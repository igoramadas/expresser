ifeq ($(OS),Windows_NT)
	MOCHA := node_modules/.bin/mocha.cmd
	DOCCO:= node_modules/.bin/docco.cmd
else
	MOCHA := ./node_modules/.bin/mocha
	DOCCO:= ./node_modules/.bin/docco
endif

test:
	$(MOCHA) -u tdd -R spec

docs:
	$(DOCCO) -l linear -o docs index.coffee lib/*.coffee

.PHONY: test
.PHONY: docs
