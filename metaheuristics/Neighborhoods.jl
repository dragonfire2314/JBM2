"""Neighborhoods API

A Neighborhood object contains a Solution, and a set of operations to modify
the solution to find its neighboring solutions. Operations/Neighborhoods are:

Neighborhood Generators:
    all_bits:
        SIMD vectorized every close bit
    N_Bit_Flip(sol, n_bits, must_be_on, must_be_off, n_neighbors):
        generate neighbors by flipping n_bits of the sol bitarraly. Of those
        neighbors, must_be_on of the flipped bits will have turned from on to
        off.

    2-opt(len, n_neighbors):
        Select a continuous piece of the bitarray with length len and
        reverse it
"""

module Neighborhoods

include("Solution.jl")

# ========================= NEIGHBORHOOD SEARCHES ============================ #

"""Performs an exhaustive search of the local bit flip neighborhood, over and
over, until no improvement is found. """
function greedy_flip(sol::Solution, problem::Problem)
    sol = CompleteSolution(sol.bitlist, problem)
    improved = true
    while improved
        improved = greedy_flip_internal!(sol, problem)
    end
    Solution(sol)
end

"""Loop over every bit in a bitarry, and calculate the score if the bit were
flipped. Then, if an improved score were found, flip the bit that lead to the
greatest improvement, and return true. Else, return false. """
function greedy_flip_internal!(sol::CompleteSolution, problem::Problem)::Bool
    index_to_change = 0
    best_found_score = sol.score
    # println("best found score is $best_found_score")
    feas = best_found_score > 0
    # println("feas is $feas")
    for i in 1:length(sol.bitlist)
        # println("starting score is $(sol.score)")
        if flip_bit!(sol, problem, i, feas=feas)
            # println("resulting flip scores $(sol.score)")
            if sol.score > best_found_score
                # println("new high found")
                best_found_score = sol.score
                index_to_change = i
            else
                # println("feas short circuit")
            end

            flip_bit!(sol, problem, i) #flip the bit back
        end
        # println("ending score is $(sol.score)")
    end
    if index_to_change > 0
        # println("changing an index $index_to_change")
        flip_bit!(sol, problem, index_to_change)
        # println("score is now $(sol.score)")
        return true
    end
    return false
end

"""Exhaustive eager search.

For every solution, loop over each bit in a random order. If a bit flipping
will improve the score, immediately flip the bit and restart the search.
Once an improvement fails to be found, return the current solution. """
function eager_flip(sol::Solution, problem::Problem)
    sol = CompleteSolution(sol.bitlist, problem)
    improved = true
    while improved
        improved = eager_flip_internal!(sol, problem)
    end
    Solution(sol)
end

"""Loop over the bits of a solution in a random order. If flipping a bit will
improve the score, flip the bit andd return true. Else, continue the search. If
no improvement is found, return false. """
function eager_flip_internal!(sol::CompleteSolution, problem::Problem)::Bool
    starting_score = sol.score
    feas = starting_score > 0
    for i in randperm(length(sol.bitlist))
        if flip_bit!(sol, problem, i, feas=feas)
            if sol.score > starting_score
                return true
            else
                flip_bit!(sol, problem, i)
            end
        end
    end
    return false
end

"""Like greedy flip, but use the bit swap neighborhood instead."""
function greedy_swap(sol::Solution, problem::Problem)
    sol = CompleteSolution(sol.bitlist, problem)
    improved = true
    while improved
        improved = greedy_swap_internal!(sol, problem)
    end
    Solution(sol)
end

"""Like greedy flip internal, but use the local swap neighborhood. """
function greedy_swap_internal!(sol::CompleteSolution, problem::Problem)::Bool
    removed_index = 0
    inserted_index = 0
    best_found_score = sol.score
    n_dimensions = length(sol.bitlist)
    for i in 1:n_dimensions
        if sol.bitlist[i]
            flip_bit!(sol, problem, i) #no feas check because even if the first
            # flip takes us out of feasibility, the second flip will put us
            # back in
            inner_feas = sol.score > 0
            for j in 1:n_dimensions
                if !sol.bitlist[j]
                    if flip_bit!(sol, problem, j, feas=inner_feas)
                        if sol.score > best_found_score
                            best_found_score = sol.score
                            inserted_index = i
                            removed_index = j
                        end
                        flip_bit!(sol, problem, j)
                    end
                end
            end
            flip_bit!(sol, problem, i)
        end
    end

    if removed_index > 0 # will only be changed if an improvement is found
        flip_bit!(sol, problem, removed_index)
        flip_bit!(sol, problem, inserted_index)
        return true
    end
    return false
end


function eager_swap(sol::Solution, problem::Problem)
    sol = CompleteSolution(sol.bitlist, problem)
    improved = true
    while improved
        improved = greedy_swap_internal!(sol, problem)
    end
    Solution(sol)
end

function eager_swap_internal!(sol::CompleteSolution, problem::Problem)
    best_found_score = sol.score
    n_dimensions = length(sol.bitlist)
    for i in randperm(n_dimensions)
        if sol.bitlist[i]
            flip_bit!(sol, problem, i) #no feas check because even if the first
            # flip takes us out of feasibility, the second flip will put us
            # back in
            inner_feas = sol.score > 0
            for j in randperm(n_dimensions)
                if !sol.bitlist[j]
                    if flip_bit!(sol, problem, j, feas=inner_feas)
                        if sol.score > best_found_score
                            return true
                        end
                        flip_bit!(sol, problem, j)
                    end
                end
            end
            flip_bit!(sol, problem, i)
        end
    end

    return false
end

"""Exhausted flip then exhausted swap"""
function exhflip_then_exhswap(sol::Solution, problem::Problem)
    sol = CompleteSolution(sol.bitlist, problem)
    improved = true
    while improved
        improved = greedy_flip_internal!(sol, problem)
    end
    improved = true
    while improved
        improved = greedy_swap_internal!(sol, problem)
    end
    Solution(sol)
end

"""flip then swap until exhaustion"""
function exh_flip_and_swap(sol::Solution, problem::Problem)
    sol = CompleteSolution(sol.bitlist, problem)
    improved = true
    improved2 = false
    while improved
        improved = greedy_flip_internal!(sol, problem)
        improved2 = greedy_swap_internal!(sol, problem)
        improved = improved || improved2 # I don't know how to shorten this
        # without short circuiting
    end
    Solution(sol)
end

"""flip until exhaustion, then swap and restart"""
function exh_flip_or_swap(sol::Solution, problem::Problem)
    sol = CompleteSolution(sol.bitlist, problem)
    while greedy_flip_internal!(sol, problem) || greedy_swap_internal!(sol, problem)
    end
    Solution(sol)
end

"""flip until exhaustion, then swap and restart"""
function exh_greedyflip_or_eagerswap(sol::CompleteSolution, problem::Problem)
    while greedy_flip_internal!(sol, problem) || eager_swap_internal!(sol, problem)
    end
    Solution(sol)
end

"""Slow Local Swap"""
function SLS(bl::BitArray, problem::Problem)
    #make a dummy Solution with a score of 0, because the bitarray will be taken
    # out to make a CompleteSolution with correct score
    exh_flip_and_swap(Solution(bl, 0), problem)
end

"""Medium Local Swap"""
function MLS(bl::BitArray, problem::Problem)
    #make a dummy Solution with a score of 0, because the bitarray will be taken
    # out to make a CompleteSolution with correct score
    exh_greedyflip_or_eagerswap(CompleteSolution(bl, problem), problem)
end

"""Fast LocaL Swap"""
function FLS(bl::BitArray, problem::Problem)
    #make a dummy Solution with a score of 0, because the bitarray will be taken
    # out to make a CompleteSolution with correct score
    greedy_flip(Solution(bl, 0), problem)
end

"""Repair Operator"""
function repair(bl::BitArray, problem::Problem)
	sol = CompleteSolution(bl, problem)
    improved = true
    while improved && sol.score < 0
        improved = greedy_flip_internal!(sol, problem)
    end
    Solution(sol)
end


"""No Local Search"""
function NLS(bl::BitArray, problem::Problem)
    make_solution(bl, problem)
end

"""Control"""
function control(sol::Solution, problem::Problem)
    sol
end
