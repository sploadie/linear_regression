require_relative 'color'

def predict_price(theta, mileage)
	price = theta[0] + (theta[1] * mileage)
end

def predict_price_with_file(mileage)
	begin
		file_contents = File.read 'theta.data'
		theta = Marshal.load file_contents
		puts "Loaded theta: #{theta.inspect}".green
	rescue
		theta = [0.0, 0.0]
		puts "Warning: theta.data could not be loaded, resorting to default theta #{theta.inspect}".red
	end
	# Calculate price
	predict_price(theta, mileage)
end
