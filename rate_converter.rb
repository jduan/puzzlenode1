require "rubygems"
require "bigdecimal"
require "nokogiri"
require "set"

class RateConverter
    attr_reader :conversions, :all_conversions

    def initialize(xml)
        @conversions = parse_xml(xml)
        @all_conversions = calculate_usd_conversions(@conversions)
    end

    def method_missing(method, *args, &block)
        if method.to_s =~ /to_([A-Z]{3})$/
            currency = $1
            @all_conversions["USD"][currency]
        else
            super
        end
    end

    def to_USD(currency)
        if currency == "USD"
            BigDecimal("1.0")
        else
            @all_conversions["USD"][currency]
        end
    end

    def to_s
        str = ""
        @all_conversions["USD"].keys.each do |currency|
            rate = @all_conversions["USD"][currency].to_f
            str << "#{currency} -> USD : #{rate}\n"
        end

        str
    end

    private
    def parse_xml(xml)
        doc = Nokogiri::XML(xml)
        conversions ||= {}

        doc.xpath("/rates/rate").each do |rate|
            from = rate.xpath("from")[0].content
            to = rate.xpath("to")[0].content
            rate = BigDecimal.new(rate.xpath("conversion")[0].content)
            add_conversion(conversions, from, to, rate)
        end

        conversions
        # add_supplements(conversions)
    end

    def add_supplements(conversions)
        conversions.each do |from, to_rate|
            to_rate.each do |to, rate|
                unless conversions[to][from]
                    conversions[to][from] = BigDecimal.new("1.0") / rate
                end
            end
        end
        conversions
    end

    def add_conversion(conversions, from, to, rate)
        from_rate = conversions[to] || {}
        if from_rate[from].nil?
            from_rate[from] = rate
        end
        conversions[to] = from_rate
    end

    def calculate_usd_conversions(conversions)
        all_conversions = {}
        all_conversions["USD"] = conversions["USD"].clone
        ring = Set.new(conversions["USD"].keys)
        visited = Set.new(["USD"])
        visited.merge ring
        while ring.size > 0
            new_ring = Set.new
            ring.each do |currency|
                conversions[currency].each do |from, rate|
                    unless visited.include? from
                        all_conversions["USD"][from] = all_conversions["USD"][currency] * rate
                        new_ring << from
                        visited << from
                    end
                end
            end
            ring = new_ring
        end

        all_conversions
    end

    def adjust_precision(f)
        (f * 10000).to_i / 10000.0
    end
end
