##### Batch Processing literature example #####

using Printf

include("bp_primary_structs.jl")
include("bp_primary_functions.jl")
include("ga_alg_rates.jl")
include("bp_primary_fitness.jl")

#Seed
Random.seed!(Dates.value(convert(Dates.Millisecond, Dates.now())))

function main_func()

	##### TESTS #####

	#### CONFIG PARAMETERS ####

	no_units = 4
	no_storages = 9
	no_instructions = 5
	products = [8, 9]
	prices = [10.0, 10.0]

	# Setup tasks 
	tasks = []

	feeders = Dict{Int, Float64}()
	receivers = Dict{Int, Float64}()
	feeders[1] = 1.0
	receivers[4] = 1.0
	push!(tasks, RTask("Heating", feeders, receivers))

	feeders = Dict{Int, Float64}()
	receivers = Dict{Int, Float64}()
	feeders[2] = 0.5
	feeders[3] = 0.5
	receivers[6] = 1.0
	push!(tasks, RTask("reaction 1", feeders, receivers))

	feeders = Dict{Int, Float64}()
	receivers = Dict{Int, Float64}()
	feeders[4] = 0.4
	feeders[6] = 0.6
	receivers[8] = 0.4
	receivers[5] = 0.6
	push!(tasks, RTask("reaction 2", feeders, receivers))

	feeders = Dict{Int, Float64}()
	receivers = Dict{Int, Float64}()
	feeders[3] = 0.2
	feeders[5] = 0.8
	receivers[7] = 1.0
	push!(tasks, RTask("reaction 3", feeders, receivers))

	feeders = Dict{Int, Float64}()
	receivers = Dict{Int, Float64}()
	feeders[7] = 1.0
	receivers[5] = 0.1
	receivers[9] = 0.9
	push!(tasks, RTask("still", feeders, receivers))


	##### Reactions #####
	#=

	Mixing		: 1
	Reaction 1	: 2
	Reaction 2	: 3
	Reaction 3	: 4
	Seperation	: 5
	
	=#
	#####################


	#Setup units
	units = []

	unit_tasks = Dict{Int, Coefs}()
	unit_tasks[1] = Coefs(2/3, 1/150)

	unit_1 = Unit("Heater", 100.0, unit_tasks)
	push!(units, unit_1)

	unit_tasks = Dict{Int, Coefs}()
	unit_tasks[2] = Coefs(4/3, 2/75)
	unit_tasks[3] = Coefs(4/3, 2/75)
	unit_tasks[4] = Coefs(2/3, 1/75)

	unit_2 = Unit("Reactor 1", 50.0, unit_tasks)
	push!(units, unit_2)

	unit_tasks = Dict{Int, Coefs}()
	unit_tasks[2] = Coefs(4/3, 1/60)
	unit_tasks[3] = Coefs(4/3, 1/60)
	unit_tasks[4] = Coefs(2/3, 1/120)

	unit_3 = Unit("Reactor 2", 80.0, unit_tasks)
	push!(units, unit_3)

	unit_tasks = Dict{Int, Coefs}()
	unit_tasks[5] = Coefs(4/3, 1/150)

	unit_4 = Unit("Still", 200.0, unit_tasks)
	push!(units, unit_4)

	#Setup storages
	storage_capacity = [Inf, Inf, Inf, 100.0, 200.0, 150.0, 200.0, Inf, Inf]

	#Initial volumes
	initial_volumes = [Inf, Inf, Inf, 0, 0, 0, 0, 0, 0]

	config = BPS_Config(no_units, no_storages, no_instructions, products, prices, units, tasks, storage_capacity, initial_volumes)

	no_params = 9
	no_tests = 5

	### RUN TESTS ###

	@printf "TESTS: %d\n" no_tests
	newline()

	#Grid searches 
	thetas = 0.1:0.1:1.0
	mutations = 0.1:0.1:1.0
	deltas = 0:0.125:1.0

	# Metaheuristic parameters 


	#Keep track of best combination of metaheuristic parameters
	best_theta = 0
	best_mutation = 0
	best_delta = 0

	combinations = size(thetas)[1] * size(mutations)[1] * size(deltas)[1]
	comb = 0

	logfile = open("default.txt", "a")
	
	for p in 1:no_params

		#### METAHEURISTIC PARAMETERS ####
		parameters_filename = "parameters_$(p).txt"
		params_file = read_parameters(parameters_filename)

		##### GENERATE CANDIDATES #####
		cands = generate_pool(config, params_file)

		overall_top_fitness = 0

		for t in thetas
		for m in mutations
		for d in deltas

		params = Params(params_file.horizon, params_file.no_events, params_file.population, params_file.generations, t, m, d)
		
		#Temporary instructions / duration arrays
		#instr_arr::Array{Int, 2} = zeros(config.no_units, params.no_events)	
		#durat_arr::Array{Float64} = zeros(params.no_events)

		#@printf "Horizon: %.1f Events: %d Generations: %d Population: %d \t--- " params.horizon params.no_events params.generations params.population

		time_sum = 0.0
		top_fitness = 0.0

		for test in 1:no_tests

			#### Test No. ####
			#write(logfile, "Test: $(test)\n")

			##### EVOLVE CHROMOSOMES #####
			#seconds = @elapsed best_index, best_fitness = evolve_chromosomes(logfile, config, cands, params, false)
			#time_sum += seconds

			best_index, best_fitness = evolve_chromosomes(logfile, config, cands, params, false)

			if best_fitness > top_fitness
				top_fitness = best_fitness
				#instr_arr = copy(cands[best_index].instructions)
				#durat_arr = copy(cands[best_index].durations)
			end

		end

		if top_fitness > overall_top_fitness
			overall_top_fitness = top_fitness
			best_theta = t
			best_mutation = m
			best_delta = d
		end

		#@printf "Total Time: %.6f Optimal Fitness: %.6f " time_sum top_fitness
		#print(instr_arr)
		#print(durat_arr)
		#newline()

		#close(logfile)
	
		comb += 1
	@printf "For P: %d [%d / %d] Theta: %.2f Mutation: %.2f Delta: %.3f Best_t: %.2f Best_m: %.2f Best_d: %.3f \n" p comb combinations t m d best_theta best_mutation best_delta

	end #thetas 
	end #mutations
	end #Deltas 

	end #P for end


end

main_func()
