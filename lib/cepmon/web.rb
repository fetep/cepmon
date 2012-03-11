require "rubygems"
require "cgi"
require "sinatra/base"
require "thread"
require "uri"

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
        CGI::escapeHTML(obj.to_s)
      end

      def rule_link(name, text)
        "<a href=\"/rules/#{name}\">#{h(text)}</a>"
      end

      def filter_alerts(alerts, params)
        res = alerts
        if params[:statement]
          res.delete_if { |a| a.statement != params[:statement] }
        end
        if params[:cluster]
          res.delete_if { |a| a.cluster != params[:cluster] }
        end
        if params[:host]
          res.delete_if { |a| a.host != params[:host] }
        end
        return res
      end
    end

    get "/rules" do
      @rules = @@event_listener.engine.statements
      erb :rules
    end

    get "/rules/:rule" do
      @rule = @@event_listener.engine.statements.select { |r| r[:statement] == params[:rule] }.first
      raise "can't find rule #{params[:rule]}" unless @rule
      erb :rule_detail
    end

    get "/history" do
      @alerts = filter_alerts(@@event_listener.history, params)
      erb :history
    end

    get "/alerts" do
      @alerts = filter_alerts(@@event_listener.alerts, params)
      erb :alerts
    end
  end # class Web
end # class CEPMon
