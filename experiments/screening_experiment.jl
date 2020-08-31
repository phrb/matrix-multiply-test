using ExperimentalDesign, StatsModels, GLM, DataFrames, Distributions, Random, CSV

function y(x)
    env_flags = ""

    for i in 1:length(x)
        if x[i] > 0
            env_flags = "-C passes=" * replace(names(x)[i], "_" => "-") * " " * env_flags
        end
    end

    env_flags = "-C lto=off -C no-prepopulate-passes -C passes=name-anon-globals " * env_flags

    cmd = `cargo build --manifest-path ../heap_vec_nolib/Cargo.toml`

    println(env_flags)
    println(cmd)

    ENV["RUSTFLAGS"] = env_flags

    run(cmd)

    exec_time = @elapsed run(`../heap_vec_nolib/target/debug/matrix-multiply-raw`)

    return exec_time
end

model = @formula(0 ~ constprop + instcombine + argpromotion + jump_threading +
                 lcssa + licm + loop_deletion + loop_extract + loop_reduce +
                 loop_rotate + loop_simplify + loop_unroll + loop_unroll_and_jam +
                 loop_unswitch + mem2reg + memcpyopt)

design = PlackettBurman(model)

repetitions = 15

# Screening
Random.seed!(192938)
design.matrix[!, :response] = y.(eachrow(design.matrix[:, collect(design.factors)]))
screening_results = copy(design.matrix)

for i = 1:repetitions
    design.matrix[!, :response] = y.(eachrow(design.matrix[:, collect(design.factors)]))
    append!(screening_results, copy(design.matrix))
end

CSV.write("screening_experiment.csv", screening_results)

# Random design
Random.seed!(8418172)

design_distribution = DesignDistribution(NamedTuple{getfield.(model.rhs, :sym)}(
    repeat([DiscreteNonParametric([-1, 1],
                                  [0.5, 0.5])], 16)))

random_design = rand(design_distribution, 10)

random_design.matrix[!, :response] = y.(eachrow(random_design.matrix[:,
                                                                     collect(keys(random_design.factors))]))
random_results = copy(random_design.matrix)

for i = 1:repetitions
    random_design.matrix[!, :response] = y.(eachrow(random_design.matrix[:,
                                                                         collect(keys(random_design.factors))]))
    append!(random_results, copy(random_design.matrix))
end

CSV.write("random_experiment.csv", random_results)

# Random Design for Interactions
Random.seed!(8418172)

design_distribution = DesignDistribution(NamedTuple{getfield.(model.rhs, :sym)}(
    repeat([DiscreteNonParametric([-1, 1],
                                  [0.5, 0.5])], 16)))

random_design = rand(design_distribution, 140)

random_design.matrix[!, :response] = y.(eachrow(random_design.matrix[:,
                                                                     collect(keys(random_design.factors))]))
random_results = copy(random_design.matrix)

for i = 1:repetitions
    random_design.matrix[!, :response] = y.(eachrow(random_design.matrix[:,
                                                                         collect(keys(random_design.factors))]))
    append!(random_results, copy(random_design.matrix))
end

CSV.write("random_experiment_140.csv", random_results)
