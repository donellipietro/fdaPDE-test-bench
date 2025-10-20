// Created by Marco Galliani on 21/05/25.
//
#include <fdaPDE/models.h>
using namespace fdapde;

#include "nlohmann/json.hpp"
using nlohmann::json;

int main() {
    using vector_t = Eigen::Matrix<double, Dynamic, 1>;
    using matrix_t = Eigen::Matrix<double, Dynamic, Dynamic>;
    using sparse_matrix_t = Eigen::SparseMatrix<double>;
    using binary_t = BinaryMatrix<Dynamic, Dynamic>;

    std::ifstream input("../params.json");
    json json_file = json::parse(input);

    // geometry
    std::string mesh_path = json_file["Path"].value("mesh","/Users/marcogalliani/Projects/fpca-simulations/simulations/data/mesh");
    mesh_path = std::filesystem::relative(mesh_path, std::filesystem::current_path());

    Triangulation<2, 2> D(mesh_path + "/points.csv", mesh_path + "/elements.csv", mesh_path + "/boundary.csv",
    /* header = */ true, /* index_col = */ true);

    // data
    std::string data_path = json_file["Path"].value("data","/Users/marcogalliani/Projects/fpca-simulations/simulations/data/mesh");
    data_path = std::filesystem::relative(data_path, std::filesystem::current_path());
    // load the data matrix (assume that X is an (n_units,n_locs) data matrix)
    matrix_t X = read_csv<double>(data_path + "/y.csv").as_matrix();
    binary_t nan_pattern = na_matrix(X);
    int n_units = X.rows(), n_locs = X.cols();
    vector_t col_sums_X = (~nan_pattern).select(X,0).colwise().sum();
    vector_t col_nobs_X = (~nan_pattern).select(matrix_t::Ones(n_units,n_locs),0).colwise().sum();
    vector_t col_means_X = col_sums_X.array() / col_nobs_X.array();

    //we are ready tp store everything in the dataframe
    GeoFrame data(D);
    matrix_t locs = read_csv<double>(data_path + "/locs.csv").as_matrix(); // (n_locs,2)-matrix
    auto& l = data.insert_scalar_layer<POINT>("layer", locs);
    l.load_vec("y",col_means_X);

    // physics (isotropic laplacian)
    FeSpace Vh(D, P1<1>);
    TrialFunction f(Vh);
    TestFunction  v(Vh);
    auto a = integral(D)(dot(grad(f), grad(v)));
    ZeroField<2> u;
    auto F = integral(D)(u * v);

    // modeling
    std::string results_path = "results/";
    SRPDE m("y ~ f", data, fe_ls_elliptic(a, F));

    // calibration
    std::vector<double> lambda_grid = json_file.at("RunParams").at("lambda_grid").get<std::vector<double>>();
    GridOptimizer<1> opt;
    opt.optimize(m.gcv(), lambda_grid);

    // fit at optimal smoothing level
    m.fit(opt.optimum());
    std::cout << opt.optimum()[0] << std::endl;

    // save results
    write_csv(results_path + "center.csv", m.f());
    write_csv(results_path + "center_locs.csv", m.fitted());

    return 0;
}