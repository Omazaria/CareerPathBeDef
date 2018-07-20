
#_______________________________________________________________________________
# Input variables

MaxCareerPathLength = 40
# GuyCareerPaths , InitManpower , MPObjectives

#_______________________________________________________________________________
# Variables number

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

AnnualRecDivNb = length(GuyCareerPaths) * NBYears

DeviationVarNb = length(MPObjectives) * NBYears * 2

VarNb = InitMPDivisionNb + AnnualRecDivNb + DeviationVarNb

#_______________________________________________________________________________
# Constraints number

InitConst = length(InitManpower)

RecruitmentConst = NBYears * 2

GoalsConst = (NBYears * length(MPObjectives))*2

RecruitmentDeviation = (NBYears - 1) * 2

#DeviationSubPop = length(SubPopulations)* NBYears * 2

ConstNb = InitConst + RecruitmentConst + GoalsConst + RecruitmentDeviation #+ DeviationSubPop

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

    # Fill A
        # Initial Manpower Constraints
AdvacmentY = 0
for i in 1:InitConst
    for j in 1:length(InitMPPartCP[i])
        A[i, AdvacmentY + j] = 1
    end
    AdvacmentY += length(InitMPPartCP[i])
end

        # Annual Recruitment
            # Max recruitment
for i in 1:Int(RecruitmentConst/2)
    for j in 1:length(GuyCareerPaths)
        A[InitConst + i, InitMPDivisionNb + (i-1)*length(GuyCareerPaths) + j] = 1
    end
end
            # Min recruitment   ________________________________________________ To verify
for i in 1:Int(RecruitmentConst/2)
    for j in 1:length(GuyCareerPaths)
        A[InitConst + NBYears + i, InitMPDivisionNb + (i-1)*length(GuyCareerPaths) + j] = 1
    end
end

            # compute which careers go with each goal

SetsPartCPinGoals = Vector{Vector{Vector{Int}}}()

for i in 1:length(GuyCareerPaths)
    AllParticipations = Vector{Vector{Int}}()
    for j in 1:length(GuyCareerPaths[i].Path)
        Participation = Vector{Int}()

        for k in 1:length(MPObjectives)
            isparticipating = true
            for subObj in 1:length(MPObjectives[k].targetLevel)
                if !contains(get_Name_Level(GuyCareerPaths[i].Path[j], MPObjectives[k].targetLevel[subObj]), MPObjectives[k].Objectives[subObj])#_______________________________________________________________________________
                    isparticipating = false#push!(Participation, k)
                    break
                end
            end

            if isparticipating
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

        # Goals___________________________________________________ (upper bound)

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
                if (j - InitManpower[imp].Seniority - 1) <= NBYears
                    A[InitConst + RecruitmentConst + (j - InitManpower[imp].Seniority - 1)*length(MPObjectives) + SetsPartCPinGoals[InitMPPartCP[imp][i]][indx][k], TempActualVar] = 1
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
                    A[InitConst + RecruitmentConst + (y - 1)*length(MPObjectives) + (j - 1)*length(MPObjectives) + SetsPartCPinGoals[i][indx][k], InitMPDivisionNb + (y - 1)*length(GuyCareerPaths) + i] = 1 - AttritionAtYear(GuyCareerPaths[i], j)
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

    # Goals___________________________________________________ (lower bound)

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
                if (j - InitManpower[imp].Seniority - 1) <= NBYears
                    A[InitConst + RecruitmentConst + Int(GoalsConst/2) + (j - InitManpower[imp].Seniority - 1)*length(MPObjectives) + SetsPartCPinGoals[InitMPPartCP[imp][i]][indx][k], TempActualVar] = 1
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
                    A[InitConst + RecruitmentConst + Int(GoalsConst/2) + (y - 1)*length(MPObjectives) + (j - 1)*length(MPObjectives) + SetsPartCPinGoals[i][indx][k], InitMPDivisionNb + (y - 1)*length(GuyCareerPaths) + i] = 1 - AttritionAtYear(GuyCareerPaths[i], j)
                end
            end
        end
    end
end

    # deviation variables
for y in 1:NBYears
for eq in 1:length(MPObjectives)

A[InitConst + RecruitmentConst + Int(GoalsConst/2) + (y - 1)*length(MPObjectives) + eq, InitMPDivisionNb + AnnualRecDivNb +                                  (y - 1)*length(MPObjectives) + eq] =  1
A[InitConst + RecruitmentConst + Int(GoalsConst/2) + (y - 1)*length(MPObjectives) + eq, InitMPDivisionNb + AnnualRecDivNb + length(MPObjectives) * NBYears + (y - 1)*length(MPObjectives) + eq] = -1

end
end

            # Recruitment deviation

for i in 1:NBYears-1
    for j in 1:length(GuyCareerPaths)
        A[InitConst + RecruitmentConst + GoalsConst + i, InitMPDivisionNb + (i)*length(GuyCareerPaths) + j] = 1
        A[InitConst + RecruitmentConst + GoalsConst + i, InitMPDivisionNb + (i-1)*length(GuyCareerPaths) + j] = -( 1 +  AllowableDeviation)
    end
end

for i in 1:NBYears-1
    for j in 1:length(GuyCareerPaths)
        A[InitConst + RecruitmentConst + GoalsConst + (NBYears - 1) + i, InitMPDivisionNb + (i)*length(GuyCareerPaths) + j] = 1
        A[InitConst + RecruitmentConst + GoalsConst + (NBYears - 1) + i, InitMPDivisionNb + (i-1)*length(GuyCareerPaths) + j] = -(1 - AllowableDeviation)
    end
end
    # Fill sense

sense[1:InitConst] = '='
sense[(InitConst + 1):(InitConst + Int(RecruitmentConst/2))] = '<'
sense[(InitConst + Int(RecruitmentConst/2) + 1):(InitConst + RecruitmentConst)] = '>'
sense[(InitConst + RecruitmentConst + 1):(InitConst + RecruitmentConst + Int(GoalsConst/2))] = '<'
sense[(InitConst + RecruitmentConst + Int(GoalsConst/2) + 1):(InitConst + RecruitmentConst + GoalsConst)] = '>'
sense[(InitConst + RecruitmentConst + GoalsConst + 1):(InitConst + RecruitmentConst + GoalsConst + (NBYears - 1))] = '<'
sense[(InitConst + RecruitmentConst + GoalsConst + (NBYears - 1) + 1):(InitConst + RecruitmentConst + GoalsConst + (NBYears - 1) + (NBYears - 1))] = '>'
#sense[(InitConst + RecruitmentConst + GoalsConst + (NBYears - 1) + (NBYears - 1) + 1):end] = '='
    # Fill b
for i in 1:InitConst
    b[i] = InitManpower[i].Nb
end
b[(InitConst +                           1):(InitConst + Int(RecruitmentConst/2))] = MaxRecruitment
b[(InitConst + Int(RecruitmentConst/2) + 1):(InitConst +  RecruitmentConst   )] = MinRecruitment
# Goals second part
index = InitConst + RecruitmentConst + 1
for y in 1:NBYears
    for i in 1:length(MPObjectives)
        b[index] = MPObjectives[i].Number*(1 + (MPObjectives[i].InitTolerance - (MPObjectives[i].Alfa)*(y-1)) )
        index += 1
    end
end
for y in 1:NBYears
    for i in 1:length(MPObjectives)
        b[index] = MPObjectives[i].Number*(1 - (MPObjectives[i].InitTolerance - (MPObjectives[i].Alfa)*(y-1)))
        index += 1
    end
end
#for y in 1:NBYears
#    for i in 1:length(SubPopulations)
#        b[index] = SubPopulations[i].NbRequired
#        index += 1
#    end
#end
    # Fill vartypes

vartypes[1:(InitMPDivisionNb + AnnualRecDivNb)] = :Int
vartypes[(InitMPDivisionNb + AnnualRecDivNb + 1):end] = :Cont

writedlm("matrix.txt", A)

#_______________________________________________________________________________
# MIP resolution
println("Solving LP...")
using MathProgBase, CPLEX#, Gurobi
stattoendStart = now()
if IntegerSolution
    sol = mixintprog(Cost, A, sense, b, vartypes, 0, Inf, CplexSolver(CPXPARAM_MIP_Tolerances_MIPGap=Tolerances_MIPGap))#CbcSolver(allowableGap=0.8)) #GurobiSolver(Presolve=0)
else
    sol = linprog(Cost, A, sense, b, 0, Inf, CplexSolver())
end
stattoendEnd = now()
println( "ended with: $(sol.status). Elapsed time: $(Dates.canonicalize(Dates.CompoundPeriod(Dates.Millisecond(stattoendEnd - stattoendStart))))." )
writedlm("solution.txt", sol.sol)

#_______________________________________________________________________________
# Computing results

RequirementFulfillment = zeros(Float64, NBYears, length(MPObjectives))
sumi = 0
for i in 1:NBYears
    for j in 1:length(MPObjectives)
        for k in 1:(InitMPDivisionNb + AnnualRecDivNb)
            if A[InitConst + RecruitmentConst + (i - 1)*length(MPObjectives) + j, k] != 0
                RequirementFulfillment[i, j] +=  sol.sol[k]*A[InitConst + RecruitmentConst + (i - 1)*length(MPObjectives) + j, k]#round(Int,)
            end
        end
    end
end

YearlyRecruitment = zeros(Float64, NBYears)

for i in 1:NBYears
    for j in 1:length(GuyCareerPaths)
        YearlyRecruitment[i] += sol.sol[InitMPDivisionNb + (i - 1)*length(GuyCareerPaths) + j]
    end
end
