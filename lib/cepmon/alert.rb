class CEPMon
  class Alert
    attr_reader :started
    attr_reader :expires

    public
    def initialize(data)
      @data = {}
      @started = data[:timestamp]
      update(data)
    end # def initialize

    public
    def update(data)
      data[:value] = sprintf "%.02f", data[:value].to_f

      @data.merge!(data)
      @expires = data[:timestamp] + 120
    end

    public
    def method_missing(method)
      @data[method]
    end

    public
    def expired?
      Time.now.to_i > @expires
    end # def expired?

    public
    def reason
      "#{@data[:value]} #{@data[:operator]} #{@data[:threshold]} " \
      "#{@data[:units]} for #{@data[:average_over]}"
    end

    public
    def to_s
      "#{Time.at(@data[:timestamp])} [ALERT] cluster=#{@data[:cluster]}/host=#{@data[:host]} " +
      "| name=#{@data[:name]} | value=#{@data[:value]} | statement=#{@data[:statement]}"
    end # def to_s

    public
    def to_json(*args)
      @data.merge({
        :started => @started,
        :expires => @expires,
        :expired => expired?,
        :reason => reason,
      }).to_json(*args)
    end # def to_json
  end # class Alert
end # class CEPMon
