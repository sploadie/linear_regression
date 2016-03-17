require_relative 'predict'
require_relative 'color'

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

def calc_scaled_data(data)
	max, min = calc_data_max_min(data)
	max_minus_min = {price: (max[:price] - min[:price]), mileage: (max[:mileage] - min[:mileage])}
	data.map do |point|
		{price: ((point[:price] - min[:price]) / max_minus_min[:price]), mileage: ((point[:mileage] - min[:mileage]) / max_minus_min[:mileage])}
	end
end

def solve_linear_regression(data)

	# FIXME
	puts 'FIXME: SCALING DATA'
	old_data = data
	data = calc_scaled_data(data)
	# FIXME

	puts 'Data:'.yellow
	data.each { |point| puts "--> Mileage: #{point[:mileage]} \t Price: #{point[:price]}" }

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

	# FIXME
	max, min = calc_data_max_min(old_data)
	
	slope = slope
	puts ''
	puts 'Unscaled...?'
	puts "estimatedPrice(mileage) = #{slope}(mileage) + #{y_intercept}".green
	# FIXME

	# Save theta
	begin
		File.write 'theta.data', Marshal.dump([y_intercept, slope])
	rescue
		raise 'failed to save theta'
	end
end












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
		y_intercept_error +=  calc_estimated_price(slope, y_intercept, point[:mileage]) - point[:price]
		slope_error       += (calc_estimated_price(slope, y_intercept, point[:mileage]) - point[:price]) * point[:mileage]
	end
	return (slope_error / data_count), (y_intercept_error / data_count)
end

def teach(data)
	# Fresh new values
	slope = 0.0
	y_intercept = 0.0

	# Standard learning rate for now
	learning_rate = 1.0

	# Get static variables
	data_count = data.count

	# Standardize data
	std_data = calc_standardized_data(data, data_count)
	# p std_data

	# Calculate theta
	iteration = 0
	puts "Iteration 0".yellow
	puts "Slope: #{slope} \t Y Intercept: #{y_intercept}"

	while $stdin.gets.chomp != 'q' do
		10.times do
			puts "Iteration #{iteration += 1}".yellow
			slope_error, y_intercept_error = calc_mean_partial_error(slope, y_intercept, std_data, data_count)
			puts "Slope Error: #{slope_error} \t Y Intercept Error: #{y_intercept_error}"
			slope -= learning_rate * slope_error
			y_intercept -= learning_rate * y_intercept_error
			puts "Slope: #{slope} \t Y Intercept: #{y_intercept}"
		end
	end

	# Write new theta
	begin
		File.write 'theta.data', Marshal.dump([y_intercept, slope])
	rescue
		raise 'failed to save theta'
	end
end