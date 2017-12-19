#!/usr/bin/env bash

npm install
npm update
npm publish

cd plugins

for d in */; do
    ( cd "$d" && npm install && npm publish )
done
