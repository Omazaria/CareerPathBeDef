requiredTypes = [ "CareerStatus" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "..", "types", reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
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

function set_MinStay(st::CareerStatus, min::Int)
    st.MinStay = min
end

function set_MaxStay(st::CareerStatus, max::Int)
    st.MaxStay = max
end

function get_MinStay(st::CareerStatus)
    st.MinStay
end

function get_MaxStay(st::CareerStatus)
    st.MaxStay
end

function get_Name_Level(cs::CareerStatus, typ::DataType)
    if typ == AcademicLevel
        return cs.AcademicLevel.Name
    elseif typ == Rank
        return cs.Rank.Name
    elseif typ == Assignment
        return cs.Assignment.Name
    elseif typ == Affiliation
        return cs.Affiliation.Name
    elseif typ == Job
        return cs.Job.Name
    elseif typ == SubJob
        return cs.SubJob.Name
    end
end

function get_Level(cs::CareerStatus, typ::DataType)
    if typ == AcademicLevel
        return cs.AcademicLevel
    elseif typ == Rank
        return cs.Rank
    elseif typ == Assignment
        return cs.Assignment
    elseif typ == Affiliation
        return cs.Affiliation
    elseif typ == Job
        return cs.Job
    elseif typ == SubJob
        return cs.SubJob
    end
end
