#!/bin/sh

# Default script behavior.
set -o errexit
#set -o pipefail

# Default paramentes.
DEBUG=false
DEBUG_OPT=
WORK_DIRECTORY=.
SSH_USER=admin
SSH_KEY=
NOMAD_SSH_ARGUMENTS=
SSH_ARGUMENTS=
IP_ADDRESS=
COMMAND=
STD_IN=
STD_IN_TEMP_FILE=nomad_ssh_stdin.tmp

# For each parameter.
while :; do
	case ${1} in
		
		# If debug should be enabled.
		--debug)
			DEBUG=true
			DEBUG_OPT="--debug"
			;;

		# SSH user.
		--user)
			SSH_USER=${2}
			shift
			;;
			
		# IP address.
		--ip)
			IP_ADDRESS=${2}
			shift
			;;
			
		# SSH key.
		-k|--key)
			SSH_KEY=${2}
			shift
			;;

		# Key checking disabled.
		-u|--key-checking-disabled)
			NOMAD_SSH_ARGUMENTS="${NOMAD_SSH_ARGUMENTS} --option StrictHostKeyChecking=No"
			;;

		# Extra arguments.
		-*)
			NOMAD_SSH_ARGUMENTS="${NOMAD_SSH_ARGUMENTS} ${1}"
			;;

		# Command.
		*)
			COMMAND="${@}"
			break

	esac 
	shift
done

# Reads from stdin.
rm -f ${STD_IN_TEMP_FILE}
touch ${STD_IN_TEMP_FILE}
if [ ! -t 0 ]
then
	while read LINE
	do
		USE_SSH=true
		STD_IN="${STD_IN}${LINE}\n"
		echo "${LINE}" >> ${STD_IN_TEMP_FILE}
	done
fi

# Using unavaialble variables should fail the script.
set -o nounset

# Enables interruption signal handling.
trap - INT TERM

# Print parameters if on debug mode.
${DEBUG} && echo "Running 'nomad_ssh'"
${DEBUG} && echo "SSH_USER=${SSH_USER}"
${DEBUG} && echo "NOMAD_SSH_ARGUMENTS=${NOMAD_SSH_ARGUMENTS}"
${DEBUG} && echo "SSH_ARGUMENTS=${SSH_ARGUMENTS}"
${DEBUG} && echo "IP_ADDRESS=${IP_ADDRESS}"
${DEBUG} && echo "COMMAND=${COMMAND}"
${DEBUG} && echo "STD_IN=$(cat ${STD_IN_TEMP_FILE})"

# Configures SSH.
mkdir -p ~/.ssh
cp ${SSH_KEY} ~/.ssh/nomad_cluster_key  
chmod 600 ~/.ssh/nomad_cluster_key
eval $(ssh-agent -s) && \
ssh-add ~/.ssh/nomad_cluster_key

# If there is no stdin.
if [ -z "${STD_IN}" ]
then 

	${DEBUG} && echo "Running 'ssh -oStrictHostKeyChecking=no \
		${SSH_USER}@${IP_ADDRESS} ${SSH_ARGUMENTS} \
		\"${COMMAND}\"'"
	ssh -oStrictHostKeyChecking=no \
		${SSH_USER}@${IP_ADDRESS} ${SSH_ARGUMENTS} \
		"${COMMAND}"

# If there is stdin.
else 

	${DEBUG} && echo "Running 'ssh -oStrictHostKeyChecking=no \
		${SSH_USER}@${IP_ADDRESS} ${SSH_ARGUMENTS} \
		\"${COMMAND}\"' < ${STD_IN_TEMP_FILE}"
	ssh -oStrictHostKeyChecking=no \
		${SSH_USER}@${IP_ADDRESS} ${SSH_ARGUMENTS} \
		"${COMMAND}" < ${STD_IN_TEMP_FILE}

fi
