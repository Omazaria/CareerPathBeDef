#_______________________________________________________________________________
# Input variables

MaxCareerPathLength = 40
# GuyCareerPaths , InitManpower , MPObjectives

#_______________________________________________________________________________
# Variables number

AnnualRecDivNb = length(GuyCareerPaths) * NBYears

DeviationVarNb = length(MPObjectives) * NBYears * 2

DependDeviationVar = NBConstDepend * NBYears * 2

VarNb = InitMPDivisionNb + AnnualRecDivNb + DeviationVarNb + DependDeviationVar

#_______________________________________________________________________________
# Constraints number

InitConst = length(InitManpower)

RecruitmentConst = 0 #NBYears

GoalsConst = (NBYears * length(MPObjectives))*2

if AllowableDeviation < 0
    RecruitmentDeviation = 0
else
    #RecruitmentDeviation = (NBYears - 1) * 2 # Deviation on total Manpower Recruitment
    RecruitmentDeviation = (NBYears - 1) * 2 * length(GuyCareerPaths)
end

DependenciesConst = NBYears * NBConstDepend

ConstNb = InitConst + RecruitmentConst + GoalsConst + RecruitmentDeviation + DependenciesConst

#_______________________________________________________________________________
# MIP construction
    # Definition of Arrays

Cost = Array{Float64}(VarNb) # Done

println("Allocating a ", ConstNb, "x", VarNb, " Array")

A = zeros(Float64, ConstNb, VarNb) # Init Done, Rec Done, Goal Done

sense = Array{Char}(ConstNb) # Done

b = zeros(Float64, ConstNb)#Array{Float64}(ConstNb) # Done

vartypes = Array{Symbol}(VarNb) # Done

    # Fill Cost
Cost[1:(InitMPDivisionNb)] = 0
Cost[1 + InitMPDivisionNb:(InitMPDivisionNb + AnnualRecDivNb)] = 1
for i in 1:length(MPObjectives)
    for j in 1:NBYears
        if MPObjectives[i].priority >= 0
            Cost[(InitMPDivisionNb + AnnualRecDivNb) +                                  (j - 1)*length(MPObjectives) + i ] = (10^(MPObjectives[i].priority))*((j > 7)? 10 : 1)
            Cost[(InitMPDivisionNb + AnnualRecDivNb) + (length(MPObjectives)*NBYears) + (j - 1)*length(MPObjectives) + i ] = (10^(MPObjectives[i].priority))*((j > 7)? 10 : 1)
        else
            Cost[(InitMPDivisionNb + AnnualRecDivNb) +                                  (j - 1)*length(MPObjectives) + i ] = 0
            Cost[(InitMPDivisionNb + AnnualRecDivNb) + (length(MPObjectives)*NBYears) + (j - 1)*length(MPObjectives) + i ] = 0
        end
    end
end
tempoDepLine = 0
for i in 1:length(Dependencies)
    for j in 1:NBYears
        for k in 1:length(Dependencies[i].Sets)
            Cost[(InitMPDivisionNb + AnnualRecDivNb + DeviationVarNb) +                             (j - 1)*NBConstDepend + tempoDepLine + k ] = 10^(Dependencies[i].Priority)
            Cost[(InitMPDivisionNb + AnnualRecDivNb + DeviationVarNb) + (NBConstDepend * NBYears) + (j - 1)*NBConstDepend + tempoDepLine + k ] = 10^(Dependencies[i].Priority)
        end
    end
    tempoDepLine += length(Dependencies[i].Sets)
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
                    A[InitConst + RecruitmentConst + (y - 1)*length(MPObjectives) + (j - 1)*length(MPObjectives) + SetsPartCPinGoals[i][indx][k], InitMPDivisionNb + (y - 1)*length(GuyCareerPaths) + i] = RemainingAtYear(GuyCareerPaths[i], j)#AttritionAtYear
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
                    A[InitConst + RecruitmentConst + Int(GoalsConst/2) + (y - 1)*length(MPObjectives) + (j - 1)*length(MPObjectives) + SetsPartCPinGoals[i][indx][k], InitMPDivisionNb + (y - 1)*length(GuyCareerPaths) + i] = RemainingAtYear(GuyCareerPaths[i], j)#AttritionAtYear
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

            # Recruitment deviation *******************************************
if AllowableDeviation >= 0
    for i in 1:NBYears-1
        for j in 1:length(GuyCareerPaths)
            if i < YearsOfAllowedRecruitmentDev#0
                A[InitConst + RecruitmentConst + GoalsConst + (i-1)*(length(GuyCareerPaths)) + j, InitMPDivisionNb + (i  )*length(GuyCareerPaths) + j] = 0
                A[InitConst + RecruitmentConst + GoalsConst + (i-1)*(length(GuyCareerPaths)) + j, InitMPDivisionNb + (i-1)*length(GuyCareerPaths) + j] = 0
            else
                A[InitConst + RecruitmentConst + GoalsConst + (i-1)*(length(GuyCareerPaths)) + j, InitMPDivisionNb + (i  )*length(GuyCareerPaths) + j] = 1
                A[InitConst + RecruitmentConst + GoalsConst + (i-1)*(length(GuyCareerPaths)) + j, InitMPDivisionNb + (i-1)*length(GuyCareerPaths) + j] = -( 1 +  AllowableDeviation)
            end
        end
    end

    for i in 1:NBYears-1
        for j in 1:length(GuyCareerPaths)
            if i < YearsOfAllowedRecruitmentDev#0
                A[InitConst + RecruitmentConst + GoalsConst + (NBYears - 1)*length(GuyCareerPaths) + (i-1)*(length(GuyCareerPaths)) + j, InitMPDivisionNb + (i  )*length(GuyCareerPaths) + j] = 0
                A[InitConst + RecruitmentConst + GoalsConst + (NBYears - 1)*length(GuyCareerPaths) + (i-1)*(length(GuyCareerPaths)) + j, InitMPDivisionNb + (i-1)*length(GuyCareerPaths) + j] = 0
            else
                A[InitConst + RecruitmentConst + GoalsConst + (NBYears - 1)*length(GuyCareerPaths) + (i-1)*(length(GuyCareerPaths)) + j, InitMPDivisionNb + (i  )*length(GuyCareerPaths) + j] = 1
                A[InitConst + RecruitmentConst + GoalsConst + (NBYears - 1)*length(GuyCareerPaths) + (i-1)*(length(GuyCareerPaths)) + j, InitMPDivisionNb + (i-1)*length(GuyCareerPaths) + j] = -(1 - AllowableDeviation)
            end
        end
    end
end

            # Dependencies Equations *******************************************
# Consider Only the case of two dependecies sets.
tempoDepLine = 0
for i in 1:length(Dependencies)
    for j in 1:NBYears
        # Set 1
        for s in 1:length(Dependencies[i].Sets[1])
            A[InitConst + RecruitmentConst + GoalsConst + RecruitmentDeviation + (j-1)*NBConstDepend + i, InitMPDivisionNb + length(GuyCareerPaths)*(j - 1) + Dependencies[i].Sets[1][s]] = Dependencies[i].Percentages[2]
        end
        # Set 2
        for s in 1:length(Dependencies[i].Sets[2])
            A[InitConst + RecruitmentConst + GoalsConst + RecruitmentDeviation + (j-1)*NBConstDepend + i, InitMPDivisionNb + length(GuyCareerPaths)*(j - 1) + Dependencies[i].Sets[2][s]] = -Dependencies[i].Percentages[1]
        end
    end
end
#         for k in 1:length(Dependencies[i].Sets)
#             # Career Paths Variables
#             for l in 1:length(Dependencies[i].Sets)
#                 #println(i)
#                 #println(Dependencies[i].Sets[l][1])
#                 if l == k
#                     for m in 1:length(Dependencies[i].Sets[k])
#                         #println("st", i, " ", k, " ", m)
#                         A[InitConst + RecruitmentConst + GoalsConst + RecruitmentDeviation + (j-1)*NBConstDepend + tempoDepLine + k, InitMPDivisionNb + length(GuyCareerPaths)*(j - 1) + Dependencies[i].Sets[l][m]] = 1 - Dependencies[i].Percentages[k]
#                     end
#                 else
#                     for m in 1:length(Dependencies[i].Sets[k])
#                         #println("nd ", i, " ", l, " ", m)
#                         A[InitConst + RecruitmentConst + GoalsConst + RecruitmentDeviation + (j-1)*NBConstDepend + tempoDepLine + k, InitMPDivisionNb + length(GuyCareerPaths)*(j - 1) + Dependencies[i].Sets[k][m]] = Dependencies[i].Percentages[k]
#                     end
#                 end
#             end
#             # Deviation Variables
#             #A[(InitMPDivisionNb + AnnualRecDivNb + DeviationVarNb) +                             (j - 1)*NBConstDepend + tempoDepLine + k ] = 1
#             #A[(InitMPDivisionNb + AnnualRecDivNb + DeviationVarNb) + (NBConstDepend * NBYears) + (j - 1)*NBConstDepend + tempoDepLine + k ] = -1
#         end
#     end
#     tempoDepLine += length(Dependencies[i].Sets)
# end

    # Fill sense

sense[1:InitConst] = '='
sense[(InitConst + 1):(InitConst + Int(RecruitmentConst/2))] = '<'
sense[(InitConst + Int(RecruitmentConst/2) + 1):(InitConst + RecruitmentConst)] = '>'
sense[(InitConst + RecruitmentConst + 1):(InitConst + RecruitmentConst + Int(GoalsConst/2))] = '<'
sense[(InitConst + RecruitmentConst + Int(GoalsConst/2) + 1):(InitConst + RecruitmentConst + GoalsConst)] = '>'
if AllowableDeviation >= 0
    sense[(InitConst + RecruitmentConst + GoalsConst +                               1):(InitConst + RecruitmentConst + GoalsConst + Int(RecruitmentDeviation/2))] = '<'
    sense[(InitConst + RecruitmentConst + GoalsConst + Int(RecruitmentDeviation/2) + 1):(InitConst + RecruitmentConst + GoalsConst +     RecruitmentDeviation   )] = '>'
end
sense[(InitConst + RecruitmentConst + GoalsConst + RecruitmentDeviation + 1):(InitConst + RecruitmentConst + GoalsConst + RecruitmentDeviation + DependenciesConst)] = '='

    # Fill b
for i in 1:InitConst
    b[i] = InitManpower[i].Nb
end
try
    b[(InitConst +                           1):(InitConst + Int(RecruitmentConst/2))] = MaxRecruitment
    #b[(InitConst + Int(RecruitmentConst/2) + 1):(InitConst +  RecruitmentConst   )] = MinRecruitment
end
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

    # Fill vartypes



if IntegerSolution
    vartypes[1:(InitMPDivisionNb + AnnualRecDivNb)] = :Int
    vartypes[(InitMPDivisionNb + AnnualRecDivNb + 1):end] = :Cont
else
    vartypes[1:end] = :Cont
end


# Clean memory

if CleanMem

    InitManpower = 0
    MPObjectives = 0
    InitMPPartCP = 0
    SubPopulations = 0
    GuyCareerPaths = 0
    MaxRecruitment = 0
    #MinRecruitment = 0
    Dependencies = 0
    tempoSet = 0

    gc()
end
