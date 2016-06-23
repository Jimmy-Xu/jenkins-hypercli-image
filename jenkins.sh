#! /bin/bash

set -e

##### generate .hyper/config.json begin #####
generate_hyper_config() {
	if [[ ! -n ${ACCESS_KEY} ]] || [[ ! -n ${SECRET_KEY} ]]; then
		cat <<EOF
Please specified hyper credential by env 'ACCESS_KEY' and 'SECRET_KEY'
eg:
	hyper run -it --rm -e ACCES_KEY="xxx" -e SECRET_KEY="xxx" hyperhq/jenkins-hypercli:2.10 bash

EOF
		exit 1
	fi
	HYPER_CONF_DIR=${JENKINS_HOME}/.hyper
	HYPER_CONF_FILE=${HYPER_CONF_DIR}/config.json
	mkdir -p ${HYPER_CONF_DIR}
	cat > ${HYPER_CONF_FILE} <<EOF
{
	"auths": {},
	"clouds": {
		"tcp://us-west-1.hyper.sh:443": {
			"accesskey": "${ACCESS_KEY}",
			"secretkey": "${SECRET_KEY}"
		}
	}
}
EOF
	echo "[ ${HYPER_CONF_FILE} ]"
	echo "--------------------------"
	cat ${HYPER_CONF_FILE}
	echo "--------------------------"
}
generate_hyper_config
##### generate .hyper/config.json end #####


# Copy files from /usr/share/jenkins/ref into $JENKINS_HOME
# So the initial JENKINS-HOME is set with expected content.
# Don't override, as this is just a reference setup, and use from UI
# can then change this, upgrade plugins, etc.
copy_reference_file() {
	f="${1%/}"
	b="${f%.override}"
	echo "$f" >> "$COPY_REFERENCE_FILE_LOG"
	rel="${b:23}"
	dir=$(dirname "${b}")
	echo " $f -> $rel" >> "$COPY_REFERENCE_FILE_LOG"
	if [[ ! -e $JENKINS_HOME/${rel} || $f = *.override ]]
	then
		echo "copy $rel to JENKINS_HOME" >> "$COPY_REFERENCE_FILE_LOG"
		mkdir -p "$JENKINS_HOME/${dir:23}"
		cp -r "${f}" "$JENKINS_HOME/${rel}";
		# pin plugins on initial copy
		[[ ${rel} == plugins/*.jpi ]] && touch "$JENKINS_HOME/${rel}.pinned"
	fi;
}
: ${JENKINS_HOME:="/var/jenkins_home"}
export -f copy_reference_file
touch "${COPY_REFERENCE_FILE_LOG}" || (echo "Can not write to ${COPY_REFERENCE_FILE_LOG}. Wrong volume permissions?" && exit 1)
echo "--- Copying files at $(date)" >> "$COPY_REFERENCE_FILE_LOG"
find /usr/share/jenkins/ref/ -type f -exec bash -c "copy_reference_file '{}'" \;

# if `docker run` first argument start with `--` the user is passing jenkins launcher arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
  eval "exec java $JAVA_OPTS -jar /usr/share/jenkins/jenkins.war $JENKINS_OPTS \"\$@\""
fi

# As argument is not jenkins, assume user want to run his own process, for sample a `bash` shell to explore this image
exec "$@"
