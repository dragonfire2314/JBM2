module Watershed

"""A deterministic, fast local search that is carried to stability every time.
This is done with a greedy search over the neighborhood of single bit
differences, then running again on the best found neighbor, until no better
neighbor is found.

This has two benefits:
This search method can yield improvements faster than a metaheuristic would take
to converge on the same solution.
By ensuring that every solution occupies the low point of its local
watershed, compressing the problem from a search for the best solution to a
search for the best watershed. The smaller search space has less local
structure, so the differences between the best performing metaheuristics and a
random sample method become more similar, by the NFL theorem.
"""

"""Our benchmarking determined that the in place bit flip to check, then bit
flip back to restore is the fastest method of evaluating neighbor performance.
This method is only slightly faster than the copy method, and we will need to
make a copy of the best found when we find one, so the copy method may be less
work overall. """

include("Solution.jl")

function find_opt(sol::Solution.Sol)
    best_found = sol
    found_better_neighbor = true
    while found_better_neighbor
        found_better_neighbor = false
        for i in 1:length(sol.bitlist)
            cop = Solution.copysol(sol)
            Solution.flip_bit!(cop, i)
            if cop.score > best_found.score
                best_found = cop
                found_better_neighbor = true
            end
        end
        sol = best_found
    end
    sol
end


# const problems = Solution.Problem.load_folder("benchmark_problems/")
# const easy_problem = problems[1]
#
# ba = convert(BitArray, rand([0, 1], length(easy_problem.objective)))
# sol = Solution.Sol(ba, easy_problem)
#
# find_opt(sol)

const Prob = Solution.Problem.Prob
const Sol = Solution.Sol
const Problem = Solution.Problem

export Solution, Problem, Prob, Sol

end
