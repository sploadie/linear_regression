require 'csv'

def parse_csv(filepath)
	csv_array = CSV.read filepath
	raise 'CSV first line should be "km,price"' if csv_array.shift != ['km','price']
	raise 'CSV file has no data'                if csv_array.count == 0

	data = csv_array.map do |point|
		begin
			raise "invalid point '#{point}' in CSV file" unless point.is_a?(Array) && point.count == 2
			{mileage: Float(point[0]), price: Float(point[1])}
		rescue Exception => e
			puts 'Error: ' + e.message
			next
		end
	end.compact
	data
end
