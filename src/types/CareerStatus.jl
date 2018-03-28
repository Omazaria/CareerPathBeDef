requiredTypes = [ "AbstractLevel" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end

export CareerStatus

type CareerStatus

    academicLevel::AbstractLevel
    rank::AbstractLevel
    assignment::AbstractLevel
    affiliation::AbstractLevel
    job::AbstractLevel
    subJob::AbstractLevel

    CareerStatus() = new(AbstractLevel(),
                         AbstractLevel(),
                         AbstractLevel(),
                         AbstractLevel(),
                         AbstractLevel(),
                         AbstractLevel())

end
