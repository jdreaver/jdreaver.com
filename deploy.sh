#!/usr/bin/env bash

set -eux;

stack build
stack exec jdreaver-site -- build
(cd _site/ && AWS_PROFILE=personal aws s3 sync --delete . s3://jdreaver.com)
