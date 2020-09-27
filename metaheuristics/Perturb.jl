module Perturb

function column_average_chances(
        current,
        rands::Vector,
        tops::Vector,
        bottoms::Vector,
        _mean::Vector{Float64}
			)::BitArray
    n_dimensions = length(current.bitlist)
    averages::Vector{Float64} = copy(current.bitlist)
	for pop in [rands, tops, bottoms]
    	for sol in pop
        	averages .+= sol.bitlist
    	end
	end
    averages /= length(rands) + length(tops) + length(bottoms) + 1
    return [rand() < percent for percent in averages]
end

function two_to(
        current,
        rands::Vector,
        tops::Vector,
        bottoms::Vector,
        _mean::Vector{Float64}
			)::BitArray
    n_dimensions = length(current.bitlist)
    averages::Vector{Float64} = copy(current.bitlist)
	for sol in [rand(tops), rand(tops)]
        averages .+= sol.bitlist
	end
    averages /= 2
    return [rand() < percent for percent in averages]
end

function jaya_perturb(
        first_sol_view;
        random_sols_views,
        top_sol_view,
        bottom_sol_view,
        mean_of_sols::Vector{Float64},
        n_samples::Int=1)::BitArray
    [bit + rand([0, 1])*(top_sol_view[1].bitlist[i]-bit) - rand([0, 1])*(bottom_sol_view[1].bitlist[i]-bit) > 0 for (i, bit) in enumerate(first_sol_view[1].bitlist)]
end

function TBO_perturb(
    first_sol_view;
    random_sols_views,
    top_sol_view,
    bottom_sol_view,
    mean_of_sols::Vector{Float64},
    n_samples::Int=1)::BitArray
    return [bit +
        rand([0,1]) * (top_sol_view[1].bitlist[i] - (rand([1, 2])) * (rand() < mean_of_sols[i])) > 0
        for (i, bit) in enumerate(first_sol_view[1].bitlist)]

end

function LBO_perturb(
        first_sol_view;
        random_sols_views,
        top_sol_view,
        bottom_sol_view,
        mean_of_sols::Vector{Float64},
        n_samples::Int=1)::BitArray

    second_sol_view = random_sols_views[1]
    if second_sol_view[1].score > first_sol_view[1].score #assure first_sol is the teacher
        temp = first_sol_view
        first_sol_view = second_sol_view
        second_sol = temp
    end
    return [second_sol_view[1].bitlist[j] + rand([0,1]) * (first_sol_view[1].bitlist[j] - second_sol_view[1].bitlist[j]) for j in 1:length(first_sol_view[1].bitlist)]
end

"""needs to be updated to use views"""
# function GA_perturb(
#         first_sol::Solution;
#         random_sols::Population,
#         top_sol::Solution,
#         bottom_sol::Solution,
#         mean_of_sols::Vector{Float64},
#         n_samples::Int=1,
#         mutation_percent::Float64=.02)::BitArray
#
#     n_dimensions = length(first_sol.bitlist)
#     pivot = rand(2:n_dimensions)
#     new_sol = vcat(first_sol.bitlist[1:pivot-1], random_sols[1].bitlist[pivot:end])
#
#     #now we mutate the new solution
#     n_mutations = Int(round(mutation_percent*n_dimensions))
#     for _ in 1:n_mutations
#         i = rand(1:n_dimensions)
#         new_sol[i] = !new_sol[i]
#     end
#     new_sol
# end
#
"""Genetic Algorithm No Mutation"""
function GANM_perturb(
        first_sol_view;
        random_sols_views,
        top_sol_view,
        bottom_sol_view,
        mean_of_sols::Vector{Float64})::BitArray

    n_dimensions = length(first_sol_view[1].bitlist)
    pivot = rand(2:n_dimensions)
    vcat(first_sol_view[1].bitlist[1:pivot-1], random_sols_views[1][1].bitlist[pivot:end])
end

function rao1_perturb(
        first_sol_view;
        top_sol_view,
        bottom_sol_view,
		random_sols_views,
        mean_of_sols::Vector{Float64})::BitArray
    return [bit + rand([0, 1])*(top_sol_view[1].bitlist[i]-bottom_sol_view[1].bitlist[1]) > 0 for (i, bit) in enumerate(first_sol_view[1].bitlist)]
end

function rao2_perturb(
        first_sol_view;
        random_sols_views,
        top_sol_view,
        bottom_sol_view,
        mean_of_sols::Vector{Float64})::BitArray
    sol_score = first_sol_view[1].score
    rand_sol_score = random_sols_views[1][1].score
    if sol_score > rand_sol_score
        better_solution_view = first_sol_view
        worse_solution_view = random_sols_views[1]
    else
        better_solution_view = random_sols_views[1]
        worse_solution_view = first_sol_view
    end
    return [bit + rand([0, 1])*(top_sol_view[1].bitlist[i]-bottom_sol_view[1].bitlist[i]) + rand([0, 1])*(better_solution_view[1].bitlist[i]-worse_solution_view[1].bitlist[i]) > 0 for (i, bit) in enumerate(first_sol_view[1].bitlist)]
end

end
