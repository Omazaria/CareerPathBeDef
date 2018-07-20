requiredTypes = [ "AcademicLevel", "Affiliation", "Assignment", "CareerStatus", "Job", "Rank", "SubJob", "CareerPath" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "functions", reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end



XlsxFile = joinpath( dirname( Base.source_path() ), "..", "SimulationInput.xlsx" )#____________________________________________ Excel File


include( "types/DataStructures.jl" )

include( "OptCareerPaths/ReadDataXlsx.jl" )

include("OptCareerPaths/PLresolution.jl")

include("OptCareerPaths/WrittingResults.jl")

if PlottingResults
    include("OptCareerPaths/PlottingResults.jl")
end

if AgeDistPlot
    include("OptCareerPaths/ComputeAgeDist.jl")
end
