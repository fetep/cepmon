require "cepmon/engine"
require "cepmon/eventlistener/stdout"
require "cepmon/metric"

module CEPMon
  class Test
    def initialize(config)
      @config = config
      @engine = CEPMon::Engine.new
      @event_listener = CEPMon::EventListener::Stdout.new(@engine, true)
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
            @event_listener.clear_history
          when /^assert (!)?([^ ]+)( .*)?/
            negate, statement, variables = $1, $2, $3

            if negate
              # make sure the statement hasn't fired
              hist = @event_listener.history.select { |h| h[0] == statement }
              if hist.length > 0
                raise "#{file}:#{linenum}: assert !#{statement} failed, rule fired: #{hist.inspect}"
              end

              next
            end

            # make sure the statement fired
            hist = @event_listener.history.select { |h| h[0] == statement }
            if hist.length == 0
              raise "#{file}:#{linenum}: assert #{statement} failed, did not fire"
            end

            # check variables
            variables ||= ""
            variables.strip.split(/ +/).each do |eq|
              var, value = eq.split("=", 2)
              # use the first event that fired
              event_vars = hist.first[1]
              #puts "checking #{var} == #{value.inspect}: #{event_vars[var].inspect}"
              if value != event_vars[var].to_s
                raise "#{file}:#{linenum}: assert #{statement} #{var}==#{value} failed, actual value is #{event_vars[var]}"
              end
            end
          else
            CEPMon::Metric.new(line).send(@engine)
          end # case line
        end # File.open
      end # args.each
    end # def run
  end # class Test
end # module CEPMon

#Logger = org.apache.log4j.Logger
#layout = org.apache.log4j.SimpleLayout.new()
#appender = org.apache.log4j.ConsoleAppender.new(layout)
#Logger.getRootLogger().addAppender(appender)
#Logger.getRootLogger().setLevel(org.apache.log4j.Level::WARN)
