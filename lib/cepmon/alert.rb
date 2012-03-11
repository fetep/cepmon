class CEPMon
  class Alert
    public
    def initialize(opts = {})
      $stderr.puts "in #{self.class}, initialize opts = #{opts.inspect}"
      @vars = opts
      @vars[:expires] = @vars[:timestamp] + 120
      @vars[:reason] = "#{@vars[:value]} #{@vars[:operator]} #{@vars[:threshold]} #{@vars[:units]} for #{@vars[:duration]}"
    end # def initialize

    public
    def method_missing(method)
      @vars[method]
    end

    public
    def expired?
      Time.now.to_f > @vars[:expires]
    end # def expired?

    public
    def to_s
      "#{Time.at(@vars[:timestamp])} [ALERT] cluster=#{@vars[:cluster]}/host=#]{@vars[:host} " +
      "| name=#{@vars[:name]} | value=#{@vars[:value]} | statement=#{@vars[:statement]}"
    end # def to_s
  end # class Alert
end # class CEPMon
