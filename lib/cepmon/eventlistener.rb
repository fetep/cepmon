require "cepmon/libs"
require "cepmon/alert"

$stderr.puts "being loaded"

class CEPMon
  class EventListener < Java::JavaLang::Object
    include com.espertech.esper.client.StatementAwareUpdateListener

    attr_reader :history

    public
    def initialize(engine)
      super()

      @engine = engine
      @alerts = {}
      @history = []
    end

    public
    #def self.update(new_events, old_events)
    def update(new_events, old_events, statement, provider)
      return unless new_events

      new_events.each do |e|
        timestamp = provider.getEPRuntime.getCurrentTime / 1000
        vars = {}
        e.getProperties().each { |k, v| vars[k.to_sym] = v }
        vars[:statement] = statement.getName
        vars[:timestamp] = timestamp
        puts "event: #{statement.getName} @#{timestamp} (#{Time.at(timestamp.to_i)}) (engine.uptime=#{@engine.uptime}): #{vars.collect { |h, k| [h, k].join("=") }.join(" ")}"
        if statement.getName =~ /_alerts_/
          alert = CEPMon::Alert.new(vars)
          add_alert(alert)
          $stderr.puts alert.to_s
        end
      end
    end # def update

    public
    def clear
      @alerts = {}
      @history = []
    end # def clear

    public
    def add_alert(alert)
      key = [alert.name, alert.host, alert.cluster]
      @alerts[key] = alert
      @history << alert
    end

    public
    def alerts
      @alerts.delete_if { |key, alert| alert.expired? }.values
    end
  end # class EventListener
end # class CEPMon
