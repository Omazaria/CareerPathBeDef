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

    # the activated levels with academic level being 0
    ActivitedLevels::Int

    CareerPath() = new(Vector{CareerStatus}(), -1)
end
