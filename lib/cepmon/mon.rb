require "cepmon/engine"
require "cepmon/eventlistener"
require "cepmon/metric"
require "cepmon/web"
require "rubygems"
require "bunny"

class CEPMon
  class Mon
    def initialize(config)
      @config = config
      @engine = CEPMon::Engine.new
      @event_listener = CEPMon::EventListener.new(@engine, @config)
      @engine.add_statements(@config, @event_listener)
      @shutting_down = false
    end

    def run(args)
      Thread::abort_on_exception = true
      @server = nil
      @web_thread = Thread.new do
        CEPMon::Web.event_listener = @event_listener
        CEPMon::Web.run!(:host => @config.host, :port => @config.port) do |server|
          @server = server
        end
      end

      @verbose = false
      if args.member?("-v")
        @verbose = true
      end

      # wait for sinatra to get started and set signal handlers
      while @server.nil?
        sleep(0.5)
      end

      if @config.amqp.length > 0 && @config.tcp.length > 0
        raise "no support for both amqp and tcp inputs at once"
      elsif @config.amqp.length > 0
        run_amqp
      elsif @config.tcp.length > 0
        run_tcp
      else
        raise "no inputs configured"
      end
    end # def run

    def run_amqp
      amqp = Bunny.new(@config.amqp)

      [:TERM, :INT].each do |sig|
        Signal.trap(sig) do
          @shutting_down = true
          @web_thread[:sinatra].quit!(@server, "")
          amqp.stop
          @engine.destroy
        end
      end

      @config.logger.info("connecting to rabbitmq...")
      amqp.start
      queue = amqp.queue("cepmon-#{Process.pid}", :auto_delete => true)
      exchange = amqp.exchange(@config.amqp[:exchange_metrics],
                               :type => :topic,
                               :durable => true)
      queue.bind(exchange)
      @config.logger.info("connected; bound queue cepmon-#{Process.pid} to topic #{@config.amqp[:exchange_metrics]}")

      Thread.new do
        begin
          queue.subscribe do |msg|
            msg[:payload].split("\n").each do |line|
                CEPMon::Metric.new(line).send(@engine)
            end
          end
        rescue Bunny::ServerDownError, Bunny::ConnectionError
          if ! @shutting_down
            # TODO: implement reconnect
            throw
          end
        end # begin
      end.join # Thread.new
    end # def run_amqp

    def run_tcp
      sock = TCPServer.new(@config.tcp[:host], @config.tcp[:port])

      [:TERM, :INT].each do |sig|
        Signal.trap(sig) do
          @shutting_down = true
          @web_thread[:sinatra].quit!(@server, "")
          sock.close
          @engine.destroy
        end
      end

      @config.logger.info("listening for carbon updates on " + 
                          "#{@config.tcp[:host]}:#{@config.tcp[:port]}")

      queue = Queue.new
      Thread.new do
        while line = queue.pop
          begin
            CEPMon::Metric.new(line).send(@engine)
          rescue
            @config.logger.warn("error parsing metric #{line.inspect}: #{$!}")
          end
        end
      end

      loop do
        Thread.start(sock.accept) do |client|
          begin
            while line = client.gets
              line.chomp!
              next if line == ""
              queue << line
            end
          rescue
            @config.logger.warn("read error with client #{client.peeraddr[2]}: #{$!}")
            client.close rescue nil
          end
        end
      end
    end # def run_amqp

  end # class Mon
end # class CEPMon
