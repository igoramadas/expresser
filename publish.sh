#!/usr/bin/env bash

npm publish
cd plugins

for d in */; do
    ( cd "$d" && npm update && npm publish )
done
