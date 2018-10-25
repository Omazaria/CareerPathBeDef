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
    CPDurationsheet = getSheet(CPworkbook, "PathDuration")
    CPAttritionsheet = getSheet(CPworkbook, "PathAttrition")
    InitMPsheet = getSheet(CPworkbook, "InitMP")
    Objsheet = getSheet(CPworkbook, "Objective") # -----------------------------------------------------------
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

    # Reading Career paths _________________________________________________________ ******************* Change
IndexRow = 5
CPIndex = 0
GuyCareerPaths = Vector{CareerPath}()
while true
    CPRow = getRow(CPDurationsheet, IndexRow)
    DurationRow = getRow(CPDurationsheet, IndexRow + 1)
    AttritionRow = getRow(CPAttritionsheet, IndexRow + 1)
    IndexRow += 3
    try
        CPIndex = Int(getCellValue(getCell(CPRow, 0)))
    catch
        # We arrived to the last one
        break
    end
    for aff in 1:length(SubPopulations)
        push!(GuyCareerPaths, CareerPath())
        GuyCareerPaths[end].RecruitmentAge = Int(getCellValue(getCell(DurationRow, 4)))
        NodeIndex = 5

        while true
            #println("NodeIndex : ", NodeIndex)
            Node = split(getCellValue(getCell(CPRow, NodeIndex)))
            #println("Node : ", Node)
            StatusDuration = Int(round(getCellValue(getCell(DurationRow, NodeIndex))))
            #println("StatusDuration : ", StatusDuration)
            attr = Float64(getCellValue(getCell(AttritionRow, NodeIndex)))#/(StatusDuration == 0? 1:Float64(StatusDuration))
            #println("attr : ", attr)
            NodeIndex +=1

            ActivateLevel(GuyCareerPaths[end], AcademicLevel)
            ActivateLevel(GuyCareerPaths[end], Assignment)

            addStateToCareerPath(GuyCareerPaths[end], CareerStatus(academicLevel=AcademicLevel(String(Node[1])), affiliation=Affiliation(SubPopulations[aff].Name), assignment=Assignment(String(Node[2])), min=StatusDuration, max=StatusDuration, attrition=attr))#attr

            trans = getCellValue(getCell(CPRow, NodeIndex))
            NodeIndex +=1
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

    AllowableDeviation = Float64(getCellValue(getCell(getRow(RecruitmentSheet, 4), 1)))

    # Reading Objective manpower ___________________________________________________

function findindex(a, b)
    for i in 1:length(a)
        if a[i] == b
            return i
        end
    end
    return -1
end

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
                    push!(MPObjectives[indexObj].Objectives, Vector{String}([""]))
                    push!(MPObjectives[indexObj].targetLevel, AcademicLevel)
                end
                break
            end
            if Cellj == nothing
                #push!(MPObjectives[indexObj].Objectives, Requirements)
                if length(MPObjectives[indexObj].Objectives) == 0
                    push!(MPObjectives[indexObj].Objectives, Vector{String}([""]))
                    push!(MPObjectives[indexObj].targetLevel, AcademicLevel)
                end
                break
            end

            LevelIndex = 0
            if !(TypesDict[Cellj] in MPObjectives[indexObj].targetLevel)
                push!(MPObjectives[indexObj].targetLevel, TypesDict[Cellj])
                push!(MPObjectives[indexObj].Objectives, Vector{String}())
                LevelIndex = length(MPObjectives[indexObj].targetLevel)
            else
                LevelIndex = findindex(MPObjectives[indexObj].targetLevel, TypesDict[Cellj])
            end
            Cellj = getCellValue(getCell(ObjRow, j))
            j += 1
            push!(MPObjectives[indexObj].Objectives[LevelIndex], Cellj)
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

# Compute which careers could each Initial manpower subset go with

InitMPPartCP = Array{Vector{Int}}(length(InitManpower))
InitMPDivisionNb = 0
for i in 1:length(InitManpower)
    InitIpartCP = Vector{Int}()
    InitManpower[i].Seniority += 1
    while length(InitIpartCP) == 0 && InitManpower[i].Seniority > 0
        InitManpower[i].Seniority -= 1
        for j in 1:length(GuyCareerPaths)
            index = get_status_index_after_duration(GuyCareerPaths[j], InitManpower[i].Seniority + 1)
            if index == -1
                continue
            end
            if contains(get_Name_Level(GuyCareerPaths[j].Path[index], AcademicLevel), InitManpower[i].Academiclvl) && contains(get_Name_Level(GuyCareerPaths[j].Path[index], Affiliation), InitManpower[i].Affiliation)
                push!(InitIpartCP, j)
            end
        end
    end
    if length(InitIpartCP) == 0
        InitManpower[i].Nb = 0
        warn("Initial subpopulation \"Academ:$(InitManpower[i].Academiclvl),Seniority:$(InitManpower[i].ActualSeniority)\" is not considered.")
    end
    InitMPPartCP[i] = InitIpartCP
    InitMPDivisionNb += length(InitIpartCP)
end


# compute which careers go with each goal

SetsPartCPinGoals = Vector{Vector{Vector{Int}}}()

for i in 1:length(GuyCareerPaths)
    AllParticipations = Vector{Vector{Int}}()
    for j in 1:length(GuyCareerPaths[i].Path)
        Participation = Vector{Int}()
        isparticipating = false
        for k in 1:length(MPObjectives)
            for subObj in 1:length(MPObjectives[k].targetLevel)
                isparticipating = false
                for targetedVal in 1:length(MPObjectives[k].Objectives[subObj])
                    #if i == 1
                    #    print("check CP:", i," node ", j," obj:", k, " level: ", MPObjectives[k].targetLevel[subObj], " with value: ", get_Name_Level(GuyCareerPaths[i].Path[j], MPObjectives[k].targetLevel[subObj]), " target: ", MPObjectives[k].Objectives[subObj][targetedVal])
                    #end
                    if contains(get_Name_Level(GuyCareerPaths[i].Path[j], MPObjectives[k].targetLevel[subObj]), MPObjectives[k].Objectives[subObj][targetedVal])#_______________________________________________________________________________
                        #if i == 1
                        #    println(" -> Yes.")
                        #end
                        isparticipating = true
                        break
                    #else
                        #if i == 1
                        #    println(" -> No.")
                        #end
                    end
                end
                if !isparticipating
                    break
                end
            end

            if isparticipating
                #println("pushing obj :", k, " for node :", j, " of career path: ", i)
                push!(Participation, k)
            end
        end
        push!(AllParticipations, Participation)
    end
    push!(SetsPartCPinGoals, AllParticipations)
end

# Compute Career Paths Length

for i in 1:length(GuyCareerPaths)
    compute_Length(GuyCareerPaths[i])
end



# Free if not needed
# if !CleanMem || !SaveInputs
#     CPworkbook = 0
#     GIsheet = 0
#     CPDurationsheet = 0
#     CPAttritionsheet = 0
#     InitMPsheet = 0
#     Objsheet = 0
#     RecruitmentSheet = 0
#     SubpopulationSheet = 0
#     DependenciesSheet = 0
#     gc()
# end
