#!/bin/bash

set -e

# Install git (required to fetch acme.sh)
apk --update add git

# Get acme.sh Let's Encrypt client source - 2.8.6
commit_hash="9190fdd42c5332f8821ce3f0de91cf0d18fa07d5"
mkdir /src
git -C /src clone https://github.com/Neilpang/acme.sh.git
cd /src/acme.sh
git checkout "$commit_hash"

# Apply our patches
for patch in /app/acme.sh-patches/*; do
  patch -p1 <$patch
done

# Install acme.sh in /app
./acme.sh --install \
  --nocron \
  --noprofile \
  --auto-upgrade 0 \
  --home /app \
  --config-home /etc/acme.sh/default

# Make house cleaning
cd /
rm -rf /src
apk del git
rm -rf /var/cache/apk/*
