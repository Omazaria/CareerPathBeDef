#=
    * Need to consider Duration
    * Activeted levels for career paths are not updated
=#
requiredTypes = [ "AcademicLevel", "Affiliation", "Assignment", "CareerPath", "CareerStatus", "Job", "Rank", "SubJob" ]

for reqType in requiredTypes
    if !isdefined( Symbol( uppercase( string( reqType[ 1 ] ) ) * reqType[ 2:end ] ) )
        include(  reqType * ".jl" )
    end  # if !isdefined( Symbol( ...
end

using LightGraphs

export ConstructCareerPaths
function ConstructCareerPaths(g::DiGraph, DefinedLevels::Array{Vector{AbstractLevel}})
    CareerPaths = Vector{CareerPath}()

		if size(DefinedLevels, 1) < 1
			warn("No level defined.")
			return CareerPaths
		end
		InitPaths = CreateInitPaths(g, DefinedLevels[1])

		for path in InitPaths
			push!(CareerPaths, path)
		end

        for i in 2:length(DefinedLevels)
            NextLevelPaths!(CareerPaths, DefinedLevels[i-1], DefinedLevels[i])
        end

        for i in 1:length(CareerPaths)
            for j in 1:length(DefinedLevels)
                ActivateLevel(CareerPaths[i], typeof(DefinedLevels[j][1]))
            end
        end
    return CareerPaths
end


function CreatePathFromGraph(g::DiGraph, n::Int)
	CarPa = Vector{Array{Int}}()
  if length(neighbors(g, n)) == 0
      push!(CarPa, [-1])
  else
      for neighbor in neighbors(g, n)
          tempPaths = CreatePathFromGraph(g, neighbor)
          for path in tempPaths
              push!(CarPa, [n path])
          end
      end
  end
  return CarPa
end

function CreateInitPaths(g::DiGraph, StLevel::Array{AbstractLevel})

	# Traversing the graph
	InitPaths = Vector{Array{Int}}()
	if is_cyclic(g)
			warn("The graph is cyclic.")
			return Array{CareerPaths}()
	else
			for node in neighbors(g, 1)
					tmpCarPat = CreatePathFromGraph(g, node)
					for path in tmpCarPat
							push!(InitPaths, path)
					end
			end
	end
	InitCareerPaths = Array{CareerPath}(length(InitPaths))
	for path in 1:length(InitPaths)
		InitCareerPaths[path] = CareerPath()
		for p in InitPaths[path][1:(end-1)]
				push!(InitCareerPaths[path].Path, CareerStatus(academicLevel = StLevel[p-1]))
		end
	end
	#println("CreateInitPaths ", InitCareerPaths)
	return InitCareerPaths
end

SetterGetter = Dict{Any,Any}(
                    AcademicLevel => (get_AcademicLevel, set_AcademicLevel),
                    Rank => (get_Rank, set_Rank),
                    Assignment => (get_Assignment, set_Assignment),
                    Affiliation => (get_Affiliation, set_Affiliation),
                    Job => (get_Job, set_Job),
                    SubJob => (get_SubJob, set_SubJob))

function NextLevelPaths!(CareerPaths::Vector{CareerPath}, CurrentLevel::Vector{AbstractLevel}, NextLevel::Vector{AbstractLevel})
    # Getter and Setter for the current and next level
    #currentGet, currentSet = SetterGetter[typeof(CurrentLevel[1])]
    #nextGet, nextSet = SetterGetter[typeof(NextLevel[1])]

    if typeof(NextLevel[1]) == Rank
        Limits = sum(getMinStay(FirstLevel[i]) for i in 1:length(FirstLevel)) + sum(getMaxStay(FirstLevel[i]) for i in 1:length(FirstLevel))
        if Limits == 0
            ConstructRankLevelPathsFreeStLvl(CareerPaths, CurrentLevel, NextLevel)
        else
            ConstructRankLevelPathsLimitedDuration(CareerPaths, CurrentLevel, NextLevel)
        end
    else
        warn("$(typeof(NextLevel[1])) is under Construction.")
    end
end

function ConstructRankLevelPathsFreeStLvl(CareerPaths::Vector{CareerPath}, CurrentLevel::Vector{AbstractLevel}, NextLevel::Vector{AbstractLevel})
    currentGet, currentSet = SetterGetter[typeof(CurrentLevel[1])]
    nextGet, nextSet = SetterGetter[typeof(NextLevel[1])]
    # This is the number of paths that we will exploit
    nbInitPaths = length(CareerPaths)
    for i in 1:nbInitPaths
        PathToExploit = shift!(CareerPaths) # This path is used to generate the possible career paths which will be appended to CareerPaths at the end ***---------
        GeneratedPaths = Vector{CareerPath}()

        #for the first node in the career path we generate possible sub paths
        workinglevel = currentGet(PathToExploit.Path[1])
        for k in 1:length(workinglevel.NextLevel)
            tmppath = CareerPath()
            for l in 1:k
                tmpstatus = CareerStatus( academicLevel = PathToExploit.Path[1].AcademicLevel,
                                          rank = PathToExploit.Path[1].Rank,
                                          assignment = PathToExploit.Path[1].Assignment,
                                          affiliation = PathToExploit.Path[1].Affiliation,
                                          job = PathToExploit.Path[1].Job,
                                          subjob = PathToExploit.Path[1].SubJob)


                nextSet(tmpstatus, NextLevel[findIndex(workinglevel.NextLevel[l], NextLevel)])
                push!(tmppath.Path, tmpstatus)
            end
            push!(GeneratedPaths, tmppath)
        end

        # for each of the remaining nodes in the career path we generate the possible sub paths
        for j in 2:length(PathToExploit.Path)
            workinglevel = currentGet(PathToExploit.Path[j])
            nbPaths = length(GeneratedPaths)
            for p in 1:nbPaths
                workingpath = shift!(GeneratedPaths)

                if nextGet(workingpath.Path[end]).RankCode <= NextLevel[findIndex(workinglevel.NextLevel[1], NextLevel)].RankCode
                    println("StartingIndex = 1")
                    StartingIndex = 1
                elseif nextGet(workingpath.Path[end]).RankCode > NextLevel[findIndex(workinglevel.NextLevel[end], NextLevel)].RankCode
                    continue
                else
                    for indx in 1:length(workinglevel.NextLevel)
                        if nextGet(workingpath.Path[end]).Name == workinglevel.NextLevel[indx]
                            StartingIndex = indx
                            break
                        end
                    end
                    println("StartingIndex = $StartingIndex")
                end
                for k in StartingIndex:length(workinglevel.NextLevel)
                    tmppath = CareerPath(workingpath)
                    for l in StartingIndex:k
                        tmpstatus = CareerStatus( academicLevel = PathToExploit.Path[j].AcademicLevel,
                                                  rank = PathToExploit.Path[j].Rank,
                                                  assignment = PathToExploit.Path[j].Assignment,
                                                  affiliation = PathToExploit.Path[j].Affiliation,
                                                  job = PathToExploit.Path[j].Job,
                                                  subjob = PathToExploit.Path[j].SubJob)


                        nextSet(tmpstatus, NextLevel[findIndex(workinglevel.NextLevel[l], NextLevel)])
                        push!(tmppath.Path, tmpstatus)
                    end
                    push!(GeneratedPaths, tmppath)
                end
            end
        end

        append!(CareerPaths, GeneratedPaths) # Appending generated sub career paths ***---------
    end
end

function ConstructRankLevelPathsLimitedDuration(CareerPaths::Vector{CareerPath}, CurrentLevel::Vector{AbstractLevel}, NextLevel::Vector{AbstractLevel})
    warn("$(typeof(NextLevel[1])) with first level restrictions is under Construction.")


end

function findIndex(name::String, Level::Vector{AbstractLevel})
    for i in 1:length(Level)
        (name == Level[i].Name) && return i
    end
    return -1
end
