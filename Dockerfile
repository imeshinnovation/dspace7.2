FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Bogota

RUN apt clean
RUN apt-get update && apt-get upgrade -y
RUN apt-get install curl wget htop net-tools nano git openssh-server sudo gnupg build-essential -y


RUN apt-get install -y locales tzdata

ENV LANG=C
ENV LANGUAGE=C
ENV LC_ALL=C


RUN echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
RUN apt-get update && apt-get install postgresql-13 postgresql-contrib-13 libpostgresql-jdbc-java -y

RUN apt install openjdk-11-jdk ant ant-optional maven -y


RUN echo "host dspace dspace 127.0.0.1/32 md5" | sudo tee -a /etc/postgresql/13/main/pg_hba.conf
RUN sed -i 's/ident/trust/' /etc/postgresql/13/main/pg_hba.conf
RUN sed -i 's/md5/trust/' /etc/postgresql/13/main/pg_hba.conf
RUN sed -i 's/peer/trust/' /etc/postgresql/13/main/pg_hba.conf

RUN adduser dspace && usermod -aG sudo dspace
RUN echo "dspace:dspace" | chpasswd
RUN echo "root:p4nd0r4#$SD" | chpasswd
RUN mkdir -p /var/run/sshd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
RUN sed -i 's/ALL=(ALL:ALL) ALL/ALL=(ALL:ALL) NOPASSWD:ALL/g' /etc/sudoers

RUN echo "export JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64" >> /etc/profile
RUN echo "export CATALINA_HOME=/opt/tomcat" >> /etc/profile

RUN echo "export JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64" >> /home/dspace/.bashrc
RUN echo "export CATALINA_HOME=/opt/tomcat" >> /home/dspace/.bashrc
RUN echo "export LC_ALL=C" >> /home/dspace/.bashrc

RUN echo "export JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64" >> /root/.bashrc
RUN echo "export CATALINA_HOME=/opt/tomcat" >> /root/.bashrc
RUN echo "export LC_ALL=C" >> /root/.bashrc

ENV JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64
ENV CATALINA_HOME=/opt/tomcat
ENV LC_ALL=C

RUN usermod -aG sudo postgres
RUN echo "postgres:p4nd0r4#$SD" | chpasswd

RUN su postgres
RUN /etc/init.d/postgresql start

ADD start.sh /
RUN chmod a+x /start.sh

ADD monk.sh /
RUN chmod a+x /monk.sh

RUN wget -c https://downloads.apache.org/lucene/solr/8.11.2/solr-8.11.2.tgz -O - | tar xz -C /opt/
RUN wget -c https://github.com/DSpace/DSpace/archive/refs/tags/dspace-7.2.tar.gz -O - | tar xz -C /opt/
RUN wget -c https://github.com/DSpace/dspace-angular/archive/refs/tags/dspace-7.2.tar.gz -O - | tar xz -C /opt/


ADD ./build/pom.xml /opt/DSpace-dspace-7.2/dspace-api/

RUN cd /opt/DSpace-dspace-7.2 && mvn -U package
RUN wget -c https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.80/bin/apache-tomcat-9.0.80.tar.gz -O - | tar xz -C /opt/ && mv /opt/apache-tomcat-9.0.80 /opt/tomcat

RUN /monk.sh

CMD ["/start.sh"]