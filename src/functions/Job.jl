requiredTypes = [ "Job" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "..", "types", reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end
