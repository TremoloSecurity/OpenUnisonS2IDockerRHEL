# openunison-centos7
FROM centos:7

MAINTAINER Tremolo Security, Inc. - Docker <docker@tremolosecurity.com>

ENV BUILDER_VERSION=1.0 \
    JDK_VERSION=1.8.0 \
    MAVEN_VERSION=3.3.9 \
    CATALINA_OPTS="-Xms512M -Xmx1024M -server -XX:+UseParallelGC" \
    JAVA_OPTS="-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom" \
    TOMCAT_VERSION="8.5.15"

LABEL io.k8s.description="Platform for building Tremolo Security OpenUnison" \
      io.k8s.display-name="OpenUnison Builder 1.0.11" \
      io.openshift.expose-services="8080:8443" \
      io.openshift.tags="builder,1.0.11,sso,identity management" \
      io.openshift.s2i.scripts-url="image:///usr/local/bin/s2i"

RUN yum install -y unzip which tar java-${JDK_VERSION}-openjdk-devel.x86_64 net-tools.x86_64 && \
    yum clean all -y && \
    echo -e "\nInstalling Tomcat $TOMCAT_VERSION" && \
    curl -v https://www.apache.org/dist/tomcat/tomcat-8/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz | tar -zx -C /usr/local && \
    ln -s /usr/local/apache-tomcat-${TOMCAT_VERSION} /usr/local/tomcat && \
    echo -e "\nInstalling Maven $MAVEN_VERSION" && \
    curl -v http://www.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz | tar -zx -C /usr/local && \
    ln -s /usr/local/apache-maven-${MAVEN_VERSION}/bin/mvn /usr/local/bin/mvn && \
    mkdir -p /etc/openunison && \
    mkdir -p /usr/local/tremolo/tremolo-service && \
    groupadd -r tremoloadmin -g 433 && \
    useradd -u 431 -r -g tremoloadmin -d /usr/local/tremolo/tremolo-service -s /sbin/nologin -c "OpenUnison Docker image user" tremoloadmin

ADD server.xml /usr/local/apache-tomcat-${TOMCAT_VERSION}/conf/
ADD run.sh /usr/local/apache-tomcat-${TOMCAT_VERSION}/bin/

# Copy the S2I scripts to /usr/local/bin since I updated the io.openshift.s2i.scripts-url label
COPY ./s2i/bin/ /usr/local/bin/s2i

RUN chown -R tremoloadmin:tremoloadmin \
    /etc/openunison \
    /usr/local/tremolo/tremolo-service \
    /usr/local/apache-maven-$MAVEN_VERSION \
    /usr/local/apache-tomcat-$TOMCAT_VERSION \
    /usr/local/tomcat \
    /usr/local/bin/mvn \
  && chmod +x /usr/local/apache-tomcat-${TOMCAT_VERSION}/bin/run.sh

USER 431

EXPOSE 8080
EXPOSE 8443

CMD ["usage"]
