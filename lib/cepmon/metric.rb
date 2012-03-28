require "cepmon/libs"

class CEPMon
  class Metric < Java::JavaUtil::HashMap
    def initialize(metric)
      super()

      name, value, timestamp = metric.split(" ", 3)
      # name is of form "some.variable.name.cluster.host"
      parts = name.split(".")
      if parts.length < 3
        raise "invalid metric name: #{name}"
      end
      self["host"] = parts.pop
      self["cluster"] = parts.pop
      self["name"] = parts.join(".")
      self["value"] = value.to_f
      self["timestamp"] = timestamp.to_i
    end

    def send(engine)
      # set the time
      engine.set_time(self["timestamp"] * 1000)

      # send the value
      engine.runtime.sendEvent(self, "metric")
    end

    def to_s
      ["host", "cluster", "name", "value", "timestamp"].collect do |v|
        "#{v}=#{self[v]}"
      end.join(" ")
    end
  end
end
