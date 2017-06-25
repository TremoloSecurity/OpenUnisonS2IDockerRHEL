FROM registry.access.redhat.com/rhel7

MAINTAINER Tremolo Security, Inc. - Docker <docker@tremolosecurity.com>

ENV BUILDER_VERSION=1.0 \
    JDK_VERSION=1.8.0 \
    MAVEN_VERSION=3.3.9 \
    CATALINA_OPTS="-Xms512M -Xmx1024M -server -XX:+UseParallelGC -DunisonEnvironmentFile=/etc/openunison/oo.env" \
    JAVA_OPTS="-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom" \
    TOMCAT_VERSION="8.5.15" \
    CLASSPATH="/tmp/quartz"

    LABEL name="OpenUnison" \
          vendor="Tremolo Security, Inc." \
          version="1.0.11" \
          release="2017061801" \
    ### Recommended labels below
          url="https://www.tremolosecurity.com/unison/" \
          summary="Platform for building Tremolo Security OpenUnison" \
          description="OpenUnison is an identity management platforms that can provide solutions for applications and infrastructure. Services include user provisioning, web access management & SSO, LDAP virtual directory and a user self service portal." \
          run='docker run -tdi --name ${NAME} -v /path/to/unison:/usr/local/tremolo/tremolo-service/external:Z ${IMAGE}' \
          io.k8s.description="Cloud Native Identity Management" \
          io.k8s.display-name="OpenUnison Builder 1.0.11" \
          io.openshift.expose-services="8080:http,8443:https" \
          io.openshift.tags="identity management,sso,user provisioning,devops,saml,openid connect" \
          io.openshift.tags="builder,1.0.11,sso,identity management" \
          io.openshift.s2i.scripts-url="image:///usr/local/bin/s2i"

ADD metadata/help.md /tmp/help.md

RUN   yum clean all && yum-config-manager --disable \* &> /dev/null && \
### Add necessary Red Hat repos here
    yum-config-manager --enable rhel-7-server-rpms,rhel-7-server-optional-rpms &> /dev/null && \
    yum -y update-minimal --security --sec-severity=Important --sec-severity=Critical --setopt=tsflags=nodocs && \
    yum install -y --setopt=tsflags=nodocs golang-github-cpuguy83-go-md2man unzip which tar java-${JDK_VERSION}-openjdk-devel.x86_64 net-tools.x86_64 python && \
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
    useradd -u 431 -r -g tremoloadmin -d /usr/local/tremolo/tremolo-service -s /sbin/nologin -c "OpenUnison Docker image user" tremoloadmin && \
    go-md2man -in /tmp/help.md -out /help.1 && yum -y remove golang-github-cpuguy83-go-md2man && \
    yum -y clean all

ADD server_template.xml /usr/local/tomcat/conf/
ADD run.sh /usr/local/tomcat/bin/
ADD eval_secrets.py /usr/local/tomcat/bin/

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

VOLUME /etc/openunison

USER 431

EXPOSE 8080
EXPOSE 8443

CMD ["usage"]
