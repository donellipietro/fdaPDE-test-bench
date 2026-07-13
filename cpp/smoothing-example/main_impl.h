#ifndef SMOOTHING_EXAMPLE_MAIN_IMPL_H
#define SMOOTHING_EXAMPLE_MAIN_IMPL_H

#include <fdaPDE/models.h>

#include "../include/json.hpp"

#include <chrono>
#include <cmath>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <vector>

using namespace fdapde;
using nlohmann::json;

using matrix_t = Eigen::Matrix<double, Eigen::Dynamic, Eigen::Dynamic>;
using vector_t = Eigen::Matrix<double, Eigen::Dynamic, 1>;

matrix_t read_matrix(const std::string& file) {
    const std::filesystem::path path(file);
    const std::string readable_path = path.is_absolute() ?
      std::filesystem::relative(path, std::filesystem::current_path()).string() : file;
    return read_csv<double>(readable_path, true, false).as_matrix();
}

int smoothing_example_main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <params.json>\n";
        return 1;
    }

    std::ifstream input(argv[1]);
    if (!input) { throw std::runtime_error("cannot open parameter file"); }
    const json params = json::parse(input);

    const int n_nodes = params.at("n_nodes").get<int>();
    const int gcv_probes = params.at("gcv_probes").get<int>();
    const int gcv_seed = params.at("gcv_seed").get<int>();
    const std::vector<double> lambda_grid = params.at("lambda_grid").get<std::vector<double>>();
    const std::string locations_file = params.at("locations_file").get<std::string>();
    const std::string response_file = params.at("response_file").get<std::string>();
    const std::string evaluation_file = params.at("evaluation_file").get<std::string>();
    const std::string prediction_file = params.at("prediction_file").get<std::string>();
    const std::string metrics_file = params.at("metrics_file").get<std::string>();

    const matrix_t locations = read_matrix(locations_file);
    const matrix_t response = read_matrix(response_file);
    const matrix_t evaluation = read_matrix(evaluation_file);

    const auto wall_start = std::chrono::steady_clock::now();
    const std::clock_t cpu_start = std::clock();

    // assemble the selected discretization and SRPDE model
    Triangulation<1, 1> domain = Triangulation<1, 1>::UnitInterval(n_nodes);
    GeoFrame data(domain);
    auto& layer = data.insert_scalar_layer<POINT>("observations", locations);
    layer.load_blk("y", response);

#ifdef SMOOTHING_EXAMPLE_SPLINE
    constexpr const char* discretization = "spline";
    constexpr int system_blocks = 1;
    BsSpace space(domain, 3);
    TrialFunction f(space);
    TestFunction v(space);
    const auto penalty = integral(domain)(dxx(f) * dxx(v));
    ZeroField<1> forcing;
    const auto load = integral(domain)(forcing * v);
    SRPDE model("y ~ f", data, bs_ls_elliptic(penalty, load));
#else
    constexpr const char* discretization = "fem";
    constexpr int system_blocks = 2;
    FeSpace space(domain, P1<1>);
    TrialFunction f(space);
    TestFunction v(space);
    const auto penalty = integral(domain)(dot(grad(f), grad(v)));
    ZeroField<1> forcing;
    const auto load = integral(domain)(forcing * v);
    SRPDE model("y ~ f", data, fe_ls_elliptic(penalty, load));
#endif
    const auto setup_end = std::chrono::steady_clock::now();

    // select lambda by GCV, fit once at the optimum, then evaluate
    GridSearch<1> optimizer;
    optimizer.optimize(model.gcv(gcv_probes, gcv_seed), lambda_grid);
    const auto gcv_end = std::chrono::steady_clock::now();
    const double lambda = optimizer.optimum()[0];
    model.fit(lambda);
    const auto fit_end = std::chrono::steady_clock::now();
    const vector_t prediction = internals::point_basis_eval(space, evaluation) * model.f();
    const auto prediction_end = std::chrono::steady_clock::now();

    const double cpu_seconds = static_cast<double>(std::clock() - cpu_start) / CLOCKS_PER_SEC;
    const double wall_seconds =
      std::chrono::duration<double>(prediction_end - wall_start).count();
    const double cpu_usage_percent = wall_seconds > 0.0 ? 100.0 * cpu_seconds / wall_seconds : 0.0;
    const double setup_seconds = std::chrono::duration<double>(setup_end - wall_start).count();
    const double gcv_seconds = std::chrono::duration<double>(gcv_end - setup_end).count();
    const double final_fit_seconds = std::chrono::duration<double>(fit_end - gcv_end).count();
    const double prediction_seconds = std::chrono::duration<double>(prediction_end - fit_end).count();

    std::filesystem::create_directories(std::filesystem::path(prediction_file).parent_path());
    write_csv(prediction_file, prediction);
    std::ofstream metrics_output(metrics_file);
    metrics_output << json {
      {"discretization", discretization},
      {"n_basis", space.n_dofs()},
      {"linear_system_dimension", system_blocks * space.n_dofs()},
      {"wall_seconds", wall_seconds},
      {"cpu_seconds", cpu_seconds},
      {"cpu_usage_percent", cpu_usage_percent},
      {"setup_seconds", setup_seconds},
      {"gcv_seconds", gcv_seconds},
      {"final_fit_seconds", final_fit_seconds},
      {"prediction_seconds", prediction_seconds},
      {"lambda", lambda},
      {"gcv", optimizer.value()}
    }.dump(2) << '\n';

    return 0;
}

#endif
