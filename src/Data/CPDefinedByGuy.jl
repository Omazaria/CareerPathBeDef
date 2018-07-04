# This file reads the career paths from the excel file. Career paths developed by Guy

#XlsxFile = "C:/Users/Administrator/Dropbox/JuliaManpowerPlanning/GuyCareerPaths.xlsx"

requiredTypes = [ "AcademicLevel", "Affiliation", "Assignment", "CareerStatus", "Job", "Rank", "SubJob", "CareerPath" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "..", "functions", reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end

if !isdefined(:Taro)
    using Taro, JavaCall
    Taro.init()
end


# type for initial manpower described as [Academic Level, Seniority, Personnel Number]
type InitMPcluster
    Academiclvl::String
    Seniority::Int
    Nb::Int
    InitMPcluster()=new("", 0, 0)
    InitMPcluster(acdlvl::String, senior::Int, nb::Int) = new(acdlvl, senior, nb)
end

InitManpower = Vector{InitMPcluster}()

type ManpowerObjective
    priority::Int
    targetLevel::Vector{DataType}
    Objectives::Vector{String}#Vector{}
    Number::Int#Vector{}

    ManpowerObjective(pri::Int;
                      target::Vector{DataType} = Vector{DataType}(),
                      obj::Vector{String} = Vector{String}(),
                      nb::Int = 0 ) = new(pri, target, obj, nb)
end

TypesDict = Dict{String, DataType}("Academ"=> AcademicLevel,
                                   "Affil"=> Affiliation,
                                   "Assign"=> Assignment,
                                   "Rank"=> Rank,
                                   "Job"=> Job,
                                   "SubJob"=> SubJob)

MPObjectives = Vector{ManpowerObjective}()

#begin
    if !isdefined(:CPworkbook)
        CPworkbook = Workbook(XlsxFile)
        CPsheet = getSheet(CPworkbook, "CareerPaths")
        CPDurationsheet = getSheet(CPworkbook, "CPDurations")
        CPAttritionsheet = getSheet(CPworkbook, "AttritionRate")
        InitMPsheet = getSheet(CPworkbook, "InitMP")
        Objsheet = getSheet(CPworkbook, "Objective")
        RecruitmentSheet = getSheet(CPworkbook, "Recruitment")
    end


    # Reading Career paths _________________________________________________________

    CPnumber = jcall(CPsheet, "getLastRowNum", jint, ()) + 1

    GuyCareerPaths = Vector{CareerPath}()

    for i in 0:CPnumber-1
        WorkingCP = getRow(CPsheet, i)
        #print("CP$(i+1): ")

        if getCellValue(getCell(WorkingCP, 0)) == 1
            CPDuration = getRow(CPDurationsheet, i)
            CPAttrition = getRow(CPAttritionsheet, i)
            j = 2
            push!(GuyCareerPaths, CareerPath())
            while true
                Cellj = getCell(WorkingCP, j)
                StLevel = getCellValue(Cellj)
                j+=1
                Cellj = getCell(WorkingCP, j)
                NdLevel = getCellValue(Cellj)
                j+=1
                StatusDuration = Int(getCellValue(getCell(CPDuration, length(GuyCareerPaths[end].Path))))
                attr = Float16(getCellValue(getCell(CPAttrition, length(GuyCareerPaths[end].Path))))
                ActivateLevel(GuyCareerPaths[end], AcademicLevel)
                ActivateLevel(GuyCareerPaths[end], Assignment)
                addStateToCareerPath(GuyCareerPaths[end], CareerStatus(academicLevel=AcademicLevel(StLevel), assignment=Assignment(NdLevel), min=StatusDuration, max=StatusDuration, attrition=attr))
                Cellj = getCell(WorkingCP, j)
                trans = getCellValue(Cellj)
                j+=1
                # if the end of the career path reached
                if trans == "PE"
                    # if it finnishes with a pension we set the career path length to MaxCareerPathLength
                    break
                elseif trans == "B-"
                    # if it finnishes with a B- we set the career path length to 7
                    break
                elseif trans == nothing
                    # if it has an undefined end we set the career path length to 0
                    break
                end
                #print("(", StLevel, ",", NdLevel, ") ", trans, " ")
            end
            #println(".")
        end
    end

println("End CP")
    # Reading Initial manpower _____________________________________________________

    InitMPnumber = jcall(InitMPsheet, "getLastRowNum", jint, ())

    if InitMPnumber < 1
        warn("Init were not defined.")
    else
        for i in 1:InitMPnumber
            MPRow = getRow(InitMPsheet, i)
            push!(InitManpower, InitMPcluster(getCellValue(getCell(MPRow, 1)), Int(SimulationYear - getCellValue(getCell(MPRow, 0))), Int(getCellValue(getCell(MPRow, 2)))))
        end
    end
#    HeaderRow = getRow(InitMPsheet, 0)

#    Headers = Vector{String}()
#    j = 1
#    Cellj = getCell(HeaderRow, 0)
#    tempAclvl = getCellValue(Cellj)
#    while true
#        try
#            Cellj = getCell(HeaderRow, j)
#            tempAclvl = getCellValue(Cellj)
#            j +=1
#        catch
#            break
#        end
        #println(tempAclvl)

#        if tempAclvl == nothing
#            break
#        else
#            push!(Headers, tempAclvl)
#        end
#    end

#    for i in 1:InitMPnumber
#        MPRow = getRow(InitMPsheet, i)
#        Cellj = getCell(MPRow, 0)
#        MPSeniority = getCellValue(Cellj)

#        for j in 1:length(Headers)
#            Cellj = getCell(MPRow, j)
#            nbinitmp = getCellValue(Cellj)

#            push!(InitManpower, InitMPcluster(Headers[j], Int(MPSeniority), Int(nbinitmp)))
#        end
#    end


    # Reading Objective manpower ___________________________________________________

    Objnumber = jcall(Objsheet, "getLastRowNum", jint, ())

    for i in 0:Objnumber
        ObjRow = getRow(Objsheet, i)
        PriorI = getCellValue(getCell(ObjRow, 0))
        #indexObj = -1
        #for j in 1:length(MPObjectives)
        #    if PriorI == MPObjectives[j].priority
        #        indexObj = j
        #        break
        #    end
        #end
        #if indexObj == -1
        push!(MPObjectives, ManpowerObjective(Int(PriorI)))
        indexObj = length(MPObjectives)
        #end
        j = 1
        #Requirements = Vector{String}()
        while true
            try
                Cellj = getCellValue(getCell(ObjRow, j))
                j += 1
            catch
                break
            end
            if typeof(Cellj) != String
                #push!(MPObjectives[indexObj].Objectives, Requirements)
                if length(MPObjectives[indexObj].Objectives) == 0
                    push!(MPObjectives[indexObj].Objectives, "")
                    push!(MPObjectives[indexObj].targetLevel, AcademicLevel)
                end
                MPObjectives[indexObj].Number = Int(Cellj)
                break
            end
            if !(TypesDict[Cellj] in MPObjectives[indexObj].targetLevel)
                push!(MPObjectives[indexObj].targetLevel, TypesDict[Cellj])
            end
            Cellj = getCellValue(getCell(ObjRow, j))
            j += 1
            push!(MPObjectives[indexObj].Objectives, Cellj)
        end
    end
#end

    # Reading Recruitment Max ___________________________________________________

    NBYears = 0

    MaxRecruitment = Vector{Int}()
    recruitmentRow = getRow(RecruitmentSheet, 1)

    while true
        try
            Cellj = getCellValue(getCell(recruitmentRow, NBYears))
            NBYears += 1
            push!(MaxRecruitment, Cellj)
        catch
            break
        end
    end
