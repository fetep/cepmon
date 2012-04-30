require "cepmon/libs"
require "cepmon/alert"
require "rubygems"
require "bunny"

$stderr.puts "being loaded"

class CEPMon
  class EventListener < Java::JavaLang::Object
    include com.espertech.esper.client.StatementAwareUpdateListener

    attr_reader :engine
    attr_reader :history

    public
    def initialize(engine, config)
      super()

      @config = config
      @engine = engine
      @alerts = {}
      @history = []
    end

    public
    def update(new_events, old_events, statement, provider)
      return unless new_events

      amqp = Bunny.new(@config.amqp)
      amqp.start()
      exchange = amqp.exchange(@config.amqp[:exchange_alerts] , :type => :topic, :durable => true)
      new_events.each do |e|
        timestamp = provider.getEPRuntime.getCurrentTime / 1000
        vars = @engine.statement_metadata(statement.getName)
        e.getProperties().each { |k, v| vars[k.to_sym] = v }
        vars[:statement] = statement.getName
        vars[:timestamp] = timestamp

        puts "event: #{statement.getName} @#{timestamp} (#{Time.at(timestamp.to_i)}) (engine.uptime=#{@engine.uptime}): #{vars.collect { |h, k| [h, k.inspect].join("=") }.join(" ")}"
        $stderr.puts "event vars=#{vars.inspect}"
        record_alert(vars, statement.getName, exchange)
      end
      amqp.stop
    end # def update

    public
    def clear
      @alerts = {}
      @history = []
    end # def clear

    public
    def record_alert(vars, statement_name, exchange)
      alert_key = [statement_name, vars[:host], vars[:cluster]]
      expire_alerts

      key = [vars[:name], vars[:host], vars[:cluster]]
      if @alerts[key]
        @alerts[key].update(vars)
      else
        alert = CEPMon::Alert.new(vars)
        exchange.publish(alert.to_json)
        @alerts[key] = alert
        @history << alert
      end
    end

    public
    def expire_alerts
      @alerts.delete_if { |key, alert| alert.expired? }.values
    end

    public
    def alerts
      expire_alerts
      return @alerts.values
    end
  end # class EventListener
end # class CEPMon
