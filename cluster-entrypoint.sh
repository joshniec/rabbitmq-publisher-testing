#!/bin/bash

set -e

/usr/local/bin/docker-entrypoint.sh rabbitmq-server -detached

sleep 10

rabbitmqctl stop_app
rabbitmqctl join_cluster rabbit@rabbitmq1

# Stop the entire RMQ server. This is done so that we
# can attach to it again, but without the -detached flag
# making it run in the forground
rabbitmqctl stop

# Wait a while for the app to really stop
sleep 2s

# Start it
rabbitmq-server
