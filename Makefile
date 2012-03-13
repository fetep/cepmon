CEPMON_VERSION = 0.2
ESPER_VERSION = "4.2.0"

METEO_FILES = esper/HoltWintersComputer.java esper/HoltWinters.java esper/HoltWintersViewFactory.java esper/TPAggregator.java publishers/EsperListener.java
METEO_GITHUB = "https://raw.github.com/ning/meteo/master/src/main/java/com/ning/metrics/meteo"

fetch_esper:
	mkdir -p vendor/jar
	wget -O vendor/jar/esper-${ESPER_VERSION}.tar.gz http://dist.codehaus.org/esper/prior-releases/esper-${ESPER_VERSION}.tar.gz

extract_esper:
	tar -xzf vendor/jar/esper-${ESPER_VERSION}.tar.gz -C vendor/jar esper-${ESPER_VERSION}/esper-${ESPER_VERSION}.jar esper-${ESPER_VERSION}/esper/lib/antlr-runtime-3.2.jar esper-${ESPER_VERSION}/esper/lib/commons-logging-1.1.1.jar esper-${ESPER_VERSION}/esper/lib/log4j-1.2.16.jar

fetch_meteo:
	mkdir -p vendor/meteo/com/ning/metrics/meteo/esper
	mkdir -p vendor/meteo/com/ning/metrics/meteo/publishers
	for f in ${METEO_FILES}; do \
		wget -O vendor/meteo/com/ning/metrics/meteo/$$f ${METEO_GITHUB}/$$f; \
	done

compile_meteo:
	javac -cp vendor/jar/esper-${ESPER_VERSION}/esper-${ESPER_VERSION}.jar:vendor/jar/esper-${ESPER_VERSION}/esper/lib/log4j-1.2.16.jar vendor/meteo/com/ning/metrics/meteo/*/*.java
	(cd vendor/meteo && jar cf meteo.jar com/ning/metrics/meteo/*/*.class)

fetch: fetch_esper fetch_meteo extract_esper compile_meteo

jar:
	warble executable jar

rpm:
	rm -rf build/root
	mkdir -p build/root/opt/cepmon
	cp cepmon.jar build/root/opt/cepmon/cepmon.jar
	(cd build; fpm -t rpm -d jre -a noarch -n logstash -v $(CEPMON_VERSION) -s dir -C root opt)

