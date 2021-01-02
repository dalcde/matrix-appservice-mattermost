#!/bin/sh

rm -rf build tsconfig.tsbuildinfo
mkdir build
npm ci
npm run build
npm ci --only=prod
mv node_modules build/
tar czf matrix-appservice-mattermost.tar.gz build/ --transform s/build/matrix-appservice-mattermost/
