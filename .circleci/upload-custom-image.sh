#!/usr/bin/env bash

# Builds and uploads our custom image needed for CircleCI

set -eu;

image_tag="jdreaver/circleci-jdreaver.com"
printf 'Building %s\n' "$image_tag"
docker build -f "Dockerfile" -t "$image_tag" .
docker push "$image_tag"
