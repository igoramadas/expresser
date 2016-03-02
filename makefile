ifeq ($(OS),Windows_NT)
	MOCHA := node_modules/.bin/mocha.cmd
	GROC:= node_modules/.bin/groc.cmd
else
	MOCHA := ./node_modules/.bin/mocha
	GROC:= ./node_modules/.bin/groc
endif

test:
	$(MOCHA) -u tdd -R spec

docs:
	$(GROC)

clean:
	rm -rf ./node_modules
	rm -rf ./logs/*.log

.PHONY: test
.PHONY: docs
