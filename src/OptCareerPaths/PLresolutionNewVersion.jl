#writedlm("matrix.txt", A)

#_______________________________________________________________________________
# MIP resolution
println("Solving LP...")
using MathProgBase, CPLEX#, Gurobi
stattoendStart = now()
if IntegerSolution
    sol = mixintprog(Cost, A, sense, b, vartypes, 0, Inf, CplexSolver(CPXPARAM_MIP_Tolerances_MIPGap=Tolerances_MIPGap))#CbcSolver(allowableGap=0.8)) #GurobiSolver(Presolve=0)
else
    sol = linprog(Cost, A, sense, b, 0, Inf, CplexSolver(CPX_PARAM_EPINT = 0.5))
end
stattoendEnd = now()
println( "ended with: $(sol.status). Elapsed time: $(Dates.canonicalize(Dates.CompoundPeriod(Dates.Millisecond(stattoendEnd - stattoendStart))))." )
writedlm("solution.txt", sol.sol)
