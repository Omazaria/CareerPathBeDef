
AgeDistribution = zeros(NBYears, 52)#[zeros(52) for i in 1:NBYears] # 52 = 18 -> 70

# Compute Age Distribution for Initial Manpower
TempActualVar = 1
for imp in 1:length(InitManpower)
    for i in 1:length(InitMPPartCP[imp])
        for j in (1 + InitManpower[imp].Seniority):GuyCareerPaths[InitMPPartCP[imp][i]].Length
            AgeDistribution[j - InitManpower[imp].Seniority, GuyCareerPaths[InitMPPartCP[imp][i]].RecruitmentAge + j - 18] += sol.sol[TempActualVar]
        end
        TempActualVar += 1
    end
end

# New recruits age distribution
for y in 1:NBYears
    for i in 1:length(GuyCareerPaths)
        for j in 1:GuyCareerPaths[i].Length # j => year for const
            if (y + j - 1) <= NBYears
                AgeDistribution[y + j - 1, GuyCareerPaths[i].RecruitmentAge + j - 18] +=  (1 - AttritionAtYear(GuyCareerPaths[i], j))* sol.sol[ InitMPDivisionNb + (y - 1)*length(GuyCareerPaths) + i]
            end
        end
    end
end


using Plots
plotly()

gui( surface([18:70],  [SimulationYear:(SimulationYear+NBYears)], AgeDistribution, xlabel = "Age (y)", ylabel = "Year", zlabel = "Amount", size=(1200,900), title = "Age distribution", color = :lightrainbow))
