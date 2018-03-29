requiredTypes = [ "AbstractLevel" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include(  reqType * ".jl" ) 
    end  # if !isdefined( Symbol( ...
end

export SubJob

type SubJob <: AbstractLevel

    # Name of the SubJob ex: X, A, B
    Name::String

    # Maximum and minimum stay in this SubJob
    MinStay::Int
    MaxStay::Int

    # A list of allowed PS. Just to maintain the same structure (no next level needed)
    NextLevel::Array{String}

    SubJob() = new("", 0, 0, Array{String}())
    SubJob(nm::String;
           min::Int = 0,
           max::Int = 0,
           next::Array{String} = Array{String}()) = new(nm, min, max, next)



end
