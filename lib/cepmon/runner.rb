require "cepmon/config"
require "cepmon/libs"
require "cepmon/test"

java_import org.apache.log4j.ConsoleAppender
java_import org.apache.log4j.Level
java_import org.apache.log4j.Logger
java_import org.apache.log4j.SimpleLayout

module CEPMon
  class Runner
    def self.main(argv)
      layout = SimpleLayout.new()
      appender = ConsoleAppender.new(layout)
      Logger.getRootLogger().addAppender(appender)
      Logger.getRootLogger().setLevel(Level::WARN)

      command = argv.shift
      case command
      when "test"
        config = CEPMon::Config.new
        CEPMon::Test.new(config).run(argv)
      when "mon"
      else
        $stderr.puts "invalid command #{command}"
        exit(1)
      end
    end
  end # class Runner
end # module CEPMon


if __FILE__ == $0
  CEPMon::Runner.main(ARGV)
end
