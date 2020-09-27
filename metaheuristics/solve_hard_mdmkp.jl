include("Experiment.jl")
using JSON

problems = Experiment.PM.Problem.load_folder("benchmark_problems/")
easy_problem = problems[1]
hard_problems = Experiment.PM.Problem.slice_select(
        problems, datasets=[7], cases=[3, 6])

metaheuristics = [
    Experiment.PM.create_PMetaDefs(1)["CAC"],
    Experiment.PM.create_PMetaDefs(2)["CAC"],
    Experiment.PM.create_PMetaDefs(3)["CAC"],
    Experiment.PM.create_PMetaDefs(10)["ToTwo"]
]

time_limit = 3 
popsize = 50
execs = [
    Experiment.PM.DescFunc(
        """$time_limit second time limit""",
        """{"stopping criteria":
            {"time_limit": $time_limit},
        "optimizer": $(meta.serial),
        "environment": {"popsize": $popsize}""",
        Experiment.Execute.make_exec(meta, Experiment.get_best_sol_score,
            Experiment.Execute.StoppingCriteria(time_limit=time_limit))
    ) for meta in metaheuristics]

res = Experiment.solve_problems(hard_problems, execs)

function serialize(pop::Vector{Experiment.PM.Sol})
    JSON.json([
        [sol.score, *([bit ? "1" : "0" for bit in sol.bitlist]...)] for sol in pop])
end

function serialize(t::Experiment.Trial)
    """{"optimizer": $(t.serial),
        "imp_gens": $(JSON.json(t.improvement_gens)),
        "pop": $(serialize(t.final_population)),
        "problem": $(JSON.json(t.problem)),
        "score": $(t.improvement_gens[end][3])
    }"""
end

function serialize(results::Vector{Experiment.Trial})
    "[" * join([serialize(trial) for trial in results], ",") * "]"
end

JSON.parse(serialize(res))

file = open("results/quick_res.json", "w")
write(file, serialize(res))
