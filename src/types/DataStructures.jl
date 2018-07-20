# type for initial manpower described as [Academic Level, Seniority, Personnel Number]
type InitMPcluster
    Academiclvl::String
    Affiliation::String
    Seniority::Int
    Nb::Int
    ActualSeniority::Int
    InitMPcluster()=new("", 0, 0)
    InitMPcluster(acdlvl::String, affil::String, senior::Int, nb::Int) = new(acdlvl, affil, senior, nb, senior)
end

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
