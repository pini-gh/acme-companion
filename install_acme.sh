#!/bin/bash

set -e

# Install git (required to fetch acme.sh)
apk --update add git

# Get acme.sh Let's Encrypt client source
commit_hash="9cc9f519fc394f553f352d0ba79750b797044864"
mkdir /src
git -C /src clone https://github.com/Neilpang/acme.sh.git
cd /src/acme.sh
git checkout "$commit_hash"

# Install acme.sh in /app
./acme.sh --install \
  --nocron \
  --auto-upgrade 0 \
  --home /app \
  --config-home /etc/acme.sh/default

# Make house cleaning
cd /
rm -rf /src
apk del git
rm -rf /var/cache/apk/*
