require_relative 'predict'
require_relative 'color'

class ThetaDiverged < Exception
end

def calc_mean(data, data_count)
	mean = {price: 0.0, mileage: 0.0}
	data.each do |point|
		mean[:price]   += point[:price]
		mean[:mileage] += point[:mileage]
	end
	mean[:price]   = mean[:price]   / data_count
	mean[:mileage] = mean[:mileage] / data_count
	mean
end

def calc_deviation_scores(mean, data)
	mean_price   = mean[:price]
	mean_mileage = mean[:mileage]
	data.map { |point| {price: (point[:price] - mean_price), mileage: (point[:mileage] - mean_mileage)} }
end

def calc_variance(deviation_scores, data_count)
	variance = {price: 0.0, mileage: 0.0}
	deviation_scores.each do |score|
		variance[:price]   += score[:price] ** 2
		variance[:mileage] += score[:mileage] ** 2
	end
	variance[:price]   = variance[:price]   / data_count
	variance[:mileage] = variance[:mileage] / data_count
	variance
end

def calc_standard_deviation(variance)
	{price: Math.sqrt(variance[:price]), mileage: Math.sqrt(variance[:mileage])}
end

def calc_pearsons_correlation(deviation_scores)
	e_xy = 0.0
	e_xx = 0.0
	e_yy = 0.0
	deviation_scores.each do |score|
		e_xy += score[:mileage] *  score[:price]
		e_xx += score[:mileage] ** 2
		e_yy += score[:price]   ** 2
	end
	pearsons_correlation = e_xy / Math.sqrt(e_xx * e_yy)
end

def calc_true_slope(pearsons_correlation, standard_deviation)
	slope = pearsons_correlation * (standard_deviation[:price] / standard_deviation[:mileage])
end

def calc_true_y_intercept(mean, true_slope)
	y_intercept = mean[:price] - (true_slope * mean[:mileage])
end

def calc_standardized_data(data, data_count)
	mean = calc_mean(data, data_count)
	deviation_scores = calc_deviation_scores(mean, data)
	standard_deviation = calc_standard_deviation(calc_variance(deviation_scores, data_count))
	deviation_scores.map do |score|
		{price: (score[:price] / standard_deviation[:price]), mileage: (score[:mileage] / standard_deviation[:mileage])}
	end
end

def calc_data_max_min(data)
	max = {price: data[0][:price], mileage: data[0][:mileage]}
	min = {price: data[0][:price], mileage: data[0][:mileage]}
	data.each do |point|
		max[:price]   = point[:price]   if max[:price]   < point[:price]
		min[:price]   = point[:price]   if min[:price]   > point[:price]
		max[:mileage] = point[:mileage] if max[:mileage] < point[:mileage]
		min[:mileage] = point[:mileage] if min[:mileage] > point[:mileage]
	end
	return max, min
end

def calc_scaled_value(val, max, min)
	(val - min) / (max - min)
end

def calc_scaled_data(data)
	max, min = calc_data_max_min(data)
	data.map do |point|
		{
			price:   calc_scaled_value(point[:price],   max[:price],   min[:price]),
			mileage: calc_scaled_value(point[:mileage], max[:mileage], min[:mileage])
		}
	end
end

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#

def save_theta(theta)
	begin
		File.write 'theta.data', Marshal.dump(theta)
	rescue
		raise 'failed to save theta'
	end
	puts ''
	puts 'Saved theta.'.green
end

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#

def solve_linear_regression(data)

	puts 'Data:'.yellow
	puts 'km,price'
	data.each { |point| puts "#{point[:mileage]},#{point[:price]}" }

	data_count = data.count
	puts 'Data Count: '.yellow + data_count.to_s

	mean = calc_mean(data, data_count)
	puts 'Mean:'.yellow
	puts "--> Price:   #{mean[:price]}"
	puts "--> Mileage: #{mean[:mileage]}"

	deviation_scores = calc_deviation_scores(mean, data)

	variance = calc_variance(deviation_scores, data_count)
	puts 'Variance:'.yellow
	puts "--> Price:   #{variance[:price]}"
	puts "--> Mileage: #{variance[:mileage]}"

	standard_deviation = calc_standard_deviation(variance)
	puts 'Standard Deviation:'.yellow
	puts "--> Price:   #{standard_deviation[:price]}"
	puts "--> Mileage: #{standard_deviation[:mileage]}"

	pearsons_correlation = calc_pearsons_correlation(deviation_scores)
	puts 'Pearson\'s Correlation: '.yellow + pearsons_correlation.to_s

	slope = calc_true_slope(pearsons_correlation, standard_deviation)
	puts 'Slope: '.yellow + slope.to_s

	y_intercept = calc_true_y_intercept(mean, slope)
	puts 'Y Intercept: '.yellow + y_intercept.to_s
	puts ''
	puts "estimatedPrice(mileage) = #{slope}(mileage) + #{y_intercept}".green

	# Save theta
	save_theta([y_intercept, slope])
end

def solve_with_standardized_data(data)
	solve_linear_regression calc_standardized_data(data, data.count)
end

def solve_with_scaled_data(data)
	solve_linear_regression calc_scaled_data(data)
end

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#

def calc_estimated_price(slope, y_intercept, mileage)
	estimated_price = (slope * mileage) + y_intercept
end

# Partial differential of
# E(m,b) = 1/N * Sigma((mX + b) - Y)^2
# ->
# dE/dm = 2/N * Sigma(((mX + b) - Y) * X)
# dE/db = 2/N * Sigma ((mX + b) - Y)
def calc_mean_partial_error(slope, y_intercept, data, data_count)
	slope_error       = 0.0
	y_intercept_error = 0.0
	data.each do |point|
		slope_error       += (calc_estimated_price(slope, y_intercept, point[:mileage]) - point[:price]) * point[:mileage]
		y_intercept_error +=  calc_estimated_price(slope, y_intercept, point[:mileage]) - point[:price]
	end
	return (slope_error / data_count), (y_intercept_error / data_count)
end

def teach(data)
	data_count = data.count

	# Fresh new values
	slope = 0.0
	# y_intercept = 0.0
	# slope = -0.8561394207905021
	# y_intercept = 2.8550912974585844e-16
	mean = calc_mean(data, data_count)
	y_intercept = mean[:price]

	# Standard learning rate for now
	learning_rate = 1.0
	# learning_rate_calibrated = false
	# slope_learning_rate = 0.1
	# y_intercept_learning_rate = 1000

	# Calculate theta
	iteration = 0
	done_training = false
	theta_history = []
	prev_slope_error, prev_y_intercept_error = calc_mean_partial_error(slope, y_intercept, data, data_count)
	puts "Iteration 0".yellow
	puts "Slope: #{slope} \t Y Intercept: #{y_intercept}"

	begin
		while $stdin.gets.chomp != 'q' do
			10.times do
				puts "Iteration #{iteration += 1}".yellow
				theta_history << [y_intercept, ',', slope]
				slope_error, y_intercept_error = calc_mean_partial_error(slope, y_intercept, data, data_count)
				puts "Slope Error: #{slope_error} \t Y Intercept Error: #{y_intercept_error}"
				raise ThetaDiverged if slope_error.infinite? || y_intercept_error.infinite?
				if slope_error.abs < prev_slope_error.abs && y_intercept_error.abs < prev_y_intercept_error.abs
					puts "Slope Error #{'decreased'.green} \t Y Intercept Error #{'decreased'.green}"
					learning_rate *= 1.05
					# learning_rate_calibrated = true
				elsif slope_error.abs == prev_slope_error.abs && y_intercept_error.abs == prev_y_intercept_error.abs
					if iteration != 1
						puts "\nSlope and Y Intercept converged!".green
						done_training = true
						break
					end
					# puts "Slope and Y Intercept Error did not change".red if iteration != 1
					# learning_rate *= 0.95
				else
					puts "Slope Error #{slope_error.abs < prev_slope_error.abs ? 'decreased'.green : 'increased'.red} \t Y Intercept Error #{y_intercept_error.abs < prev_y_intercept_error.abs ? 'decreased'.green : 'increased'.red}"
					learning_rate *= 0.90
					# learning_rate *= 0.50
					# learning_rate_calibrated = true if slope_error.abs < prev_slope_error.abs
					# if learning_rate_calibrated == false
					# 	slope_error, y_intercept_error = prev_slope_error.abs * (slope_error / slope_error.abs), prev_y_intercept_error.abs * (y_intercept_error / y_intercept_error.abs)
					# 	puts "Slope Error: #{slope_error} \t Y Intercept Error: #{y_intercept_error}".red
					# end
				end
				# learning_rate = 0.0001 if learning_rate < 0.00000001
				# learning_rate *= 0.99
				puts "Learning Rate: #{learning_rate}"
				# if slope_error.abs < prev_slope_error.abs
				# 	slope_learning_rate *= 1.05
				# else
				# 	slope_learning_rate *= 0.50
				# end
				# if y_intercept_error.abs < prev_y_intercept_error.abs
				# 	y_intercept_learning_rate *= 2.00
				# else
				# 	y_intercept_learning_rate *= 0.10
				# end
				# puts "Slope Learning Rate: #{slope_learning_rate} \t Y Intercept Learning Rate: #{y_intercept_learning_rate}"
				puts "Slope Diff: #{learning_rate * slope_error * -1.0} \t Y Intercept Diff: #{learning_rate * y_intercept_error * -1.0}"
				slope       -= learning_rate * slope_error
				y_intercept -= learning_rate * y_intercept_error
				# slope       -= slope_learning_rate       * (slope_error       / slope_error.abs)
				# y_intercept -= y_intercept_learning_rate * (y_intercept_error / y_intercept_error.abs)
				prev_slope_error, prev_y_intercept_error = slope_error, y_intercept_error
				# # FIXME
				# y_intercept = mean[:price] - (slope * mean[:mileage])
				# # FIXME
				puts "Slope: #{slope} \t Y Intercept: #{y_intercept}"
			end
			break if done_training
		end

		puts ''
		puts 'Slope:       '.yellow + slope.to_s
		puts 'Y Intercept: '.yellow + y_intercept.to_s

		# Write new theta
		save_theta([y_intercept, slope])

	rescue ThetaDiverged
		puts 'Error: slope and y-intercept diverged'.red
	end

	puts ''
	begin
		$stdin.flush
		print 'Output theta history? (y/n) : '
		input = $stdin.gets.chomp
	end while input != 'y' && input != 'n'

	if input == 'y'
		puts 'y-intercept,slope'
		puts theta_history.map(&:join).join("\n")
	end
end

def teach_with_scaled(data)
	teach calc_scaled_data(data)
end

def teach_with_standardized(data)
	teach calc_standardized_data(data, data.count)
end
