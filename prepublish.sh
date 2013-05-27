#!/bin/bash
npm prune
docco -l linear -o docs `find . \( -name "*.coffee" ! -path "*node_modules*" \)`