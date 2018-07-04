include("functions/GenerateCareerPaths.jl")
using Compose, GraphPlot


# Deinition on constants which are the vertices of our graph
const in_world  = 1
const _3D_BDL   = 2
const _3D_B     = 3
const _2C_BDL   = 4
const _2C_B     = 5
const _2B_BDL   = 6
const _2B_B     = 7
const _1B_BDL   = 8
const _1B_B     = 9
const _1A_BDL   = 10
const _1A_B     = 11
const out_world = 12

FirstLevel = Vector{AbstractLevel}()
push!(FirstLevel, AcademicLevel("3D-BDL"))
push!(FirstLevel, AcademicLevel("3D-B"))
push!(FirstLevel, AcademicLevel("2C-BDL"))
push!(FirstLevel, AcademicLevel("2C-B"))
push!(FirstLevel, AcademicLevel("2B-BDL"))
push!(FirstLevel, AcademicLevel("2B-B"))
push!(FirstLevel, AcademicLevel("1B-BDL"))
push!(FirstLevel, AcademicLevel("1B-B"))
push!(FirstLevel, AcademicLevel("1A-BDL"))
push!(FirstLevel, AcademicLevel("1A-B"))

g = DiGraph(12)

# Recruitment edges i.e. statrting from in_world
add_edge!(g, in_world, _3D_BDL)
add_edge!(g, in_world, _2C_BDL)
add_edge!(g, in_world, _2B_BDL)
add_edge!(g, in_world, _1B_BDL)
add_edge!(g, in_world, _1A_BDL)

# Leaving the organization (retirement and attrition) i.e. connect all edges to the leaving vertex
for i in 2:11
    add_edge!(g, i, out_world)
end

# Connecting nodes with even index to all nodes with a higher index
for i in 1:5
    for j in (2*i + 1):11
        add_edge!(g, 2*i, j)
    end
end

# Connecting nodes with odd index to nodes with a higher odd index
for i in 1:5
    for j in (i+1):5
        add_edge!(g, 2*i + 1, 2*j + 1)
    end
end
levelnames = [FirstLevel[i].Name for i in 1:length(FirstLevel)]
draw(PNG("InitGraph.png", 50cm, 50cm), gplot(g, nodelabel=["In_world"; levelnames ;"Out_world"]))

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
draw(SVG("CareerPaths.svg", 50cm, 50cm), gplot(PlotG, nodelabel=NodeLabels))
draw(PNG("CareerPaths.png", 50cm, 50cm), gplot(PlotG, nodelabel=NodeLabels))
