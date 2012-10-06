
class Genetic

	MIN_FITNESS = -1.0E32

	attr_reader :vec_size,:pop_size,:generation_count
	attr_reader :current_fitness,:best_fitness,:avg_fitness
	attr_accessor :mutation,:crossover,:chunk

	def initialize(nvec,npop)
		@vec_size = nvec
		@upper_bound = Array.new(@vec_size,1.0)
		@lower_bound = Array.new(@vec_size,0.0)
		@creep = Array.new(@vec_size,0.0)
		@child_vector = Array.new(@vec_size,0.0)

		@pop_size = npop
		@pop_vector = Array.new(@pop_size)
		@fitness_vector = Array.new(@pop_size)
		for n in 0...@pop_size
			@pop_vector[n] = Array.new(@vec_size,0.0)
		end

		@chunk = 1
		@mutation = 0.3
		@crossover = 0.2
		randomize(1234)
	end
	
	def randomize(seed)

		srand seed

		for i in 0...@pop_size
			@fitness_vector[i]=MIN_FITNESS
			for k in 0...@vec_size
				@pop_vector[i][k]=rand
			end
		end
		
		@best_fitness=MIN_FITNESS
		@avg_fitness=MIN_FITNESS
		@child_fitness=MIN_FITNESS
		@current_fitness=MIN_FITNESS
		@generation_count=0
	end
	
	def set_param(index,lower_bound,upper_bound,creep)
		@upper_bound[index] = upper_bound
		@lower_bound[index] = lower_bound
		@creep[index] = creep
	end
	
	def receive_vector

		v=Array.new(@vec_size)
		i=rand(@pop_size)
		begin j=rand(@pop_size) end while j==i
		
		tgl = (rand>0.5) ? 1 : -1
		
		for k in 0...@vec_size
		
			if (k%@chunk)==0 then
				if rand < @crossover then
					tgl=-tgl
				end
			end

			@child_vector[k] = (tgl>0) ? @pop_vector[i][k] : @pop_vector[j][k]
			
            if rand < @mutation then
			
                if @creep[k]>0.0 then
                    begin
						v1=2.0*rand-1.0
						v2=2.0*rand-1.0
						rsq=v1*v1+v2*v2
                    end while rsq>=1.0 || rsq==0.0
                    nrnd=v2*Math.sqrt(-2.0*Math.log10(rsq)/rsq)
                    @child_vector[k] += (@creep[k]/(@upper_bound[k]-@lower_bound[k]))*nrnd
                
                else 
                    @child_vector[k] += rand
                    @child_vector[k] -= 1.0 if @child_vector[k]>1.0
                end
            end
			
            if @child_vector[k]>1.0 then
				@child_vector[k]=1.0
            elsif @child_vector[k]<0.0 then
				@child_vector[k]=0.0
			end
			
            v[k]=@lower_bound[k]+(@upper_bound[k]-@lower_bound[k])*@child_vector[k];

		end

		return v

	end
	
	def send_fitness(fitness)

		@child_fitness=fitness
		fworst=1.0E32
		iworst=0
		
		for k in 0...@pop_size
			if @fitness_vector[k]<fworst then
				fworst=@fitness_vector[k]
				iworst=k
			end
		end

		if @child_fitness > fworst then
			vector_ptr=@pop_vector[iworst]
			@pop_vector[iworst]=@child_vector
			@child_vector=vector_ptr
			@fitness_vector[iworst]=@child_fitness;
		end

		if @child_fitness>@best_fitness then
			@best_fitness=@child_fitness
		end
		
		@current_fitness=fitness
		@avg_fitness=0.0
		namf=0		
		for k in 0...@pop_size
			if @fitness_vector[k] > MIN_FITNESS then
				@avg_fitness += @fitness_vector[k]
				namf += 1
			end
		end
		
		@avg_fitness = (namf>0) ? (@avg_fitness/namf) : MIN_FITNESS;
		@generation_count += 1
	end
	
	def most_fit_vector

		ibest=0
		fbest=MIN_FITNESS
		v=Array.new(@vec_size)
		
		for k in 0...@pop_size
			if @fitness_vector[k]>fbest then
				fbest=@fitness_vector[k]
				ibest=k
			end
		end
		
		for k in 0...@vec_size
			v[k]=@lower_bound[k]+(@upper_bound[k]-@lower_bound[k])*@pop_vector[ibest][k]
		end
    
		@current_fitness=fbest

		return v
	end

end

if __FILE__ == $0 then

g = Genetic.new(5,120)
g.mutation = 0.15
g.crossover = 0.10
g.set_param(0, -5.0, 5.0, 3.0 )
g.set_param(1, 0.0, 100.0, 40.0 )
g.set_param(2, -100.0, 100.0, 70.0 )
g.set_param(3, 2.0, 10.0, 4.0 )
g.set_param(4, -10.0, 10.0, 8.0 )

for gen in 1..5000

	v = g.receive_vector

	fitness = ( 5.0*v[0]*(v[0]+2.0) - v[0]*v[0]*v[0]*v[0] - 100.0*Math.sin(3.0*v[1]+1.0) ).to_f.ceil / (10.5 + (v[2]+v[3]/(v[1]+0.001)-v[3]*v[4]*v[4]*Math.cos(v[2])).floor)
					 
	g.send_fitness(fitness)

	printf("%6d %12.2f %12.2f %7.2f %7.2f %7.2f %7.2f %7.2f\n",
		   gen,fitness,g.avg_fitness,v[0],v[1],v[2],v[3],v[4])

	$stdout.flush
	
end

puts "most fit = #{g.most_fit_vector.join(" ")}"

end