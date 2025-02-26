#!/bin/bash
set -e

BROKER_HOME=/var/lib/
CONFIG_PATH=$BROKER_HOME/etc
export BROKER_HOME OVERRIDE_PATH CONFIG_PATH

if [[ ${ANONYMOUS_LOGIN,,} == "true" ]]; then
  LOGIN_OPTION="--allow-anonymous"
else
  LOGIN_OPTION="--require-login"
fi

if ! [ -x ./etc/broker.xml ]; then
    CREATE_ARGUMENTS="--user ${ARTEMIS_USER} --password ${ARTEMIS_PASSWORD} --silent ${LOGIN_OPTION} ${EXTRA_ARGS}"
    /opt/activemq-artemis/bin/artemis create ${CREATE_ARGUMENTS} .
else
    echo "skipping broker instance creation; instance already exists"
fi

for f in ./etc-override/*
do
  if [ -f $f ]; then
    echo "Copying $f to ./etc/"
    cp --dereference --preserve --verbose --recursive $f ./etc/
  fi
done