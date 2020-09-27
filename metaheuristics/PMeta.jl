module PM
using StatsBase: sample
include("Watershed.jl")
include("Perturb.jl")

struct PMeta
	compress::Function
	perturb::Function

	n_top::Int
	use_top::Bool
	n_bottom::Int
	use_bottom::Bool
	n_random::Int
	use_random::Bool
	use_mean::Bool
	select_extrema_every_perturb::Bool
end

function PMeta(perturb::Function;
		compress::Function=Watershed.find_opt,
		n_top::Int=-1, n_bottom::Int=-1, n_random::Int=-1,
		UESET::Bool=false,
		use_mean::Bool=false)
	PMeta(compress, perturb, n_top, n_top > 0, n_bottom, n_bottom > 0, n_random,
	n_random > 0, use_mean, UESET)
end

"""Described Function"""
struct DescFunc
	description::String
	serial::String
	exec::Function
end

function maxk(a, k)
    a[partialsortperm(a, 1:k, rev=true, by=x->x.score)]
end

function mink(a, k)
    a[partialsortperm(a, 1:k, by=x->x.score)]
end

function select_other_solutions(pm::PMeta, pop::Vector{Watershed.Sol})
	tops = Vector{Watershed.Sol}()
	bottoms, randoms = copy(tops), copy(tops)
	if pm.use_top
		tops = maxk(pop, pm.n_top)
	end
	if pm.use_bottom
		bottoms = mink(pop, pm.n_bottom)
	end
	if pm.use_random
		randoms = rand(pop, pm.n_random)
	end
	tops, bottoms, randoms
end

function calc_pop_center(pm, pop)
	mean_of_sols = zeros(Float64, length(pop[1].bitlist))
	if pm.use_mean
		for p in pop
			mean_of_sols .+= p.bitlist
		end
		mean_of_sols ./= len(pop[1].bitlist)
	end
	mean_of_sols
end

function solution_in_pop(pop, sol)
	for othersol in pop
		if sol.bitlist == othersol.bitlist
			return true
		end
	end
	false
end

"""
accept a config object and return a function that will accept a population and
optimize it in place using the configured behavior.
"""
function create_PMeta_func(pmeta::PMeta)
	function apply_pmeta!(pop::Vector{Watershed.Sol})
		tops, bottoms, randoms = select_other_solutions(pmeta, pop)
		population_center = calc_pop_center(pmeta, pop)
		for (i, sol) in enumerate(pop)
			new_bitlist = pmeta.perturb(sol, randoms, tops, bottoms,
				population_center)
			new_sol = Watershed.Sol(new_bitlist, sol.problem)
			new_sol = Watershed.find_opt(new_sol)
			if !solution_in_pop(pop, new_sol) && new_sol.score > sol.score
				pop[i] = new_sol
			end
		end
	end
end

"""UESET = Update extreme solution every time"""
function create_PMetaDefs(n; UESET::Bool=false)
	mapping = Dict()
	mapping["CAC"] = DescFunc(
		"""Column Average Chances {n:$n} will accept the present solution, plus
		n more solutions, and calculate the average bit value for each index.
		A new solution will be generated using the average value of each index
		as the chance that the index will be turned on.""",
		"""{"perturb": "CAC", "n": $n}""",
		create_PMeta_func(PMeta(
			Perturb.column_average_chances,
			n_random = n)))
	mapping["ToTwo"] = DescFunc(
		"""To Two will accept the top $n solutions, randomly select two of them,
		then perform the CAC procedure using the two top solutions and the
		current one.""",
		"""{"perturb": "ToTwo", "n": $n}""",
		create_PMeta_func(PMeta(
			Perturb.column_average_chances,
			n_top = n)))
	# mapping["Jaya"] = PMeta(
	# 	Perturb.jaya_perturb,
	# 	n_top=n,
	# 	n_bottom=n)
	# mapping["TBO"] = PMeta(Perturb.TBO_perturb, n_top=n, use_mean=true)
	# mapping["LBO"] = PMeta(Perturb.LBO_perturb, n_random=1)
	# mapping["Rao1"] = PMeta(Perturb.rao1_perturb, n_top=n, n_bottom=n,
	# 	UESET=UESET)
	# mapping["Rao2"] = PMeta(Perturb.rao2_perturb, n_top=n, n_bottom=n,
	# 	n_random=1, UESET=UESET)
	mapping
end

const Sol = Watershed.Sol
const Prob = Watershed.Prob
const Problem = Watershed.Problem
const Solution = Watershed.Solution


end
