ifeq ($(OS),Windows_NT)
	MOCHA := node_modules/.bin/mocha.cmd
	DOCCO:= node_modules/.bin/betterdocco.cmd
else
	MOCHA := ./node_modules/.bin/mocha
	DOCCO:= ./node_modules/.bin/betterdocco
endif

test:
	$(MOCHA) -u tdd -R mocha-lcov-reporter

docs:
	betterdocco -o docs/source index.coffee lib/*.coffee plugins/**/*.coffee

clean:
	rm -rf ./node_modules
	rm -rf ./logs/*.log

.PHONY: test
.PHONY: docs
