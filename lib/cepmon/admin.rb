require "rubygems"
require "sinatra/base"

class CEPMon
  class Admin < Sinatra::Base
    @@engine = nil

    def self.engine=(engine)
      @@engine = engine
    end

    def initialize(*args)
      if @@engine.nil?
        raise "must set CEPMon::Admin.engine first"
      end

      super(*args)
    end

    get '/' do
      "Here, with engine! #{@@engine.inspect}"
    end
  end # class Admin
end # class CEPMon
