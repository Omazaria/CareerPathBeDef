requiredTypes = [ "AbstractLevel" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end

export Rank

type Rank

    # Name of the Rank ex: LT, CPN
    Name::String

    # Maximum and minimum stay in this Rank
    MinStay::Int
    MaxStay::Int

    # A list of allowed Assignment
    NextLevel::Array{String}

    Rank() = new("", 0, 0, Array{String}())
    Rank(nm::String;
         min::Int = 0,
         max::Int = 0,
         next::Array{String} = Array{String}()) = new(nm, min, max, next)



end
