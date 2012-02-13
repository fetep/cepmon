class CEPMon
  class Alert
    attr_reader :host
    attr_reader :cluster
    attr_reader :name
    attr_reader :value
    attr_reader :statement
    attr_reader :timestamp
    attr_reader :expires

    public
    def initialize(opts = {})
      $stderr.puts "in #{self.class}, initialize opts = #{opts.inspect}"
      @host = opts[:host]
      @cluster = opts[:cluster]
      @name = opts[:name]
      @value = opts[:value]
      @statement = opts[:statement]
      @timestamp = opts[:timestamp]
      @expires = @timestamp + 120
    end # def initialize

    public
    def expired?
      Time.now.to_f > @expires
    end # def expired?

    public
    def to_s
        "#{Time.at(@timestamp)} [ALERT] cluster=#{@cluster}/host=#{@host} " +
        "| name=#{@name} | value=#{@value} | statement=#{@statement}"
    end # def to_s
  end # class Alert
end # class CEPMon
