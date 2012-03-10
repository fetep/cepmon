require "rubygems"
require "sinatra/base"

class CEPMon
  class Web < Sinatra::Base
    @@event_listener = nil

    def self.event_listener=(event_listener)
      @@event_listener = event_listener
    end

    def initialize(*args)
      if @@event_listener.nil?
        raise "must set CEPMon::Web.event_listener first"
      end

      super(*args)
    end

    get "/history" do
      content_type "text/plain"

      @@event_listener.history.collect { |a| a.to_s }.join("\n")
    end

    get "/alerts" do
      content_type "text/plain"

      @@event_listener.alerts.collect { |a| a.to_s }.join("\n")
    end
  end # class Web
end # class CEPMon
