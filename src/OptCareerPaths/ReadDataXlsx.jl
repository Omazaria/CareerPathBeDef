# This file reads the career paths from the excel file. Career paths developed by Guy

#XlsxFile = "C:/Users/Administrator/Dropbox/JuliaManpowerPlanning/GuyCareerPathsAllPop.xlsx"

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
    ActualSeniority::Int
    InitMPcluster()=new("", 0, 0)
    InitMPcluster(acdlvl::String, senior::Int, nb::Int) = new(acdlvl, senior, nb, senior)
end

InitManpower = Vector{InitMPcluster}()

type ManpowerObjective
    priority::Int
    targetLevel::Vector{DataType}
    Objectives::Vector{String}
    Number::Int
    Relation::String #relation between the diferent levels and / or
    InitTolerance::Float64
    EndTolerance::Float64
    Alfa::Float64
    PlotNb::Int
    ManpowerObjective(pri::Int;
                      target::Vector{DataType} = Vector{DataType}(),
                      obj::Vector{String} = Vector{String}(),
                      nb::Int = 0,
                      rl = "",
                      initT = 0.0,
                      endT = 0.0,
                      alfa = 1.0,
                      plot = 0) = new(pri, target, obj, nb, rl, initT, endT, alfa, plot)
end

TypesDict = Dict{String, DataType}("Academ"=> AcademicLevel,
                                   "Affil"=> Affiliation,
                                   "Assign"=> Assignment,
                                   "Rank"=> Rank,
                                   "Job"=> Job,
                                   "SubJob"=> SubJob)

type Subpopulation
    priority::Int
    Name::String
    NbRequired::Int

    Subpopulation(;pr = 1, nm = "", nb = 0) = new(pr, nm, nb)

end
MPObjectives = Vector{ManpowerObjective}()

#begin
    if !isdefined(:CPworkbook)
        CPworkbook = Workbook(XlsxFile)
        GIsheet = getSheet(CPworkbook, "GeneralInfo")
        CPsheet = getSheet(CPworkbook, "CareerPaths")
        CPDurationsheet = getSheet(CPworkbook, "CPDurations")
        CPAttritionsheet = getSheet(CPworkbook, "AttritionRate")
        InitMPsheet = getSheet(CPworkbook, "InitMP")
        Objsheet = getSheet(CPworkbook, "Objective")
        RecruitmentSheet = getSheet(CPworkbook, "Recruitment")
        SubpopulationSheet = getSheet(CPworkbook, "SubPopulations")
    end
#end

    # Reading General Information __________________________________________________
SimulationName = getCellValue(getCell(getRow(GIsheet, 0), 1))
SaveInputs = (getCellValue(getCell(getRow(GIsheet, 1), 1)) == "Yes")
IntegerSolution = (getCellValue(getCell(getRow(GIsheet, 2), 1)) == "Yes")
Tolerances_MIPGap = getCellValue(getCell(getRow(GIsheet, 3), 1))
SimulationYear = Int(getCellValue(getCell(getRow(GIsheet, 4), 1)))
PlottingResults = (getCellValue(getCell(getRow(GIsheet, 5), 1)) == "Yes")
AgeDistPlot = (getCellValue(getCell(getRow(GIsheet, 6), 1)) == "Yes")
println("Simulation : $SimulationName, saving input data : $SaveInputs.")


    # Reading Sub populations __________________________________________________

SubPopulations = Vector{Subpopulation}()

subpopnumber = jcall(SubpopulationSheet, "getLastRowNum", jint, ())

for i in 0:subpopnumber
    Row = getRow(SubpopulationSheet, i)
    push!(SubPopulations, Subpopulation( nm = getCellValue(getCell(Row, 0))))
end

    # Reading Career paths _________________________________________________________

    CPnumber = jcall(CPsheet, "getLastRowNum", jint, ()) + 1

    GuyCareerPaths = Vector{CareerPath}()

    for i in 0:CPnumber-1
        WorkingCP = getRow(CPsheet, i)

        for aff in 1:length(SubPopulations)
            if getCellValue(getCell(WorkingCP, 0)) == 1
                CPDuration = getRow(CPDurationsheet, i)
                CPAttrition = getRow(CPAttritionsheet, i)
                j = 2
                push!(GuyCareerPaths, CareerPath())
                GuyCareerPaths[end].RecruitmentAge = Int(getCellValue(getCell(CPDuration, 12)))
                while true
                    StLevel = getCellValue(getCell(WorkingCP, j))
                    j+=1
                    NdLevel = getCellValue(getCell(WorkingCP, j))
                    j+=1
                    StatusDuration = Int(getCellValue(getCell(CPDuration, length(GuyCareerPaths[end].Path))))
                    attr = Float16(getCellValue(getCell(CPAttrition, length(GuyCareerPaths[end].Path))))
                    ActivateLevel(GuyCareerPaths[end], AcademicLevel)
                    ActivateLevel(GuyCareerPaths[end], Assignment)
                    addStateToCareerPath(GuyCareerPaths[end], CareerStatus(academicLevel=AcademicLevel(StLevel), affiliation=Affiliation(SubPopulations[aff].Name), assignment=Assignment(NdLevel), min=StatusDuration, max=StatusDuration, attrition=attr))
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
                end
            end
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

    # Reading Recruitment Max/min __________________________________________________

    NBYears = 0

    MaxRecruitment = Vector{Int}()
    MinRecruitment = Vector{Int}()
    recruitMaxRow = getRow(RecruitmentSheet, 1)
    recruitMinRow = getRow(RecruitmentSheet, 2)

    while true
        try
            CellMax = getCellValue(getCell(recruitMaxRow, NBYears+1))
            CellMin = getCellValue(getCell(recruitMinRow, NBYears+1))
            NBYears += 1
            push!(MaxRecruitment, CellMax)
            push!(MinRecruitment, CellMin)
        catch
            break
        end
    end

    AllowableDeviation = getCellValue(getCell(getRow(RecruitmentSheet, 4), 1))

    # Reading Objective manpower ___________________________________________________

    Objnumber = jcall(Objsheet, "getLastRowNum", jint, ())
    #Cellj = 0
    for i in 1:Objnumber
        ObjRow = getRow(Objsheet, i)
        PriorI = getCellValue(getCell(ObjRow, 0))
        NbDemnded = Int(getCellValue(getCell(ObjRow, 1)))
        tolInit = getCellValue(getCell(ObjRow, 2))
        TolEnd =  getCellValue(getCell(ObjRow, 3))
        plotnb = getCellValue(getCell(ObjRow, 4))
        Alfa = (tolInit-TolEnd)/(NBYears-1)
        push!(MPObjectives, ManpowerObjective(Int(PriorI), nb = NbDemnded, initT = tolInit, endT = TolEnd, alfa = Alfa, plot = plotnb))
        indexObj = length(MPObjectives)
        j = 5
        while true
            try
                Cellj = getCellValue(getCell(ObjRow, j))
                j += 1
            catch
                if length(MPObjectives[indexObj].Objectives) == 0
                    push!(MPObjectives[indexObj].Objectives, "")
                    push!(MPObjectives[indexObj].targetLevel, AcademicLevel)
                end
                break
            end
            if Cellj == nothing
                #push!(MPObjectives[indexObj].Objectives, Requirements)
                if length(MPObjectives[indexObj].Objectives) == 0
                    push!(MPObjectives[indexObj].Objectives, "")
                    push!(MPObjectives[indexObj].targetLevel, AcademicLevel)
                end
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
