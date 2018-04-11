include("functions/GenerateCareerPaths.jl")
using Compose, GraphPlot


FirstLevel = Vector{AbstractLevel}()
g = DiGraph(4)

# 1 => world
add_edge!(g, 1, 2)
#add_edge!(g, 1, 4)

# 2 => 1B-BDL
add_edge!(g, 2, 3)
add_edge!(g, 2, 4)
#add_edge!(g, 2, 5)
#add_edge!(g, 2, 6)
push!(FirstLevel, AcademicLevel("1B-BDL", next = ["SLT", "1LT", "CPN"], min = 6, max = 6))

# 3 => 1B-B
add_edge!(g, 3, 4)
#add_edge!(g, 3, 5)
#add_edge!(g, 3, 6)
push!(FirstLevel, AcademicLevel("1B-B", next = ["1LT", "CPN", "CDT"], max = 14))

# 4 => 1A-BDL
#add_edge!(g, 4, 5)
#add_edge!(g, 4, 6)
#push!(FirstLevel, AcademicLevel("1A-BDL", next = ["SLT", "1LT"]))

# 5 => 1A-B
#add_edge!(g, 5, 6)
#push!(FirstLevel, AcademicLevel("1A-B", next = ["CPN", "CDT"]))

# 6 => Leaving org


levelnames = [FirstLevel[i].Name for i in 1:length(FirstLevel)]
draw(PNG("InitGraph.png", 25cm, 25cm), gplot(g, nodelabel=["In_world"; levelnames ;"Out_world"]))
draw(SVG("InitGraph.svg", 25cm, 25cm), gplot(g, nodelabel=["In_world"; levelnames ;"Out_world"]))

SecondLevel = Vector{AbstractLevel}()
push!(SecondLevel, Rank("SLT", 13, min = 2, max = 2))
push!(SecondLevel, Rank("1LT", 14, min = 3, max = 3))
push!(SecondLevel, Rank("CPN", 15, min = 4, max = 6))
push!(SecondLevel, Rank("CDT", 16, min = 9))

Levels = Array{Vector{AbstractLevel}}(2)
Levels[1] = FirstLevel
Levels[2] = SecondLevel

Paths = ConstructCareerPaths(g, Levels)

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
        NodeLabels[i] = status.AcademicLevel.Name * " " * status.Rank.Name
        add_edge!(PlotG, i - 1, i)
        i += 1
    end
    add_edge!(PlotG, i - 1, i)
    NodeLabels[i] = "World"
    i += 1
end
draw(SVG("CareerPath.svg", 150cm, 150cm), gplot(PlotG, nodelabel=NodeLabels))
draw(PNG("CareerPath.png", 150cm, 150cm), gplot(PlotG, nodelabel=NodeLabels))
