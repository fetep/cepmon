require "cepmon/libs"

java_import com.espertech.esper.client.Configuration
java_import com.espertech.esper.client.EPServiceProviderManager
java_import com.espertech.esper.client.time.TimerControlEvent
java_import java.util.HashMap


class CEPMon
  class Engine
    attr_reader :engine
    attr_reader :admin
    attr_reader :runtime
    attr_accessor :time

    public
    def initialize
      @ep_config = com.espertech.esper.client.Configuration.new
      add_type_maps

      # tp(pct, value) function to get top pct% percentile
      #@ep_config.addPlugInAggregationFunction("tp", "com.ning.metrics.meteo.esper.TPAggregator")

      #@ep_config.addPlugInView("cepmon", "predict", "com.ning.metrics.meteo.esper.HoltWintersViewFactory")

      @engine = EPServiceProviderManager.getDefaultProvider(@ep_config)
      @admin = @engine.getEPAdministrator
      @runtime = @engine.getEPRuntime

      # put the engine in external clock mode
      @runtime.send_event(
        TimerControlEvent.new(TimerControlEvent::ClockType::CLOCK_EXTERNAL)
      )
      @time = nil

      # keep track of statement metadata
      @statement_md = {}

      @start = Time.now.to_i
    end # def initialize

    public
    def add_statements(config, event_listener)
      config.statements.sort.each do |name, opts|
        statement = @admin.createEPL(opts[:epl], name.to_s)
        statement.addListener(event_listener) unless opts[:listen] == false
        @statement_md[name] = opts[:metadata] ? opts[:metadata] : {}
      end
    end # def add_statements

    public
    def statements
      res = []
      @statement_md.each do |name, md|
        statement = @admin.getStatement(name)
        md[:statement] = name
        md[:epl] = statement.getText
        md[:last_change] = statement.getTimeLastStateChange
        res << md
      end

      return res
    end

    public
    def statement_metadata(name)
      return @statement_md[name]
    end

    private
    def add_type_maps
      # for now, "metric" is the only type we care about.
      props = java.util.Properties.new
      props.setProperty("name", "String")
      props.setProperty("host", "String")
      props.setProperty("cluster", "String")
      props.setProperty("value", "Double")

      @ep_config.addEventType("metric", props)
    end # def add_type_maps

    public
    def set_time(new_time)
      if @time != new_time
        time_event = Java::ComEspertechEsperClientTime::CurrentTimeEvent.new(new_time)
        @runtime.sendEvent(time_event)
        @time = new_time
      end
    end # def set_time

    public
    def uptime
      return Time.now.to_i - @start
    end # def uptime

    public
    def destroy
      @engine.destroy
    end # def destroy
  end # class Engine
end # class CEPmon
