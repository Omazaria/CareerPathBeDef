requiredTypes = [ "AbstractLevel" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include(  reqType * ".jl" ) 
    end  # if !isdefined( Symbol( ...
end

export Job

type Job <: AbstractLevel

    # Name of the Job ex: 01 => _01
    Name::String

    # Maximum and minimum stay in this Affiliation
    MinStay::Int
    MaxStay::Int

    # A list of allowed SubJobs
    NextLevel::Array{String}

    Job() = new("", 0, 0, Array{String}())
    Job(nm::String;
        min::Int = 0,
        max::Int = 0,
        next::Array{String} = Array{String}()) = new(nm, min, max, next)




end
