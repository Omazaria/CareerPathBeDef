requiredTypes = [ "AcademicLevel", "Affiliation", "Assignment", "CareerStatus", "Job", "Rank", "SubJob", "CareerPath" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "functions", reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end
CleanMem = false
YearsOfAllowedRecruitmentDev = 0

if !isdefined(:Taro)
    using Taro, JavaCall
    Taro.init()
end

XlsxFile = joinpath( dirname( Base.source_path() ), "..", "Input_InitWithCPAdjust.xlsx" )#____________________________________________ Excel File
    include( "types/DataStructures.jl" )
    include( "OptCareerPaths/ReadDataXlsxNewFormat.jl" )
    include( "OptCareerPaths/DataPreparation.jl" )
    include("OptCareerPaths/PLresolutionNewVersion.jl")
    SimulationName = "InitWithDeviation"
    include("OptCareerPaths/WrittingResults.jl")
    if PlottingResults
        include("OptCareerPaths/PlottingResults.jl")
    end

    if AgeDistPlot
        include("OptCareerPaths/ComputeAgeDist.jl")
    end
#workspace()
quit()
#_______________________________________________________________________________________________________________________________________
# requiredTypes = [ "AcademicLevel", "Affiliation", "Assignment", "CareerStatus", "Job", "Rank", "SubJob", "CareerPath" ]
#
# for reqType in requiredTypes
#     if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
#         include( joinpath( dirname( Base.source_path() ), "functions", reqType * ".jl" ) )
#     end  # if !isdefined( Symbol( ...
# end
CleanMem = false
YearsOfAllowedRecruitmentDev = 0
XlsxFile = joinpath( dirname( Base.source_path() ), "..", "Input_NoInitHomeTest1.xlsx" )#____________________________________________ Excel File
    #include( "types/DataStructures.jl" )
    include( "OptCareerPaths/ReadDataXlsxNewFormat.jl" )
    include( "OptCareerPaths/DataPreparation.jl" )
    include("OptCareerPaths/PLresolutionNewVersion.jl")
    include("OptCareerPaths/WrittingResults.jl")
    if PlottingResults
        include("OptCareerPaths/PlottingResults.jl")
    end

    if AgeDistPlot
        include("OptCareerPaths/ComputeAgeDist.jl")
    end
#workspace()

#_______________________________________________________________________________________________________________________________________
requiredTypes = [ "AcademicLevel", "Affiliation", "Assignment", "CareerStatus", "Job", "Rank", "SubJob", "CareerPath" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "functions", reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end
CleanMem = false
YearsOfAllowedRecruitmentDev = 0
XlsxFile = joinpath( dirname( Base.source_path() ), "..", "Input_NoInitHomeTest2.xlsx" )#____________________________________________ Excel File
    #include( "types/DataStructures.jl" )
    include( "OptCareerPaths/ReadDataXlsxNewFormat.jl" )
    #SimulationName = "Results_WithInit_WithDev"
    include( "OptCareerPaths/DataPreparation.jl" )
    include("OptCareerPaths/PLresolutionNewVersion.jl")
    include("OptCareerPaths/WrittingResults.jl")
    if PlottingResults
        include("OptCareerPaths/PlottingResults.jl")
    end

    if AgeDistPlot
        include("OptCareerPaths/ComputeAgeDist.jl")
    end
#workspace()

quit()

# if PlottingResults
#     include("OptCareerPaths/PlottingResults.jl")
# end
#
# if AgeDistPlot
#     include("OptCareerPaths/ComputeAgeDist.jl")
# end


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

#workspace()
