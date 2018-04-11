requiredTypes = [ "CareerStatus" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end

export CareerPath

type CareerPath

    # Status table
    Path::Vector{CareerStatus}

    # the activated levels with : academic level being 0
    # academic level    0       Affiliation         3
    # Rank              1       Job                 4
    # Assignment        2       SubJob              5
    ActivatedLevels::Vector{Int}

    CareerPath() = new(Vector{CareerStatus}(), Vector{Int}())
    function CareerPath(careerpath::CareerPath)
        cp = new()
        cp.Path = copy(careerpath.Path)
        cp.ActivatedLevels = copy(careerpath.ActivatedLevels)
        return cp
    end
end

LevelsCodes = Dict{DataType, Int}(AcademicLevel => 0,
                                  Rank => 1,
                                  Assignment => 2,
                                  Affiliation => 3,
                                  Job => 4,
                                  SubJob => 5)

function ActivateLevel(careerpath::CareerPath, level::DataType)
    push!(careerpath.ActivatedLevels, LevelsCodes[level])
end

function isActivatedLevel(careerpath::CareerPath, level::DataType)
    return LevelsCodes[level] in careerpath.ActivatedLevels
end
