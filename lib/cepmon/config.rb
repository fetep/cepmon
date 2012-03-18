class CEPMon
  class Config
    attr_reader :amqp
    attr_reader :statements

    public
    def initialize(cfg_file="cepmon.cfg")
      @amqp = {}
      @statements = {}

      instance_eval(File.read(cfg_file))
    end # def initialize

    private
    def verify_present(params, required)
      required.each do |key|
        return false unless params.member?(key)
      end
      return true
    end # def verify_present

    private
    def statement(params)
      required = [:name, :epl, :metadata]
      if not verify_present(params, required)
        raise "required parameters (#{required.inspect}) missing from statement: #{params.inspect}"
      end

      name = params[:name]
      epl = params[:epl]
      if @statements.member?(name)
        raise "duplicate statement name #{name}"
      end

      @statements[name] = params
    end # def statement

    private
    def statement_name(name)
      i = 1
      while true
        proposed = [name, i].join("_")
        break unless @statements.member?(proposed)
        i += 1
      end
      return proposed
    end

    private
    def amqp_input(params)
      @amqp = params
    end # def amqp_input

    private
    def threshold(name, metric, passed_opts = {})
      opts = {
        :level => :host,  # :cluster or :host
        :threshold => 0,
        :average_over => "5 min",
        :operator => nil,
      }.merge(passed_opts)

      case opts[:operator]
      when '>', '<', '>=', '<=', '='
        true # ok
      else
        raise ArgumentError, "unknown :operator (#{opts[:operator]})"
      end

      metric_safe = metric.tr('.', '_')
      case opts[:level]
      when :cluster
        group_by = "name, cluster"
        select = "name, cluster"
      when :host
        group_by = "name, cluster, host"
        select = "name, host, cluster"
      else
        raise ArgumentError, "unknown :level (#{opts[:level]})"
      end

      md = opts
      md[:name] = metric

      statement :name => name,
                :epl  => "select average as value, cluster, host " +
                         "from metric(name='#{metric}')." +
                         "std:groupwin(#{group_by})." +
                         "win:time(#{opts[:average_over]})." +
                         "stat:uni(value, #{group_by}) " +
                         "group by #{group_by} " +
                         "having average > #{opts[:threshold]} " +
                         "output first every 90 seconds",
                :metadata => md
    end # def threshold
  end # class Config
end # class CEPMon
