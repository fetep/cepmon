class CEPMon
  class Config
    attr_reader :amqp
    attr_reader :host
    attr_reader :port
    attr_reader :statements

    public
    def initialize(cfg_file="cepmon.cfg")
      @amqp = {}
      @statements = {}
      @host = "0.0.0.0"
      @port = 8989

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
                         "having average " +
                         "#{opts[:operator]} #{opts[:threshold]} " +
                         "output first every 90 seconds",
                :metadata => md
    end # def threshold

    private
    def threshold_counter(name, metric, passed_opts = {})
      opts = {
        :level => :host,  # :cluster or :host
        :average_over => "5 min",
        :threshold => 0,
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

    statement :name => "01_metric_delta_stream-#{metric}",
              :epl => "insert into
                        metric_delta_stream
                      select
                        (value - prev(value)) as value, cluster, host, name
                      from
                        metric(name='#{metric}').std:groupwin(#{group_by}).win:length(2)",
              :metadata => { :name => "01_metric_delta_stream-#{metric}" },
              :listen => false

    statement :name => name,
              :epl  => "select average as value, cluster, host from metric_delta_stream(name='#{metric}').std:groupwin(#{group_by}).win:time(#{opts[:average_over]}).stat:uni(value, #{group_by}) group by #{group_by} having average #{opts[:operator]} #{opts[:threshold]} output first every 90 seconds",
              :metadata => md
  end # def threshold_counter

  # This should work, but it doesn't....
  #private
  #def missing_metric(name, metric, passed_opts = {})
  #  opts = {
  #    :level => :host,  # :cluster or :host
  #    :out_to_lunch => "5 min",
  #  }.merge(passed_opts)
  #
  #  metric_safe = metric.tr('.', '_')
  #  case opts[:level]
  #  when :cluster
  #    group_by = "name, cluster"
  #    select = "name, cluster"
  #  when :host
  #    group_by = "name, cluster, host"
  #    select = "name, host, cluster"
  #  else
  #    raise ArgumentError, "unknown :level (#{opts[:level]})"
  #  end
  #
  #  md = opts
  #  md[:name] = metric
  #
  #  statement :name => name,
  #            :epl => "select * from metric(name='#{metric}').std:groupwin(#{group_by}).win:time(#{opts[:out_to_lunch]}).std:lastevent().std:size() where size = 0 group by #{group_by}",
  #            :metadata => md
  #end # def missing_metric

  private
  def listen(host, port = 8989)
    @host = host
    @port = port.to_i
  end

  end # class Config
end # class CEPMon
