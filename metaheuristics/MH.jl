module MH

include("Experiment.jl")

const Execute = Experiment.Execute
const StoppingCriteria = Execute.StoppingCriteria
const PM = Experiment.PM
const PMeta = PM.PMeta
const DescFunc = PM.DescFunc
const Watershed = PM.Watershed
const Problem = Watershed.Problem
const Prob = Problem.Prob
const Solution = Watershed.Solution
const Sol = Watershed.Sol

end
