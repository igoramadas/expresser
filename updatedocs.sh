#!/bin/bash
./node_modules/.bin/codo
./node_modules/.bin/docco -l linear -o docs/annotated `find . \( -name "*.coffee" ! -path "*node_modules*" \)`