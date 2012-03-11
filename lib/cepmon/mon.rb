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
      @event_listener = CEPMon::EventListener.new(@engine)
      @engine.add_statements(@config, @event_listener)
      @shutting_down = false
    end

    def run(args)
      Thread::abort_on_exception = true
      @server = nil
      @web_thread = Thread.new do
        CEPMon::Web.event_listener = @event_listener
        CEPMon::Web.run!(:host => "0.0.0.0", :port => 8989) do |server|
          @server = server
        end
      end

      # wait for sinatra to get started and set signal handlers
      while @server.nil?
        sleep(0.5)
      end

      amqp = Bunny.new(@config.amqp)

      [:TERM, :INT].each do |sig|
        Signal.trap(sig) do
          @shutting_down = true
          @web_thread[:sinatra].quit!(@server, "")
          amqp.stop
          @engine.destroy
        end
      end

      amqp.start
      queue = amqp.queue("cepmon-#{Process.pid}", :auto_delete => true)
      exchange = amqp.exchange("stats", :type => :topic, :durable => true)
      queue.bind(exchange)

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
    end # def run
  end # class Mon
end # class CEPMon
