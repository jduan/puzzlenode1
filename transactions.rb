require "bigdecimal"

class Transactions
    def initialize(io, rate_converter)
        @io = io
        @rate_converter = rate_converter
        parse_transactions(io)
    end

    # convert and round each sale to USD
    def total_sale_of1(item)
        total = BigDecimal("0")
        @items[item].each do |currency, values|
            rate = @rate_converter.to_USD(currency)
            subtotal = values.inject(BigDecimal.new("0.0")) do |subtotal, value|
                subtotal = subtotal + bankers_rounding(value * rate)
                puts "convert #{value} #{currency} to #{value*rate} USD and round to #{bankers_rounding(value*rate)} USD"
                subtotal
            end

            total += subtotal
        end

        puts "number of sales for item #{item} is #{number_of_transactions_for_item(item)}"
        total
    end

    # convert each sale to USD and round the subtotal
    def total_sale_of2(item)
        total = 0
        @items[item].each do |currency, values|
            rate = @rate_converter.to_USD(currency)
            subtotal = values.inject(0.0) do |subtotal, value|
                subtotal += value * rate
                puts "convert #{value} #{currency} to #{bankers_rounding(value*rate)} USD"
                subtotal
            end

            puts "round subtotal of #{subtotal} to #{bankers_rounding(subtotal)}"
            total += bankers_rounding(subtotal)
        end

        total
    end

    # convert each sale to USD, calculate the subtotal, round the
    # total at the very end
    def total_sale_of3(item)
        total = 0
        @items[item].each do |currency, values|
            rate = @rate_converter.to_USD(currency)
            subtotal = values.inject(0.0) do |subtotal, value|
                subtotal += value * rate
                puts "subtotal for currency #{currency} so far: #{subtotal}"
                subtotal
            end

            total += subtotal
        end

        bankers_rounding(total)
    end

    # f is actually big decimal
    def bankers_rounding(f)
        new_f = (f * 1000).to_i / 10.0
        i = new_f.to_i
        reminder = new_f - i
        if reminder == 0.5
            i = i.odd? ? i+1 : i
        elsif reminder > 0.5
            i = i + 1
        else
            i = i
        end
        i / 100.0
    end

        
    private
    def parse_transactions(io)
        header = io.gets.chomp
        unless header == "store,sku,amount"
            raise "header line isn't as expected"
        end

        items = {}
        line_num = 0
        while line = io.gets
            line_num += 1
            line.chomp!
            place, item, price = line.split(",")
            item.strip!
            price.strip!
            value, currency = price.split
            value = BigDecimal.new(value)
            items[item] ||= {}
            if items[item][currency]
                items[item][currency] << value
            else
                items[item][currency] = []
                items[item][currency] << value
            end
        end

        puts "total number of sales: #{line_num}"
        items

        @items = items
    end

    def number_of_transactions
        total = @items.reduce(0) do |total, currency_values|
            subtotal = currency_values[1].reduce(0) do |subtotal, cv|
                subtotal += cv[1].size
            end

            total += subtotal
        end

        puts "total records: #{total}"
        total
    end

    def number_of_transactions_for_item(item)
        @items[item].reduce(0) do |total, currency_value|
            total += currency_value[1].size
        end
    end
end
