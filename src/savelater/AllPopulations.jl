requiredTypes = [ "AcademicLevel", "Affiliation", "Assignment", "CareerStatus", "Job", "Rank", "SubJob", "CareerPath" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "..", "functions", reqType * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end
#println(joinpath( dirname( Base.source_path() ), "..", "..", "..", GuyCareerPathsAll.xlsx ) )

#_______________________________________________________________________________
# Input variables

MaxCareerPathLength = 40

SimulationYear = 2018

XlsxFile = joinpath( dirname( Base.source_path() ), "..", "..", "..", "GuyCareerPathsAllPop.xlsx" )

requiredData = ["CPByGuyAllpop"] # GuyCareerPaths , InitManpower , MPObjectives

for reqData in requiredData
    if !isdefined( Symbol( uppercase( string( reqData[ 1 ] ) ) * reqData[ 2:end ] ) )
        include( joinpath( dirname( Base.source_path() ), "..", "Data", reqData * ".jl" ) )
    end  # if !isdefined( Symbol( ...
end


#_______________________________________________________________________________
# Variables number

    # Compute which careers could each Initial manpower subset go with

InitMPPartCP = Array{Vector{Int}}(length(InitManpower))
InitMPDivisionNb = 0
for i in 1:length(InitManpower)
    InitIpartCP = Vector{Int}()
    for j in 1:length(GuyCareerPaths)
        index = get_status_index_after_duration(GuyCareerPaths[j], InitManpower[i].Seniority + 1)
        if index == -1
            continue
        end
        if contains(get_Name_Level(GuyCareerPaths[j].Path[index], AcademicLevel), InitManpower[i].Academiclvl)
            push!(InitIpartCP, j)
        end
    end
    InitMPPartCP[i] = InitIpartCP
    InitMPDivisionNb += length(InitIpartCP)
end
InitMPDivNbOnePop = InitMPDivisionNb
InitMPDivisionNb *= length(SubPopulations)

AnnualRecDivNbOnePop = length(GuyCareerPaths) * NBYears
AnnualRecDivNb = AnnualRecDivNbOnePop * length(SubPopulations)

DeviationVarNb = length(MPObjectives) * NBYears * 2

DeviationSubPop = length(SubPopulations)* NBYears * 2

VarNb = InitMPDivisionNb + AnnualRecDivNb + DeviationVarNb + DeviationSubPop

#_______________________________________________________________________________
# Constraints number

InitConst = length(InitManpower)

RecruitmentConst = NBYears

GoalsConst = NBYears * length(MPObjectives)

RecruitmentDeviation = (NBYears - 1) * 2

SubPopConst = length(SubPopulations)* NBYears

ConstNb = InitConst + RecruitmentConst + GoalsConst + RecruitmentDeviation + SubPopConst

#_______________________________________________________________________________
# MIP construction
    # Definition of Arrays

Cost = Array{Float64}(VarNb) # Done

A = zeros(Float64, ConstNb, VarNb) # Init Done, Rec Done, Goal Done

sense = Array{Char}(ConstNb) # Done

b = zeros(Float64, ConstNb)#Array{Float64}(ConstNb) # Done

vartypes = Array{Symbol}(VarNb) # Done

    # Fill Cost
Cost[1:(InitMPDivisionNb)] = 0
Cost[1 + InitMPDivisionNb:(InitMPDivisionNb + AnnualRecDivNb)] = 0
for i in 1:length(MPObjectives)
    for j in 1:NBYears
        Cost[(InitMPDivisionNb + AnnualRecDivNb) +                                  (j - 1)*length(MPObjectives) + i ] = MPObjectives[i].priority
        Cost[(InitMPDivisionNb + AnnualRecDivNb) + (length(MPObjectives)*NBYears) + (j - 1)*length(MPObjectives) + i ] = MPObjectives[i].priority
    end
end
for i in 1:length(SubPopulations)
    for j in 1:NBYears
        Cost[(InitMPDivisionNb + AnnualRecDivNb) + DeviationVarNb +                                    (j - 1)*length(SubPopulations) + i ] = SubPopulations[i].priority
        Cost[(InitMPDivisionNb + AnnualRecDivNb) + DeviationVarNb + (length(SubPopulations)*NBYears) + (j - 1)*length(SubPopulations) + i ] = SubPopulations[i].priority
    end
end
    # Fill A
        # Initial Manpower Constraints
AdvacmentY = 0
for i in 1:InitConst
    for j in 1:length(InitMPPartCP[i])
        for k in 1:length(SubPopulations)
            A[i, InitMPDivNbOnePop*(k-1) + AdvacmentY + j] = 1
        end
    end
    AdvacmentY += length(InitMPPartCP[i])
end

        # Annual Recruitment

for i in 1:(RecruitmentConst)
    for j in 1:length(GuyCareerPaths)
        for k in 1:length(SubPopulations)
            A[InitConst + i, InitMPDivisionNb + AnnualRecDivNbOnePop*(k-1) + (i-1)*length(GuyCareerPaths) + j] = 1
        end
    end
end

        # Goals

            # compute which careers go with each goal

SetsPartCPinGoals = Vector{Vector{Vector{Int}}}()

for i in 1:length(GuyCareerPaths)
    AllParticipations = Vector{Vector{Int}}()
    for j in 1:length(GuyCareerPaths[i].Path)
        Participation = Vector{Int}()

        for k in 1:length(MPObjectives)
            if contains(get_Name_Level(GuyCareerPaths[i].Path[j], MPObjectives[k].targetLevel[1]), MPObjectives[k].Objectives[1])#_______________________________________________________________________________
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

            # Initial Manpower participation

TempActualVar = 1
for imp in 1:length(InitManpower)
    for i in 1:length(InitMPPartCP[imp])
        for j in (1 + InitManpower[imp].Seniority):GuyCareerPaths[InitMPPartCP[imp][i]].Length
            indx = get_status_index_after_duration(GuyCareerPaths[InitMPPartCP[imp][i]], j)
            if indx == -1
                break
            end
            for k in 1:length(SetsPartCPinGoals[InitMPPartCP[imp][i]][indx])
                if (j - 1) <= NBYears
                    for l in 1:length(SubPopulations)
                        A[InitConst + RecruitmentConst + (j - InitManpower[imp].Seniority - 1)*length(MPObjectives) + SetsPartCPinGoals[InitMPPartCP[imp][i]][indx][k], InitMPDivNbOnePop*(l-1) + TempActualVar] = 1
                    end
                end
            end
        end
        TempActualVar += 1
    end
end

            # Annual Recruitment participation

for y in 1:NBYears
    for i in 1:length(GuyCareerPaths)
        for j in 1:GuyCareerPaths[i].Length # j => year for const
            indx = get_status_index_after_duration(GuyCareerPaths[i], j)
            if indx == -1
                break
            end
            for k in 1:length(SetsPartCPinGoals[i][indx])
                if (y + j - 1) <= NBYears
                    for l in 1:length(SubPopulations)
                        A[InitConst + RecruitmentConst + (y - 1)*length(MPObjectives) + (j - 1)*length(MPObjectives) + SetsPartCPinGoals[i][indx][k], InitMPDivisionNb + AnnualRecDivNbOnePop*(l-1) + (y - 1)*length(GuyCareerPaths) + i] = 1 - AttritionAtYear(GuyCareerPaths[i], j)
                    end
                end
            end
        end
    end
end

            # deviation variables
for y in 1:NBYears
    for eq in 1:length(MPObjectives)

        A[InitConst + RecruitmentConst + (y - 1)*length(MPObjectives) + eq, InitMPDivisionNb + AnnualRecDivNb +                                  (y - 1)*length(MPObjectives) + eq] =  1
        A[InitConst + RecruitmentConst + (y - 1)*length(MPObjectives) + eq, InitMPDivisionNb + AnnualRecDivNb + length(MPObjectives) * NBYears + (y - 1)*length(MPObjectives) + eq] = -1

    end
end

            # Recruitment deviation

for i in 1:NBYears-1
    for j in 1:length(GuyCareerPaths)
        for k in 1:length(SubPopulations)
            A[InitConst + RecruitmentConst + GoalsConst + i, InitMPDivisionNb + AnnualRecDivNbOnePop*(k-1) + (i  )*length(GuyCareerPaths) + j] = 1
            A[InitConst + RecruitmentConst + GoalsConst + i, InitMPDivisionNb + AnnualRecDivNbOnePop*(k-1) + (i-1)*length(GuyCareerPaths) + j] = -1.10
        end
    end
end

for i in 1:NBYears-1
    for j in 1:length(GuyCareerPaths)
        for k in 1:length(SubPopulations)
            A[InitConst + RecruitmentConst + GoalsConst + (NBYears - 1) + i, InitMPDivisionNb + AnnualRecDivNbOnePop*(k-1) + (i  )*length(GuyCareerPaths) + j] = 1
            A[InitConst + RecruitmentConst + GoalsConst + (NBYears - 1) + i, InitMPDivisionNb + AnnualRecDivNbOnePop*(k-1) + (i-1)*length(GuyCareerPaths) + j] = -0.90
        end
    end
end

# Subpopulations fulfillement


    # Participation of the recruitment 
for i in 1:NBYears
    for j in 1:length(SubPopulations)
        for k in 1:length(GuyCareerPaths)
            A[InitConst + RecruitmentConst + GoalsConst + RecruitmentDeviation + (i-1)*length(SubPopulations) + j, InitMPDivisionNb + ] = 1 #- AttritionAtYear(GuyCareerPaths[k], )
        end
    end
end


    # Fill sense

sense[1:InitConst] = '='
sense[(InitConst + 1):(InitConst + RecruitmentConst)] = '<'
sense[(InitConst + RecruitmentConst + 1):(InitConst + RecruitmentConst + GoalsConst)] = '='
sense[(InitConst + RecruitmentConst + GoalsConst + 1):(InitConst + RecruitmentConst + GoalsConst + (NBYears - 1))] = '<'
sense[(InitConst + RecruitmentConst + GoalsConst + (NBYears - 1) + 1):end] = '>'

    # Fill b
for i in 1:InitConst
    b[i] = InitManpower[i].Nb
end
b[(InitConst + 1):(InitConst + RecruitmentConst)] = MaxRecruitment
index = InitConst + RecruitmentConst + 1
for y in 1:NBYears
    for i in 1:length(MPObjectives)
        b[index] = MPObjectives[i].Number
        index += 1
    end
end

    # Fill vartypes

vartypes[1:(InitMPDivisionNb + AnnualRecDivNb)] = :Int
vartypes[(InitMPDivisionNb + AnnualRecDivNb + 1):end] = :Cont

writedlm("matrix.txt", A)

#_______________________________________________________________________________
# MIP resolution
println("Solving LP...")
using MathProgBase, CPLEX#, Gurobi
stattoendStart = now()
sol = mixintprog(Cost, A, sense, b, vartypes, 0, Inf, CplexSolver(CPXPARAM_MIP_Tolerances_MIPGap=0.01))#CbcSolver(allowableGap=0.8)) #GurobiSolver(Presolve=0)
stattoendEnd = now()
println( "ended with: $(sol.status). Elapsed time: $(Dates.canonicalize(Dates.CompoundPeriod(Dates.Millisecond(stattoendEnd - stattoendStart))))." )
writedlm("solution.txt", sol.sol)

#_______________________________________________________________________________
# Computing results

RequirementFulfillment = zeros(Float64, NBYears, length(MPObjectives))

for i in 1:NBYears
    for j in 1:length(MPObjectives)
        for k in 1:(InitMPDivisionNb + AnnualRecDivNb)
            if A[InitConst + RecruitmentConst + (i - 1)*length(MPObjectives) + j, k] != 0
                RequirementFulfillment[i, j] += round(Int, sol.sol[k]*A[InitConst + RecruitmentConst + (i - 1)*length(MPObjectives) + j, k])
            end
        end
    end
end

YearlyRecruitment = zeros(Float64, NBYears)

for i in 1:NBYears
    for j in 1:length(GuyCareerPaths)
        for k in 1:length(SubPopulations)
            YearlyRecruitment[i] += sol.sol[InitMPDivisionNb + AnnualRecDivNbOnePop*(k-1) + (i - 1)*length(GuyCareerPaths) + j]
        end
    end
end


include("WrittingResultsAllPop.jl")
