require "cepmon/libs"

class CEPMon
  class Metric < Java::JavaUtil::HashMap
    attr_reader :line

    def initialize(metric)
      super()

      @line = metric
      metric_parts = metric.split(" ", 3)
      if metric_parts.length != 3
        raise "invalid metric update: #{metric.inspect}"
      end
      name, value, timestamp = metric_parts
      # name is of form "some.variable.name.cluster.host"
      name_parts = name.split(".")
      if name_parts.length < 3
        raise "invalid metric name: #{name}"
      end
      self["host"] = name_parts.pop
      self["cluster"] = name_parts.pop
      self["name"] = name_parts.join(".")
      self["value"] = value.to_f
      self["timestamp"] = timestamp.to_i
    end

    def send(engine, set_time=false)
      engine.set_time(self["timestamp"] * 1000) if set_time
      engine.runtime.sendEvent(self, "metric")
    end

    def to_s
      ["host", "cluster", "name", "value", "timestamp"].collect do |v|
        "#{v}=#{self[v]}"
      end.join(" ")
    end
  end
end
