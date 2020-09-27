include("Solution.jl")

const problems = Solution.Problem.load_folder("benchmark_problems/")

const hard_problems = Solution.Problem.slice_select(problems, datasets=[7], cases=[3, 6])

const easy_problem = problems[1]

function test_bit_flips()
    first_ba = convert(BitArray, rand([0, 1], 100))
    second_ba = copy(first_ba)
    second_ba[3] = !(second_ba[3] == 1)

    first_sol = Solution.Sol(first_ba, easy_problem)
    Solution.flip_bit!(first_sol, 3)
    second_sol = Solution.Sol(second_ba, easy_problem)
    first_sol
end

"""Benchmark replace vs return:
In a search of the neighborhood of one bit different solutions, we have to take
the center solution, change it to one of the neighbors, and then change it back
many times. Is it faster to do this by:
initializing a new solution every time
creating a copy, moving the original, and then replacing the original w/ copy
move the original then move it back
"""
function benchmark_rep_vs_ret(problem)

    function new_every_time(BAs, problem)
        tot = 0
        for BA in BAs
            original = Solution.Sol(BA, problem)
            oba = copy(BA)
            oba[3] = !(oba[3] == 1)
            other = Solution.Sol(oba, problem)
            tot += original.score
            tot += other.score
        end
        tot
    end

    function copy_move_replace(BAs, problem)
        tot = 0
        for BA in BAs
            original = Solution.Sol(BA, problem)
            cop = Solution.copysol(original)
            Solution.flip_bit!(original, 3)
            tot += original.score
            original = cop
            tot += cop.score
        end
        tot
    end

    function move_move(BAs, problem)
        tot = 0
        for BA in BAs
            original = Solution.Sol(BA, problem)
            Solution.flip_bit!(original, 3)
            tot += original.score
            Solution.flip_bit!(original, 3)
            tot += original.score
        end
        tot
    end

    function cond_move(BAs, problem)
        tot = 0
        for BA in BAs
            original = Solution.Sol(BA, problem)
            tot += original.score
            if Solution.cond_flip_bit!(original, 3)
                tot += original.score
                Solution.flip_bit!(original, 3)
            end
        end
        tot
    end

    small_BAs = convert.(BitArray,
        [rand([0, 1], length(problem.objective)) for _ in [4]])
    lots_BAs = convert.(BitArray,
        [rand([0, 1], length(problem.objective)) for _ in 1:1000000])

    new_every_time(small_BAs, problem)
    copy_move_replace(small_BAs, problem)
    move_move(small_BAs, problem)

    println("starting...")
    #now that everything is compiled
    for method in [new_every_time, copy_move_replace, move_move, cond_move]
        start_time = time()
        res = method(deepcopy(lots_BAs), problem)
        end_time = time()
        elapsed = end_time - start_time
        println("$(Symbol(method)) ran in $elapsed and gave $res")
    end
    println("done")
end

benchmark_rep_vs_ret(easy_problem)

test_bit_flips()
