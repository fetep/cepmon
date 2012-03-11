require "rubygems"
require "cgi"
require "sinatra/base"
require "thread"

class CEPMon
  class Web < Sinatra::Base
    @@event_listener = nil

    set :root, File.join(File.dirname(__FILE__), "..", "..")
    set :public_folder, Proc.new { File.join(root, "static") }
    enable :static

    def self.event_listener=(event_listener)
      @@event_listener = event_listener
    end

    def self.run!(*args, &block)
      started = false
      super(*args) do |server|
        Thread.current[:sinatra] = self
        started = true
        yield(server) if block_given?
      end
      raise "error starting sinatra" unless started
    end

    def initialize(*args)
      if @@event_listener.nil?
        raise "must set CEPMon::Web.event_listener first"
      end

      super(*args)
    end

    helpers do
      def h(obj)
        text = case obj.type
        when Float
          sprintf "%.2f", obj
        when String
          obj
        else
          obj.to_s
        end
        CGI::escapeHTML(text)
      end
    end

    get "/history" do
      @alerts = @@event_listener.history
      erb :history
    end

    get "/alerts" do
      @alerts = @@event_listener.alerts
      erb :alerts
    end
  end # class Web
end # class CEPMon
