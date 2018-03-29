include("functions/GenerateCareerPaths.jl")
using Compose, GraphPlot

FirstLevel = Vector{AbstractLevel}()
g = DiGraph(6)

# 1 => world
add_edge!(g, 1, 2)
add_edge!(g, 1, 4)

# 2 => 1B-BDL
add_edge!(g, 2, 3)
add_edge!(g, 2, 4)
add_edge!(g, 2, 5)
add_edge!(g, 2, 6)
push!(FirstLevel, AcademicLevel("1B-BDL"))

# 3 => 1B-B
add_edge!(g, 3, 5)
add_edge!(g, 3, 6)
push!(FirstLevel, AcademicLevel("1B-B"))

# 4 => 1A-BDL
add_edge!(g, 4, 5)
add_edge!(g, 4, 6)
push!(FirstLevel, AcademicLevel("1A-BDL"))

# 5 => 1A-B
add_edge!(g, 5, 6)
push!(FirstLevel, AcademicLevel("1A-B"))

# 6 => Leaving org

Paths = ConstructCareerPaths(g, [FirstLevel])

nbVertices = 0
for i in 1:length(Paths)
    nbVertices += length(Paths[i].Path)
end
PlotG = DiGraph(length(Paths) + nbVertices + length(Paths))

NodeLabels = Array{String}(length(Paths) + nbVertices + length(Paths))
i = 1
for path in Paths
    NodeLabels[i] = "World"
    i += 1
    for status in path.Path
        NodeLabels[i] = status.AcademicLevel.Name
        add_edge!(PlotG, i - 1, i)
        i += 1
    end
    add_edge!(PlotG, i - 1, i)
    NodeLabels[i] = "World"
    i += 1
end
draw(PNG("CareerPaths.png", 50cm, 50cm), gplot(PlotG, nodelabel=NodeLabels))
