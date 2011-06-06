require "java"

jar_paths = []
jar_paths << File.join(File.dirname(__FILE__), "..", "..", "vendor", "jar", "**", "*.jar")
jar_paths << File.join(File.dirname(__FILE__), "..", "..", "vendor", "meteo", "*.jar")

jar_paths.each do |path|
  Dir.glob(path).each do |jar|
    require jar
  end
end
