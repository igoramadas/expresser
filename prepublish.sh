#!/bin/bash
npm prune
./node_modules/.bin/docco -l linear -o docs `find . \( -name "*.coffee" ! -path "*node_modules*" \)`
