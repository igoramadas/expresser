ifeq ($(OS),Windows_NT)
	MOCHA:= node_modules/.bin/mocha.cmd
	MOCHAEXEC:= node_modules/.bin/_mocha
	DOCCO:= node_modules/.bin/betterdocco.cmd
	CODO:= node_modules/.bin/bettercodo.cmd
	ISTANBUL:= node_modules/istanbul/lib/cli.js
	TESTPATH:= test/*.js
else
	MOCHA:= ./node_modules/.bin/mocha
	MOCHAEXEC:= ./node_modules/.bin/_mocha
	DOCCO:= ./node_modules/.bin/betterdocco
	CODO:= ./node_modules/.bin/bettercodo
	ISTANBUL:= ./node_modules/istanbul/lib/cli.js
	TESTPATH:= ./test/*.js
endif

test:
	$(MOCHA) -u tdd -R spec
cover:
	$(ISTANBUL) cover $(MOCHAEXEC) -- -R spec $(TESTPATH)
docs:
	$(DOCCO) -o docs/annotated index.coffee lib/*.coffee plugins/**/*.coffee
	$(CODO) -o ./docs/codo -n Expresser ./lib ./lib/utils ./plugins
clean:
	rm -rf ./node_modules
	rm -rf ./logs/*.log

.PHONY: test
.PHONY: docs
