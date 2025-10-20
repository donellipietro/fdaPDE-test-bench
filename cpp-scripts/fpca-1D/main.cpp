//
// Created by Marco Galliani on 21/05/25.
//
#include <fdaPDE/models.h>
using namespace fdapde;

#include "nlohmann/json.hpp"
using nlohmann::json;

#include <variant>

using fpca_solver_variant = std::variant<
    fpca_power_solver,
    fpca_subspace_solver,
    fpca_direct_solver
>;

fpca_solver_variant get_fpca_solver(const std::string& solver_name) {
    if (solver_name == "subspace") return fpca_subspace_solver();
    else if (solver_name == "sequential") return fpca_power_solver();
    else if (solver_name == "direct") return fpca_direct_solver();
    else throw std::invalid_argument("Unknown solver: " + solver_name);
}

int main() {
    using vector_t = Eigen::Matrix<double, Dynamic, 1>;
    using matrix_t = Eigen::Matrix<double, Dynamic, Dynamic>;
    using binary_t = BinaryMatrix<Dynamic, Dynamic>;

    std::ifstream input("params.json");
    json json_file = json::parse(input);

    // geometry
    std::string mesh_path = json_file["Path"].value("mesh","/Users/marcogalliani/Projects/fpca-simulations/simulations/data/mesh");
    mesh_path = std::filesystem::relative(mesh_path, std::filesystem::current_path());

    Triangulation<1, 1> T(mesh_path + "/knots.csv",
    /* header = */ true, /* index_col = */ true);

    // physics (isotropic laplacian)
    BsSpace Bh(T, 3);
    TrialFunction f_t(Bh);
    TestFunction  v_t(Bh);
    auto a_t = integral(T)(dxx(f_t) * dxx(v_t));  // curvature penalty
    ZeroField<1> u_t;
    auto F_t = integral(T)(u_t * v_t);

    // data
    std::string data_path = json_file["Path"].value("data","/Users/marcogalliani/Projects/fpca-simulations/simulations/data/mesh");
    data_path = std::filesystem::relative(data_path, std::filesystem::current_path());
    // load the data matrix (assume that X is an (n_units,n_locs) data matrix)
    matrix_t X = read_csv<double>(data_path + "/y.csv").as_matrix();
    int n_units = X.rows(), n_locs = X.cols();
    matrix_t locs = read_csv<double>(data_path + "/locs.csv").as_matrix(); // (n_locs,1)-matrix

    GeoFrame data(T);
    auto& l_locs = data.insert_scalar_layer<POINT>("locs_layer", locs);
    l_locs.load_blk("X", X.transpose());

    //fit the model
    fPCA fpca("X", data, sp_smoothing(a_t, F_t));

    std::vector<double> lambda_grid = json_file.at("RunParams").at("lambda_grid").get<std::vector<double>>();
    //select the fpca solver according to the params.json
    int rank = json_file["RunParams"].value("n_pc",6);
    std::visit(
        [&](auto&& solver){
            fpca.fit(
                /* n_comp = */ rank,
                lambda_grid,
                /* options = */ ComputeRandSVD | OptimizeGCV,
                solver
            );
        },
        get_fpca_solver(json_file["RunParams"].value("fpca_solver","subspace"))
    );
    // save results
    std::string results_path = "test-results/";
    //(1) functional mean ()
    //write_csv(results_path + "center.csv", fpca.center()); //at nodes
    //write_csv(results_path + "center_locs.csv", fpca.center_locs()); //at locs
    //(2) functional PCs
    write_csv(results_path + "loadings.csv", fpca.F()); //at nodes
    write_csv(results_path + "loadings_locs.csv", fpca.Fn()); //at locs
    vector_t loadings_norms = Eigen::Map<const vector_t>(fpca.loadings_norm().data(), rank);
    write_csv(results_path + "loadings_norms.csv", loadings_norms); //norms
    //(3) scores
    write_csv(results_path + "scores.csv", fpca.S());
    //(4) reconstructed functional data
    matrix_t rec_X = fpca.S()*fpca.F().transpose();
    write_csv(results_path + "reconstruction.csv", rec_X); //at nodes
    matrix_t rec_X_locs = fpca.S()*fpca.Fn().transpose();
    write_csv(results_path + "reconstruction_at_locs.csv", rec_X_locs); //at locs
    //(6) lambda
    write_csv(results_path + "lambda.csv", fpca.lambda());

    return 0;
}