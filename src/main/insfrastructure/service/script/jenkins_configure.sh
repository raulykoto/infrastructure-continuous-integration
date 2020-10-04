#!/bin/sh

# Default script behavior.
set -o errexit
#set -o pipefail

# Default parameters.
DEBUG=false
DEBUG_OPT=

# For each argument.
while :; do
	case ${1} in
		
		# If debuf is enabled.
		--debug)
			DEBUG=true
			DEBUG_OPT="--debug"
			;;

		# No more options.
		*)
			break

	esac 
	shift
done

# Using unavaialble variables should fail the script.
set -o nounset

# Enables interruption signal handling.
trap - INT TERM

# Print arguments if on debug mode.
${DEBUG} && echo "Running 'jenkins_configure'"

# If there is a git user.
if env | grep "GIT_USER_NAME=" && [ ! -z "${GIT_USER_NAME}" ]
then
	# Configures git.
	git config --global user.name ${GIT_USER_NAME}
fi

# If there is a git user.
if env | grep "GIT_USER_EMAIL=" && [ ! -z "${GIT_USER_EMAIL}" ]
then
	# Configures git.
	git config --global user.email ${GIT_USER_EMAIL}
fi

# If there is maven information.
if env | grep "MAVEN_REPOSITORY_ID=" && [ ! -z "${MAVEN_REPOSITORY_ID}" ]
then
	
	# Configures Maven.
	${DEBUG} && echo "Configuring Maven in continuous integration"
	tee .m2/settings.xml <<EOF
<settings>
	<servers>
		<server>
			<id>${MAVEN_REPOSITORY_ID}</id>
			<username>${MAVEN_USER_NAME}</username>
			<password>${MAVEN_USER_PASSWORD}</password>
		</server> 
	</servers> 
	<mirrors>
		<mirror>
			<id>${MAVEN_REPOSITORY_ID}</id>
			<name>Repository mirror</name>
			<url>${MAVEN_REPOSITORY_URL}</url>
			<mirrorOf>*</mirrorOf>
		</mirror>
	</mirrors>
	<profiles>
		<profile>
			<id>${MAVEN_REPOSITORY_ID}</id>
			<repositories>
				<repository>
				<id>${MAVEN_REPOSITORY_ID}</id>
				<url>${MAVEN_REPOSITORY_URL}</url>
					<releases><enabled>true</enabled></releases>
					<snapshots><enabled>true</enabled></snapshots>
				</repository>
			</repositories>
			<pluginRepositories>
				<pluginRepository>
				<id>${MAVEN_REPOSITORY_ID}</id>
				<url>${MAVEN_REPOSITORY_URL}</url>
					<releases><enabled>true</enabled></releases>
					<snapshots><enabled>true</enabled></snapshots>
				</pluginRepository>
			</pluginRepositories>
		</profile>
	</profiles>
	<activeProfiles>
		<activeProfile>${MAVEN_REPOSITORY_ID}</activeProfile>
	</activeProfiles>
</settings>
EOF

fi

# If there Docker information.
if env | grep "DOCKER_USER_NAME=" && [ ! -z "${DOCKER_USER_NAME}" ]
then

	# Logs in the Docker repository.
	${DEBUG} && echo "Logging in the docker repository"
	docker login -u ${DOCKER_USER_NAME} \
		-p ${DOCKER_USER_PASSWORD} ${DOCKER_REPOSITORY_URL} || \
	echo "Docker login failed."

fi

# If there is DCOs configuration.
if [ -d ${JENKINS_HOME}/dcos/ ]
then

	# For each configured enviroment.
	for CURRENT_ENVIRONMENT in ${HOME}/dcos/*
	do
	
		${DEBUG} && echo "Running DCOS CLI for ${CURRENT_ENVIRONMENT}"
		. ${CURRENT_ENVIRONMENT}/dcos_cli.properties
		export CLUSTER_ADDRESS
		export DCOS_DIR=${CURRENT_ENVIRONMENT}
		dcos_init \
			--uid continuous-integration \
			--private-key ${HOME}/secrets/continuous_integration_private.pem || \
		echo "DCOS CLI not available for ${CURRENT_ENVIRONMENT}."
	
	done

fi


