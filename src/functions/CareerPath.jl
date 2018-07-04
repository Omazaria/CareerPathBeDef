requiredTypes = [ "CareerPath" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "..", "types", reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end

function ActivateLevel(careerpath::CareerPath, level::DataType)
    push!(careerpath.ActivatedLevels, LevelsCodes[level])
end

function isActivatedLevel(careerpath::CareerPath, level::DataType)
    return LevelsCodes[level] in careerpath.ActivatedLevels
end

function addStateToCareerPath(cp::CareerPath, st::CareerStatus)
    push!(cp.Path, st)
end

function set_CareerPath_Length(cp::CareerPath, length::Int)
    cp.Length = length
end

function compute_Length(cp::CareerPath)
    if cp.Length == 0
        for i in 1:length(cp.Path)
            cp.Length += cp.Path[i].MinStay
        end
    end
end

function get_status_index_after_duration(cp::CareerPath, duration::Int)

    spentleng = 0
    index = -1
    for i in 1:length(cp.Path)
        spentleng += cp.Path[i].MinStay
        if spentleng >= duration
            index = i
            break
        end
    end
    return index
end

function AttritionAtYear(cp::CareerPath, year::Int)

    currentyear = 0
    attrition = 0
    index = 1
    sumprenode = 0
    while true
        currentyear += 1

        if currentyear > year
            break
        else
            if currentyear > sumprenode + cp.Path[index].MinStay
                sumprenode += cp.Path[index].MinStay
                index += 1
            end
            attrition += cp.Path[index].Attrition
        end
    end
    return attrition
end
