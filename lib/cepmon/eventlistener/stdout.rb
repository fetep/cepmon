require "cepmon/libs"

module CEPMon; module EventListener
  class Stdout < Java::JavaLang::Object
    include com.espertech.esper.client.StatementAwareUpdateListener

    attr_reader :history

    public
    def initialize(engine, keep_history=false)
      super()

      @engine = engine
      @keep_history = keep_history
      @history = []
    end

    public
    #def self.update(new_events, old_events)
    def update(new_events, old_events, statement, provider)
      return unless new_events

      new_events.each do |e|
        timestamp = provider.getEPRuntime.getCurrentTime / 1000
        vars = {}
        e.getProperties().each { |k, v| vars[k] = v }
        puts "event: #{statement.getName} @#{timestamp} (#{Time.at(timestamp.to_i)}) (engine.uptime=#{@engine.uptime}): #{vars.collect { |h, k| [h, k].join("=") }.join(" ")}"
        if statement.getName =~ /_alerts_/
          puts "ALERT: #{statement.getName}: #{Time.at(timestamp.to_i)}: threshold=#{vars["threshold"]} value=#{vars["value"]}"
        end
        vars["_timestamp"] = timestamp
        if @keep_history
          @history << [statement.getName, vars]
        end
      end
    end # def update

    public
    def clear_history
      @history = []
    end # def clear
  end # class EventListener
end; end # module CEPMon::EventListener
