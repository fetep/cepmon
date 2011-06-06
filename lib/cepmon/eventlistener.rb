require "cepmon/libs"

module CEPMon
  class EventListener < Java::JavaLang::Object
    include com.espertech.esper.client.StatementAwareUpdateListener

    attr_reader :history

    public
    def initialize(keep_history=false)
      super()

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
        vars["_timestamp"] = timestamp
        puts "event: #{statement.getName} @#{timestamp}: #{vars.inspect}"
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
end # class CEPMon
