module Experiment

include("PMeta.jl")
include("Execute.jl")

function create_random_pop(n, p)::Vector{PM.Watershed.Sol}
    pop = Vector{}()
    for i in 1:n
        ba = convert(BitArray, rand([0, 1], length(p.objective)))
        sol = PM.Watershed.Sol(ba, p)
        push!(pop, sol)
    end
    pop
end

function get_best_sol_score(pop)
    max([s.score for s in pop]...)
end

struct Trial
    serial::String
    problem::PM.Problem.Problem_ID

    final_population::Vector{PM.Sol}

    improvement_gens::Vector{Tuple}
end

function solve_problems(problems, descr_optimizers;
        popsize=50)::Vector{Trial}
    """accept a list of problems, and a list of executors, and run each executor
    on the list of problems and save the results. """
    results = []
    Threads.@threads for problem in problems
        master_pop = create_random_pop(popsize, problem)
        for descr_opt in descr_optimizers
            pop = deepcopy(master_pop)
            println("Start score is $(get_best_sol_score(pop))")
            imp_gens = descr_opt.exec(pop)
            println("end score is $(get_best_sol_score(pop))")
            println("")

            push!(results, Trial(descr_opt.serial, problem.id, pop, imp_gens, ))
        end
    end
    results
end


end
