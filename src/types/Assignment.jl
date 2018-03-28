requiredTypes = [ "AbstractLevel" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end

export Assignment

type Assignment
    # Name of the Assignment ex: VR, CP
    Name::String

    # Maximum and minimum stay in this Assignment
    MinStay::Int
    MaxStay::Int

    # A list of allowed Affiliations
    NextLevel::Array{String}

    Assignment() = new("", 0, 0, Array{String}())
    Assignment(nm::String;
                min::Int = 0,
                max::Int = 0,
                next::Array{String} = Array{String}()) = new(nm, min, max, next)
end
