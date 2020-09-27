module ST

using JSON
results = JSON.parse(open("results/CAC_compare_on_hard.json", "r"))

function enrow()

function simple_table(results)
    kys = keys(results[1])
    rows = []
    for trial in results
        row = []
        for k in kys
            push!(row, enrow(trial[k]))
            println(trial[k])
        end
    end
end

simple_table(results)

end
