# From service cluster CLI.
FROM coldis/infrastructure-service-cluster-cli AS service-cluster-cli

# From Jenkins.
FROM jenkins/jenkins:2.257-jdk11

# Sets the user to root.
USER root

# Changes locale and timezone.
RUN cp /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && \
	apt-get purge -y locales
ENV TZ=America/Sao_Paulo

# Installs basic tools and languages.
RUN apt-get update -y && \
	apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common && \
	apt-get remove -y docker docker.io && \
	curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
	add-apt-repository -y \
		"deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" && \
	apt-get update -y && \
	apt-get install -y docker-ce=5:18.09.7~3-0~debian-stretch docker-ce-cli=5:18.09.7~3-0~debian-stretch && \
	usermod -aG docker jenkins && \
	systemctl enable docker && \
	curl -sL https://deb.nodesource.com/setup_10.x | bash - && \	
	apt-get install -y nodejs && \
	npm cache clean -f && \
	npm install -g n && \
	apt-get install -y git maven jq cron gosu zip unzip && \
	apt-get autoremove -y && \
	apt-get clean -y && \
	rm -rf /var/lib/apt/lists/*
	
# Installs chrome driver.
RUN apt-get update -y && \
	apt-get install -y wget unzip && \
	mkdir -p temp/ && \
	cd temp && \
	wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
	( dpkg -i google-chrome-stable_current_amd64.deb || true ) && \
	apt-get install -yf && \
	LATEST_CHROMEDRIVER=$(curl https://chromedriver.storage.googleapis.com/LATEST_RELEASE) && \
	wget https://chromedriver.storage.googleapis.com/$LATEST_CHROMEDRIVER/chromedriver_linux64.zip && \
	mkdir -p /opt/chromedriver/ && \
	unzip chromedriver_linux64.zip -d /opt/chromedriver/ && \
	cd .. && \
	rm -rf temp/ && \
	apt-get remove -y unzip && \
	apt-get autoremove -y && \
	apt-get clean -y && \
	rm -rf /var/lib/apt/lists/*
	
# Installs service cluster CLI.
ENV DCOS_VERSION="latest"
COPY --from=service-cluster-cli /opt/dcos-script/ /opt/dcos-script/
RUN	chmod +x /opt/dcos-script/*.sh && \
	ln -s /opt/dcos-script/*.sh /usr/bin && \
	for FILE in /usr/bin/dcos*.sh; do  mv -- "${FILE}" "${FILE%.sh}"; done && \
	dcos_install --version ${DCOS_VERSION}
	
# Copies operational scripts.
COPY --from=service-cluster-cli /opt/operational-utils-script/ /opt/operational-utils-script/
RUN	chmod +x /opt/operational-utils-script/utils/script/*.sh && \
	ln -s /opt/operational-utils-script/utils/script/*.sh /usr/bin && \
	for FILE in /usr/bin/operational_utils*.sh; do  mv -- "${FILE}" "${FILE%.sh}"; done

# Copies scripts.
ENV JENKINS_SCRIPT=/opt/jenkins-script
RUN mkdir -p ${JENKINS_SCRIPT}
COPY script ${JENKINS_SCRIPT}
RUN chown -R jenkins:jenkins ${JENKINS_SCRIPT} && \
	ln -s ${JENKINS_SCRIPT}/*.sh /usr/bin && \
	for FILE in /usr/bin/jenkins*.sh; \
	do \
		chown jenkins:jenkins ${FILE} && \	
		mv -- "${FILE}" "${FILE%.sh}"; \
	done
	
	
# Configures scheduled jobs.
#COPY cron /etc/cron.d
#RUN chmod -R 0644 /etc/cron.d/ && \
#	crontab /etc/cron.d/jenkins_jobs && \
#	touch /var/jenkins_home/cron_env && \
#	chown jenkins.jenkins /var/jenkins_home/cron_env && \
#	service cron start
	
# Sets the user back to Jenkins.
USER jenkins
ENV HOME=/var/jenkins_home
WORKDIR /var/jenkins_home

# Creates necessary directories.
RUN mkdir -p .m2 secrets

# Configures Java memory.
ENV JAVA_OPTS="-Xms128m -Xmx5g -XX:MaxDirectMemorySize=5g"
ENV MAVEN_OPTS="-Xms128m -Xmx5g -XX:MaxDirectMemorySize=5g"

# Installs plugins.
COPY config/plugins.conf /usr/share/jenkins/ref/plugins.conf
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.conf

# Entrypoint.
ENTRYPOINT [ "jenkins_init" ]

