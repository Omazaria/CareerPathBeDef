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
		#println(InitPaths)
		for path in InitPaths
			push!(CareerPaths, path)
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
		InitCareerPaths[path].ActivitedLevels = 0
		for p in InitPaths[path][1:(end-1)]
				#println(StLevel[p-1])
				push!(InitCareerPaths[path].Path, CareerStatus(academicLevel = StLevel[p-1]))
		end
	end
	#println("CreateInitPaths ", InitCareerPaths)
	return InitCareerPaths
end
