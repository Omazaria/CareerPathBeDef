requiredTypes = [ "" ]

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
    lvl.MinStay = name
end

function setMaxStay(lvl::AbstractLevel, max::Int)
    lvl.MaxStay = name
end
