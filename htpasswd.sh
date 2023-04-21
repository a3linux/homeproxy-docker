#!/bin/bash

if [ $# -ne 2 ]; then
	echo "Missed or worng paramters"
	echo "Usage: $0 username password"
	exit 1
else
	docker run --rm -ti docker.io/xmartlabs/htpasswd $1 $2
fi
