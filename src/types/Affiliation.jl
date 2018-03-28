requiredTypes = [ "AbstractLevel" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end

export Affiliation
type Affiliation <: AbstractLevel

    # Name of the Affiliation ex: AC, AS
    Name::String

    # Maximum and minimum stay in this Affiliation
    MinStay::Int
    MaxStay::Int

    # A list of allowed Jobs
    NextLevel::Array{String}

    Affiliation() = new("", 0, 0, Array{String}())
    Affiliation(nm::String;
                min::Int = 0,
                max::Int = 0,
                next::Array{String} = Array{String}()) = new(nm, min, max, next)

end
