requiredTypes = [ "AcademicLevel", "Affiliation", "Assignment", "CareerStatus", "Job", "Rank", "SubJob", "CareerPath" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "functions", reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end



XlsxFile = joinpath( dirname( Base.source_path() ), "..", "NewInputFormat.xlsx" )#____________________________________________ Excel File

CleanMem = false

include( "types/DataStructures.jl" )

include( "OptCareerPaths/ReadDataXlsxNewFormat.jl" )
include( "OptCareerPaths/DataPreparation.jl" )

include("OptCareerPaths/PLresolutionNewVersion.jl")

#CleanMem = false
#include( "OptCareerPaths/ReadDataXlsxNewFormat.jl" )
#include( "OptCareerPaths/DataPreparation.jl" )

include("OptCareerPaths/WrittingResults.jl")

if PlottingResults
    include("OptCareerPaths/PlottingResults.jl")
end

if AgeDistPlot
    include("OptCareerPaths/ComputeAgeDist.jl")
end


# for obj in 1:length(MPObjectives)
#     println("obj : ", obj)
#     for i in 1:length(SetsPartCPinGoals)
#         for j in 1:length(SetsPartCPinGoals[i])
#             for k in 1:length(SetsPartCPinGoals[i][j])
#                 if obj == SetsPartCPinGoals[i][j][k]
#                     print("(", i,", ", j, ") ")
#                 end
#             end
#         end
#     end
#     println("")
# end
