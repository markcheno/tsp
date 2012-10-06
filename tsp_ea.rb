require './tradesim'
require './genetic'

class EA < System

	def setup(params)	
		@fast      = params[0]
		@slow      = params[1]
		@atrmult   = params[2]
		@heat      = params[3]
		@atrperiod = params[4]
		@roundlot  = 250
		@startbar  = 25
		@skidfrac  = 0.5
		@maxdd     = 0.5
		@startcash = 1000000
		@emafast   = lag(@close,@fast)
		@emaslow   = lag(@close,@slow)
		@atr       = atr(@quote,@atrperiod)
	end

	def rules(bar)

		# money management
		risk = @atr[bar] * @atrmult
		@units = @balance[@bar] * @heat / risk

		# buy rule
		buyopen  if @emafast[bar] > @emaslow[bar]

		# sell rule
		sellopen if @emafast[bar] < @emaslow[bar]

	end

	def closeposition
		fillprice = @close[-1]
		exittrade(@date[-1],fillprice)
	end

	def output
		#printf("fast: %d slow: %d bliss: %6.3f icagr: %6.3f dd: %6.3f\n",@fast,@slow,bliss,icagr,drawdown)
		#metricslog
		#equitylog
		#tradelog
	end

	def metricslog
		for n in 0...@barcount
			printf("%s Eq=%10.2f OHLC:[ %6.2f %6.2f %6.2f %6.2f ] slow=%7.3f fast=%7.3f Atr=%6.3f\n",
			   @date[n].strftime('%y-%m-%d-%-%a'),@equity[n],
			   @open[n],@high[n],@low[n],@close[n],
			   @emaslow[n],@emafast[n],@atr20[n])
		end
	end

end

# Build and run simulator
sim = Simulator.new
sim.system = EA.new(TspQuote.new("sp.csv"))

# Create genetic optimizer
opt = Genetic.new(5,120)
opt.mutation = 0.15
opt.crossover = 0.10
opt.set_param(0, 15.0, 300.0, 80.0 )	# fast lag
opt.set_param(1, 30.0, 600.0, 80.0 )	# slow lag
opt.set_param(2,  1.0,  10.0, 20.0 )	# atr multiplier
opt.set_param(3,  0.01,  0.5, 20.0 )	# heat
opt.set_param(4,  2.0,  20.0, 20.0 )	# atr period

# Optimize
for gen in 1..2500

	v = opt.receive_vector

	fitness = sim.simulate(v[0].to_i,v[1].to_i,v[2].to_i,v[3],v[4].to_i)

	opt.send_fitness(fitness)

	printf("%6d %12.2f %12.2f %7.2f %7.2f %7.2f %7.2f %7.2f\n",
		   gen,fitness,opt.avg_fitness,v[0],v[1],v[2],v[3],v[4])

	$stdout.flush
	
end

puts "most fit = #{opt.most_fit_vector.join(" ")}"
