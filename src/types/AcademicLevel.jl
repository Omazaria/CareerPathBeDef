requiredTypes = [ "AbstractLevel" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include(  reqType * ".jl"  )
    end  # if !isdefined( Symbol( ...
end

export AcademicLevel

type AcademicLevel <: AbstractLevel

    # Name of the AcademicLevel ex: 1A-B => _1A_B
    Name::String

    # Maximum and minimum stay in this AcademicLevel
    MinStay::Int
    MaxStay::Int

    # A list of allowed Ranks
    NextLevel::Array{String}

    AcademicLevel() = new("", 0, 0, Array{String}())
    AcademicLevel(nm::String;
                  min::Int = 0,
                  max::Int = 0,
                  next::Array{String} = Array{String}()) = new(nm, min, max, next)

end
