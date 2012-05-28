require "cepmon/engine"
require "cepmon/eventlistener"
require "cepmon/metric"

class CEPMon
  class Test
    def initialize(config)
      @config = config
      @engine = CEPMon::Engine.new
      @event_listener = CEPMon::EventListener.new(@engine, @config)
      @engine.add_statements(@config, @event_listener)
    end

    def run(args)
      args.each do |file|
        linenum = 0
        File.open(file).each do |line|
          linenum += 1
          line.chomp!
          case line
          when /^(#|$)/
            next
          when "clear"
            @engine.admin.destroyAllStatements()
            @engine.add_statements(@config, @event_listener)
            @event_listener.clear
          when /^(assert_active|assert_inactive) (.+)/
            assert_type, statement = $1, $2
            match = false
            @event_listener.alerts.each do |a|
              if a.data[:statement] == statement
                match = true
                break
              end
            end

            if assert_type == "assert_active" and match == false
              raise "#{file}:#{linenum}: assert_active #{statement} failed"
            elsif assert_type == "assert_inactive" and match == true
              raise "#{file}:#{linenum}: assert_inactive #{statement} failed"
            end
          else
            CEPMon::Metric.new(line).send(@engine)
          end # case line
        end # File.open
      end # args.each
    end # def run
  end # class Test
end # class CEPMon

#Logger = org.apache.log4j.Logger
#layout = org.apache.log4j.SimpleLayout.new()
#appender = org.apache.log4j.ConsoleAppender.new(layout)
#Logger.getRootLogger().addAppender(appender)
#Logger.getRootLogger().setLevel(org.apache.log4j.Level::WARN)
