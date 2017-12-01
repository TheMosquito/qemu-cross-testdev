#!/bin/bash

IMAGE=$1
TAG=$2

if docker inspect ${IMAGE}:${TAG} >/dev/null 2>&1
then
	TZ=GMT touch -t $(docker inspect -f '{{ .Created }}' ${IMAGE}:${TAG} | awk -F. '{print $1}' | sed 's/[-T]//g' | sed 's/://' | sed 's/:/./') ${IMAGE}-${TAG}.flag
else
	rm -f ${IMAGE}-${TAG}.flag
fi

