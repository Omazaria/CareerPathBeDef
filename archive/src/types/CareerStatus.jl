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

function get_AcademicLevel(cs::CareerStatus)
    return cs.AcademicLevel
end
function set_AcademicLevel(cs::CareerStatus, Val::AbstractLevel)
    cs.AcademicLevel = Val
end

function get_Rank(cs::CareerStatus)
    return cs.Rank
end
function set_Rank(cs::CareerStatus, Val::AbstractLevel)
    cs.Rank = Val
end

function get_Assignment(cs::CareerStatus)
    return cs.Assignment
end
function set_Assignment(cs::CareerStatus, Val::AbstractLevel)
    cs.Assignment = Val
end

function get_Affiliation(cs::CareerStatus)
    return cs.Affiliation
end
function set_Affiliation(cs::CareerStatus, Val::AbstractLevel)
    cs.Affiliation = Val
end

function get_Job(cs::CareerStatus)
    return cs.Job
end
function set_Job(cs::CareerStatus, Val::AbstractLevel)
    cs.Job = Val
end

function get_SubJob(cs::CareerStatus)
    return cs.SubJob
end
function set_SubJob(cs::CareerStatus, Val::AbstractLevel)
    cs.SubJob = Val
end
