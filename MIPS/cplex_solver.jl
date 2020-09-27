#=
Cplex is found at
/opt/ibm/ILOG/CPLEX_Studio1210/cplex/bin
=#
using CPLEX, JuMP, JSON

include("../metaheuristics/MH.jl")

problems = MH.Problem.load_folder("./benchmark_problems/")
easy_problem = problems[1]
hard_problems = MH.Problem.slice_select(
        problems, datasets=[7], cases=[3, 6])


function create_model(problem; time_limit=20)
	model = Model(with_optimizer(CPLEX.Optimizer, CPXPARAM_ScreenOutput=0))

	#make cplex params
	# set_optimizer_attribute(model, "CPXPARAM_Threads", 1)
	set_optimizer_attribute(model, "CPXPARAM_TimeLimit", time_limit)

    #make the problem variables with a Binary constraint
    @variable(model, x[1:length(problem.objective)], Bin)

    @objective(model, Max, sum(problem.objective .* x))

    for ub in problem.upper_bounds
        @constraint(model, sum(ub[1] .* x) <= ub[2])
    end

    for lb in problem.lower_bounds
        @constraint(model, sum(lb[1] .* x) >= lb[2])
    end

    model
end

function ba_to_int(arr)
    return sum(arr .* (2 .^ collect(length(arr)-1:-1:0)))
end

grayencode(n::Integer) = n ⊻ (n >> 1)

function encode_bitarray(ba)
	join([grayencode(ba_to_int(a)) for a in collect(Iterators.partition(ba, 10))], "/")
end

struct TolStep
   solution::BitArray
   repr::String
   tolerance::Number
   objective::Number
   elapsed_time::Number
   solution_status::String
   termination_status::String
end


function run_matheuristic(problems, results_folder; meta_time=3, tol_time=10)
	#make the optimizer method
    meta = MH.PM.create_PMetaDefs(2)["CAC"]
    meta_opt = MH.Execute.make_exec(meta, MH.Experiment.get_best_sol_score,
        MH.StoppingCriteria(time_limit=meta_time))

	results = Vector{Dict{String,Any}}()
	mkpath(results_folder)
	println("----------------Running Trials------------")
	for p in problems
      problem_results = Vector{}()
		println("")
		println("")
		println("problem is c:$(p.id.case) i:$(p.id.instance)")
		#first, get the metaheuristic solutions
		pop = MH.Experiment.create_random_pop(50, p)
      start_time = time()
		meta_opt(pop)
      end_time = time()
		sort!(pop, by=x->-x.score)


		for sol in pop[1:1]
         sol_results = Vector{TolStep}()
         push!(sol_results, TolStep(
            sol.bitlist,
            encode_bitarray(sol.bitlist),
            -1,
            end_time - start_time,
            sol.score,
            "metaheuristic produced solution",
            "CPLEX not ran"))
         println("")
			println("using metaheuristic solution $(encode_bitarray(sol.bitlist)) with score $(sol.score)")
			t = 0
			best = [[0], 0]
			# m = create_model(p, 20)
         m = create_model(p, time_limit=tol_time)
			set_start_value.(all_variables(m), convert.(Float64, sol.bitlist))
			for tolerance in [.001, .005, .01, .05, .08, .12]
            t = tolerance
            println("")
				println("-----------------------------tolerance set to $tolerance")
            #check if best  solution rolled over
				set_optimizer_attribute(m, "CPXPARAM_MIP_Tolerances_MIPGap",
					tolerance)

            println("    solution status is: $(primal_status(m))")
            try
               println("    solution is: $(encode_bitarray(convert(BitArray, value.(all_variables(m)))))")
               println("    objective value is: $(objective_value(m))")
            catch e
               println("error: $e")
            end
            println("running model: ")

				#run optimizer silently
				tempout = stdout # save stream
				try
					redirect_stdout() # redirect to null
               start_time = time()
					optimize!(m)
               end_time = time()
					redirect_stdout(tempout)
				catch e
					redirect_stdout(tempout)
					return e
				end

            ba, repr, obj = 0, 0, 0
            elapsed_time = end_time - start_time
            try
               ba = convert(BitArray, value.(all_variables(m)))
               repr = encode_bitarray(ba)
               obj = objective_value(m)
            catch e
               ba = [0]
               repr = "$(e)"
               obj = 0
            end

            push!(sol_results, TolStep(
               ba,
               repr,
               tolerance,
               obj,
               elapsed_time,
               "$(primal_status(m))",
               "$(termination_status(m))"))

            println("    termination status is $(termination_status(m))")
            println("    solution status is: $(primal_status(m))")
            println("    objective value is: $obj")

				if termination_status(m) == MOI.ALMOST_OPTIMAL ||
						termination_status(m) == MOI.OPTIMAL
					best = (value.(all_variables(m)), objective_value(m))
					break
				end
				if termination_status(m) == MOI.INFEASIBLE ||
						termination_status(m) == MOI.ALMOST_INFEASIBLE
					println("CPLEX proved infeasible")
				end
			end

         push!(problem_results, sol_results)

         println("")
			println("Tolerance relaxed to $t")
			println("produced solution is $(encode_bitarray(convert(BitArray, best[1]))) and scores $(best[2])")
		end
    	push!(results, Dict("problem"=>p.id, "tolsteps"=>problem_results))
	  	f = open(joinpath(results_folder, JSON.json(p.id)) * ".json", "w")
		write(f, JSON.json(results[end]))
	end
   results
end

# solset = run_matheuristic(problems[400:402], "test_results", meta_time=3,
   # tol_time=3)
solset = run_matheuristic(hard_problems[7:end], "math_results", meta_time=120,
   tol_time=120)
