requiredTypes = [ "AcademicLevel", "Affiliation", "Assignment", "Job", "Rank", "SubJob" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end

export CareerStatus

type CareerStatus

    AcademicLevel::AbstractLevel
    Rank::AbstractLevel
    Assignment::AbstractLevel
    Affiliation::AbstractLevel
    Job::AbstractLevel
    SubJob::AbstractLevel

    CareerStatus(;academicLevel::AbstractLevel = AcademicLevel(),
                  rank::AbstractLevel = Rank(),
                  assignment::AbstractLevel = Assignment(),
                  affiliation::AbstractLevel = Affiliation(),
                  job::AbstractLevel = Job(),
                  subjob::AbstractLevel = SubJob()) = new(academicLevel, rank, assignment, affiliation, job, subjob)
end
