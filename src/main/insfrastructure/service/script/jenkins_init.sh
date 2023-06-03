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
${DEBUG} && echo "Running 'jenkins_init'"

# Starts cron.
#env > /var/jenkins_home/docker_env
#chmod +x /var/jenkins_home/docker_env
#service cron status

# Configures Jenkins.
jenkins_configure ${DEBUG_OPT}

# Executes the main process.
/usr/bin/tini -- /usr/local/bin/jenkins.sh



