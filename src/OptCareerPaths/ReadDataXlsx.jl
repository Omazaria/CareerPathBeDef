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
    DependenciesSheet = getSheet(CPworkbook, "CPDependecies")
end

InitManpower = Vector{InitMPcluster}()

MPObjectives = Vector{ManpowerObjective}()


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
                j = 3
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
    BasicCPNb = Int(length(GuyCareerPaths)/length(SubPopulations))
println("End CP")
    # Reading Initial manpower _____________________________________________________

    InitMPnumber = jcall(InitMPsheet, "getLastRowNum", jint, ())

    if InitMPnumber < 1
        warn("Init were not defined.")
    else
        for i in 1:InitMPnumber
            MPRow = getRow(InitMPsheet, i)
            push!(InitManpower, InitMPcluster(getCellValue(getCell(MPRow, 1)), getCellValue(getCell(MPRow, 2)), Int(SimulationYear - getCellValue(getCell(MPRow, 0))), Int(getCellValue(getCell(MPRow, 3)))))
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

# Reading Dependencies  ___________________________________________________
DepNB = Int(getCellValue(getCell(getRow(DependenciesSheet, 0), 1)))
NBConstDepend = 0
Dependencies = Vector{Dependency}()
#println("Dependencies", Dependencies)
RowIndex = 2
tempoSet = Vector{Int}()

for i in 1:DepNB
    nbSets = Int(getCellValue(getCell(getRow(DependenciesSheet, RowIndex), 1)))
    NBConstDepend += nbSets
    TempoDep = Dependency()
    RowIndex += 1
    for j in 1:nbSets
        SetRow = getRow(DependenciesSheet, RowIndex)
        RowIndex += 1
        cellindex = 1
        while true
            try
                CPinx = Int(getCellValue(getCell(SetRow, cellindex))); cellindex += 1
                SupPopName = getCellValue(getCell(SetRow, cellindex)); cellindex += 1
                SubPopIndex = findfirst(x -> x.Name == SupPopName, SubPopulations)
                push!(tempoSet, CPinx + ((SubPopIndex-1)*BasicCPNb))
            catch
                push!(TempoDep.Sets, tempoSet)
                tempoSet = Vector{Int}()
                break
            end
        end

    end

    SetRow = getRow(DependenciesSheet, RowIndex)
    RowIndex += 1
    for i in 1:nbSets
        push!(TempoDep.Percentages, getCellValue(getCell(SetRow, i)))
    end

    TempoDep.Priority = Int(getCellValue(getCell(getRow(DependenciesSheet, RowIndex), 1)))
    RowIndex += 1

    push!(Dependencies, TempoDep)

    RowIndex += 1
end
