requiredTypes = [ ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end


# _______________________________________________________________type

export AbstractLevel
abstract type AbstractLevel end

# _______________________________________________________________functions

function setName(lvl::AbstractLevel, name::String)
    lvl.Name = name
end

function setMinStay(lvl::AbstractLevel, min::Int)
    lvl.MinStay = min
end

function setMaxStay(lvl::AbstractLevel, max::Int)
    lvl.MaxStay = max
end

function getMinStay(lvl::AbstractLevel)
    return lvl.MinStay
end

function getMaxStay(lvl::AbstractLevel)
    return lvl.MaxStay
end
