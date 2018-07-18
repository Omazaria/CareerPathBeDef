# Plotting results

using Plots
plotly();
print("Plotting results...")

ArraysToPlot = Dict{Int, Any}() # Priority , Arrays of RequirementFulfillment corresponding to the priority
ArraysLabels = Dict{Int, Any}() # Priority , Array of lablels
for i in 1:length(MPObjectives)
    try
        ArraysToPlot[MPObjectives[i].PlotNb] = [ArraysToPlot[MPObjectives[i].PlotNb] RequirementFulfillment[:,i]]
        ArraysLabels[MPObjectives[i].PlotNb] = [ArraysLabels[MPObjectives[i].PlotNb] reduce(*,MPObjectives[i].Objectives)]
    catch
        if MPObjectives[i].PlotNb > 0
            ArraysToPlot[MPObjectives[i].PlotNb] = RequirementFulfillment[:,i]
            ArraysLabels[MPObjectives[i].PlotNb] = [reduce(*,MPObjectives[i].Objectives)]
            if ArraysLabels[MPObjectives[i].PlotNb][1] == ""
                ArraysLabels[MPObjectives[i].PlotNb] = "Total Population"
            end
        end
    end
end
for p in ArraysToPlot
    gui(plot(1:NBYears, p[2], size=(800,600), label = ArraysLabels[p[1]], lw = 3, ylim = (0,1.1*maximum(p[2]))))
end

for i in 1:length(MPObjectives)
    if MPObjectives[i].PlotNb == 0
        titles = ((MPObjectives[i].Objectives[1] == "")? "Total population": reduce(*,MPObjectives[i].Objectives))
        p1 = plot(1:NBYears, RequirementFulfillment[:,i], size=(800,600), lw = 3, ylim = (0,1.1*maximum(RequirementFulfillment[:,i])), title = titles)
        plot!(p1, [1, NBYears], [(1 + MPObjectives[i].InitTolerance)*MPObjectives[i].Number, (1 + MPObjectives[i].EndTolerance)*MPObjectives[i].Number], color = :red, legend=false)
        plot!(p1, [1, NBYears], [(1 - MPObjectives[i].InitTolerance)*MPObjectives[i].Number, (1 - MPObjectives[i].EndTolerance)*MPObjectives[i].Number], color = :red, legend=false)
        gui(p1)
    end
end
println(" End.")
