#!/bin/bash

set -e
set -x

#set http proxy to speed up
PROXY_IP="172.17.0.1"
PROXY_PORT="8118"

JENKINS_VERSION=`curl -sq https://api.github.com/repos/jenkinsci/jenkins/tags | grep '"name":' | grep -o '[0-9]\.[0-9]*'  | uniq | sort --version-sort | tail -1`
echo $JENKINS_VERSION

JENKINS_SHA=`curl http://repo.jenkins-ci.org/simple/releases/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war.sha1`
echo $JENKINS_SHA

docker build --build-arg JENKINS_VERSION=$JENKINS_VERSION \
             --build-arg JENKINS_SHA=$JENKINS_SHA \
             --build-arg PROXY_IP=$PROXY_IP --build-arg PROXY_PORT=$PROXY_PORT \
             --pull \
             --tag hyperhq/jenkins-hypercli:$JENKINS_VERSION .

docker tag -f hyperhq/jenkins-hypercli:$JENKINS_VERSION hyperhq/jenkins-hypercli:latest

docker push hyperhq/jenkins-hypercli:$JENKINS_VERSION
docker push hyperhq/jenkins-hypercli:latest
