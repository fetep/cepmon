require "cepmon/config"
require "cepmon/libs"
require "cepmon/mon"
require "cepmon/test"

java_import org.apache.log4j.ConsoleAppender
java_import org.apache.log4j.Level
java_import org.apache.log4j.SimpleLayout
JLogger = org.apache.log4j.Logger

class CEPMon
  class Runner
    def self.main(argv)
      layout = SimpleLayout.new()
      appender = ConsoleAppender.new(layout)
      JLogger.getRootLogger().addAppender(appender)
      JLogger.getRootLogger().setLevel(Level::WARN)

      command = argv.shift
      config_file = argv.shift || "cepmon.cfg"
      case command
      when "test"
        config = CEPMon::Config.new(config_file)
        CEPMon::Test.new(config).run(argv)
      when "mon"
        config = CEPMon::Config.new(config_file)
        CEPMon::Mon.new(config).run(argv)
      else
        $stderr.puts "invalid command #{command}"
        exit(1)
      end
    end
  end # class Runner
end # class CEPMon


if __FILE__ == $0
  CEPMon::Runner.main(ARGV)
end
