#(PA) Movies Part 2, Jing Zou, 1-27-2015
class MovieData
	attr_accessor :training_data
	attr_accessor :test_data
	
	#If there is one argument, u.data is read as the training set and the test set is empty
	#If there are two arguments, .base is read as the training set and .test is read as the test set
	def initialize(*args)
		@training_data = {}
		@test_data = {}
		if args.length == 2 
			training_path = args[0] + "/" + args[1].to_s + ".base"
			test_path = args[0] + "/" + args[1].to_s + ".test"
			load_data(@test_data, test_path)
		else
			training_path = args[0] + "/u.data"
		end
		load_data(@training_data, training_path)
	end

	#It takes a path to the folder containing the movie data (ml-100k) 
	def load_data(data, path)
		file = open(path)		
		file.each do |line|
			one_line = line.chomp.split("\t")
			one_line_movie_info = {one_line[1] => one_line[2]}
			if data[one_line[0]] == nil
   				data[one_line[0]] = one_line_movie_info
   			else
   				data[one_line[0]][one_line[1]] = one_line[2]
   			end
		end
	end

	#It returns the rating that user u gave movie m in the training set, and 0 if user u did not rate movie m
	def rating(u,m)
		rating = @training_data[u.to_s][m.to_s]
		if rating == nil
			return 0
		else 
			return rating
		end
	end

	#Similarity is defined as Pearson correlation-based similarity sim(X,Y)=(E(XY)-E(X)E(Y))/sqrt((E(X^2)-E(X)^2)(E(Y^2)-E(Y)^2))
	#Pearson correlation-based similarity ranges between +1 and −1, where 1 is total positive correlation and −1 is total negative correlation.
	def similarity(user1,user2)
		number_of_movie = 0
		sum_user1 = 0
		sum_user2 = 0
		sum_sq_user1 = 0
		sum_sq_user2 = 0
		product_user1_user2 = 0
		numerator = 0
		denominator = 0
		similarity = 0
		@training_data[user1.to_s].each do |movie, rating1|
			rating2 = training_data[user2.to_s][movie]
			if rating2 != nil
				number_of_movie += 1
				rating1 = rating1.to_i
				rating2 = rating2.to_i
				sum_user1 += rating1
				sum_user2 += rating2
				sum_sq_user1 += rating1*rating1
				sum_sq_user2 += rating2*rating2
				product_user1_user2 += rating1*rating2
			end
		end
		if number_of_movie == 0
			return -1
		end
		numerator = product_user1_user2-sum_user1*sum_user2/number_of_movie.to_f
		denominator = Math.sqrt((sum_sq_user1-sum_user1*sum_user1/number_of_movie.to_f)*(sum_sq_user2-sum_user2*sum_user2/number_of_movie.to_f))
		if denominator == 0
			return -1
		end
		similarity = numerator/denominator
		return similarity
	end

	#It returns a floating point number between 1.0 and 5.0 as an estimate of what user u would rate movie m
	#The returned predicted value = sum of (simularity(u, other users)*rating of m)/sum of simularity(u, other users) [only count the simularity that is larger than 0]
	def predict(u,m)
		sum_of_rating = 0
		sum_of_simularity = 0
		predicted_rating = 0
		@training_data.each do |user, movie|
			if user != u.to_s and movie[m.to_s] != nil
				similarity = similarity(u, user)
				if similarity > 0
					sum_of_rating += similarity * movie[m.to_s].to_f
					sum_of_simularity += similarity
				end
			end
		end
		if sum_of_simularity == 0
			return 3.0
		end
		predicted_rating = sum_of_rating / sum_of_simularity
		return predicted_rating.round(1)
	end

	#It returns the array of movies that user u has watched
	def movies(u)
		return @training_data[u.to_s].keys 
	end

	#It returns the array of users that have seen movie m
	def viewers(m)
		viewers_array = []
		@training_data.each do |user, movie|
			if movie.keys.include?(m.to_s)
				viewers_array.push(user)
			end
		end
		return viewers_array
	end

	#It runs the z.predict method on the first k ratings in the test set and returns a MovieTest object containing the results
	#If k is omitted, all of the tests will be run
	def run_test(*k)
		predict_data = {}
		count = 0
		max = 20000
		if k.length != 0 
			max = k[0].to_i
		end		
		predict_data = {}
		@test_data.each do |user, movie|
			predict_movie = {}
			movie.each do |movie_name, movie_rating|
				if count < max
					movie_test = [movie_rating, predict(user, movie_name).to_s]
					predict_movie[movie_name] = movie_test
					count += 1
				end
			end
			predict_data[user] = predict_movie
		end
		test = MovieTest.new(predict_data)
		return test
	end
end

class MovieTest
	attr_accessor :predict_data

	#MovieTest can be generated by the z.run_test(k)
	#It stores a list of tuples containing the user, movie, rating, and the predicted rating.
	def initialize(predict_data)
		@predict_data = predict_data
	end

	#It returns the average predication error and each error is defined as the absolute value of (predicted rating - actual rating)
	def mean
		sum_of_error = 0
		number = 0
		@predict_data.each do |user, movie|
			movie.each do |movie_name, movie_rating|
				actual = movie_rating[0].to_f
				predicted = movie_rating[1].to_f
				sum_of_error += (predicted - actual).abs
				number += 1
			end
		end
		mean_of_error = sum_of_error / number
		return mean_of_error
	end

	#It returns the standard deviation of the error defined as sqrt of ((sum of (each error - mean of error)^2)/number of records)
	def stddev
		sum_of_stddev = 0
		number = 0
		mean_of_error = mean.to_f
		@predict_data.each do |user, movie|
			movie.each do |movie_name, movie_rating|
				actual = movie_rating[0].to_f
				predicted = movie_rating[1].to_f
				sum_of_stddev += ((predicted - actual).abs - mean_of_error)**2
				number += 1
			end
		end
		stddev_of_error = Math.sqrt(sum_of_stddev / number)
		return stddev_of_error
	end

	#It returns the root mean square error of the prediction defined as sqrt of ((sum of (predicted rating - actual rating)^2)/number of records)
	def rms
		sum_of_rms = 0
		number = 0
		@predict_data.each do |user, movie|
			movie.each do |movie_name, movie_rating|
				actual = movie_rating[0].to_f
				predicted = movie_rating[1].to_f				
				sum_of_rms += (predicted - actual)**2
				number += 1
			end
		end
		rms_error = Math.sqrt(sum_of_rms / number)
		return rms_error
	end

	#It returns an array of the predictions in the form [u,m,r,p]
	def to_a
		predict_array = []
		@predict_data.each do |user, movie|
			movie.each do |movie_name, movie_rating|
				one_record = [user, movie_name, movie_rating[0], movie_rating[1]]
				predict_array.push(one_record)
			end
		end
		return predict_array
	end
end


puts "This is a simple test"
z = MovieData.new('ml-100k',:u1)
puts "The rating that user 1 gave movie 10: "
puts z.rating(1,10)
puts "User 1 would rate movie 17: "
puts z.predict(1,17)
puts "The array of movies that user 1 has watched: "
puts z.movies(1).inspect
puts "The array of users that have seen movie 1: "
puts z.viewers(1).inspect
puts Time.now 
puts "The array of the predictions of first 1000 records: "
puts z.run_test(1000).to_a.inspect
puts Time.now
puts "The average predication error of first 1000 records: "
puts z.run_test(1000).mean
puts "The standard deviation of the error of first 1000 records: "
puts z.run_test(1000).stddev
puts "The root mean square error of first 1000 records: "
puts z.run_test(1000).rms

