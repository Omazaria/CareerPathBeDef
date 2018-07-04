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

    MinStay::Int
    MaxStay::Int

    Attrition::Float16

    CareerStatus(;academicLevel::AbstractLevel = AcademicLevel(),
                  rank::AbstractLevel = Rank(),
                  assignment::AbstractLevel = Assignment(),
                  affiliation::AbstractLevel = Affiliation(),
                  job::AbstractLevel = Job(),
                  subjob::AbstractLevel = SubJob(),
                  min::Int = 0,
                  max::Int = 0,
                  attrition::Float16 = 0) = new(academicLevel, rank, assignment, affiliation, job, subjob, min, max, attrition)

    function CareerStatus(cs::CareerStatus)
        ncs = new()
        ncs.AcademicLevel = cs.AcademicLevel
        ncs.Rank = cs.Rank
        ncs.Assignment = cs.Assignment
        ncs.Affiliation = cs.Affiliation
        ncs.Job = cs.Job
        ncs.SubJob = cs.SubJob
        ncs.MinStay = cs.MinStay
        ncs.MaxStay = cs.MaxStay
        ncs.Attrition = cs.Attrition
        return ncs
    end

end
