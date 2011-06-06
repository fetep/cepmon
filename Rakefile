# Most of this magic borrowed from logstash's Makefile.

VERSIONS = {
  :jruby => "1.6.0",
  :esper => "4.2.0",
}

namespace :vendor do
  file "vendor/jar" do |t|
    mkdir_p t.name
  end

  file "vendor/jar/jruby-complete-#{VERSIONS[:jruby]}.jar" => "vendor/jar" do |t|
    baseurl = "http://repository.codehaus.org/org/jruby/jruby-complete"
    if !File.exists?(t.name)
      sh "wget -O #{t.name} #{baseurl}/#{VERSIONS[:jruby]}/#{File.basename(t.name)}"
    end
  end

  task :jruby => "vendor/jar/jruby-complete-#{VERSIONS[:jruby]}.jar" do
    # nothing
  end

  file "vendor/jar/esper-#{VERSIONS[:esper]}.tar.gz" => "vendor/jar" do |t|
    baseurl = "http://dist.codehaus.org/esper"
    if !File.exists?(t.name)
      sh "wget -O #{t.name} #{baseurl}/#{File.basename(t.name)}"
    end
  end

  file "vendor/jar/esper-#{VERSIONS[:esper]}/esper-#{VERSIONS[:esper]}.jar" => "vendor/jar/esper-#{VERSIONS[:esper]}.tar.gz" do
    sh "tar -xzf vendor/jar/esper-#{VERSIONS[:esper]}.tar.gz -C vendor/jar esper-#{VERSIONS[:esper]}/esper-#{VERSIONS[:esper]}.jar esper-#{VERSIONS[:esper]}/esper/lib/antlr-runtime-3.2.jar esper-#{VERSIONS[:esper]}/esper/lib/commons-logging-1.1.1.jar esper-#{VERSIONS[:esper]}/esper/lib/log4j-1.2.16.jar"
  end

  task :esper => "vendor/jar/esper-#{VERSIONS[:esper]}/esper-#{VERSIONS[:esper]}.jar" do
    # nothing
  end

  task :gems => "vendor" do
    sh "bundle install --path #{File.join("vendor", "bundle")}"
  end


  file "vendor/meteo/com/ning/metrics/meteo/esper" do |t|
    mkdir_p t.name
  end

  file "vendor/meteo/com/ning/metrics/meteo/publishers" do |t|
    mkdir_p t.name
  end

  meteo_giturl = "https://raw.github.com/ning/meteo/master/src/main/java/com/ning/metrics/meteo"

  ["esper/HoltWintersComputer.java", "esper/HoltWinters.java", "esper/HoltWintersViewFactory.java", "esper/TPAggregator.java", "publishers/EsperListener.java"].each do |f|
    file "vendor/meteo/com/ning/metrics/meteo/#{f}" => ["vendor/meteo/com/ning/metrics/meteo/esper", "vendor/meteo/com/ning/metrics/meteo/publishers"] do |t|
      sh "wget -O #{t.name} #{meteo_giturl}/#{f}"
    end
  end

  task :meteo_compile do
    sh "cd vendor/meteo && javac -cp ../jar/esper-4.2.0/esper-4.2.0.jar:../jar/esper-4.2.0/esper/lib/log4j-1.2.16.jar com/ning/metrics/meteo/*/*.java"
    sh "cd vendor/meteo && jar cf meteo.jar com/ning/metrics/meteo/*/*.class"
  end

  task :meteo => ["vendor/meteo/com/ning/metrics/meteo/esper/HoltWintersComputer.java", "vendor/meteo/com/ning/metrics/meteo/esper/HoltWinters.java", "vendor/meteo/com/ning/metrics/meteo/esper/HoltWintersViewFactory.java", "vendor/meteo/com/ning/metrics/meteo/esper/TPAggregator.java", "vendor/meteo/com/ning/metrics/meteo/publishers/EsperListener.java", :meteo_compile] do
    # nothing
  end
end

task :compile do
  target = "build/ruby"
  mkdir_p target

  Dir.chdir("lib") do
    relative = File.join("..", target)
    sh "jrubyc", "-t", relative, "cepmon/runner.rb"

    Dir.glob("**/*.rb").each do |file|
      d = File.join(relative, File.dirname(file))
      mkdir_p d
      cp file, File.join(d, File.basename(file))
    end
  end
end

namespace :package do
  task :jar => ["vendor:esper", "vendor:jruby", "vendor:gems", "vendor:meteo", "compile"] do
    build_dir = "build/jar"
    mkdir_p build_dir
    Dir.glob("vendor/{bundle,jar}/**/*.jar").each do |jar|
      relative = File.join(build_dir.split(File::SEPARATOR).collect { ".." })
      Dir.chdir(build_dir) { sh "jar xf #{relative}/#{jar}" }
    end

    Dir.glob("build/ruby/**/*.class").each do |file|
      target = File.join(build_dir, file.sub("build/ruby/", ""))
      mkdir_p File.dirname(target)
      cp file, target
    end

    # Purge any extra files we don't need in META-INF (like manifests and
    # jar signatures)
    ["INDEX.LIST", "MANIFEST.MF", "ECLIPSEF.RSA", "ECLIPSEF.SF"].each do |file|
      File.delete(File.join(builddir, "META-INF", file)) rescue nil
    end

    target_jar = "cepmon-0.1.jar"
    sh "jar cfe #{target_jar} cepmon.runner -C #{build_dir} ."

    jar_update_args = []

    gem_dirs = %w{doc gems specifications}
    gem_root = File.join("vendor", "bundle", "jruby", "1.8")
    jar_update_args += gem_dirs.collect { |d| ["-C", gem_root, d] }.flatten

    # compiled runner
    jar_update_args += %w{-C build/ruby .}

    sh "jar uf #{target_jar} #{jar_update_args.join(" ")}"
    sh "jar i #{target_jar}"
  end
end
