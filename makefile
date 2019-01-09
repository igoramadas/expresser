ifeq ($(OS),Windows_NT)
	COFFEEJSDOC:= node_modules/.bin/COFFEEJSDOC.cmd
	MOCHA:= node_modules/.bin/mocha.cmd
	MOCHAEXEC:= node_modules/.bin/_mocha
	DOCCO:= node_modules/.bin/betterdocco.cmd
	ISTANBUL:= node_modules/istanbul/lib/cli.js
	TESTPATH:= test/*.js
else
	COFFEEJSDOC:= ./node_modules/.bin/coffeejsdoc
	MOCHA:= ./node_modules/.bin/mocha
	MOCHAEXEC:= ./node_modules/.bin/_mocha
	DOCCO:= ./node_modules/.bin/betterdocco
	ISTANBUL:= ./node_modules/istanbul/lib/cli.js
	TESTPATH:= ./test/*.js
endif

test:
	$(MOCHA) --trace-warnings --exit -u tdd -R spec

cover:
	$(ISTANBUL) cover $(MOCHAEXEC) -- -R spec $(TESTPATH)

docs:
	$(COFFEEJSDOC)
	$(DOCCO) -o docs/annotated lib/*.coffee plugins/**/*.coffee
	cp CNAME docs/

clean:
	rm -rf ./node_modules
	rm -rf ./logs/*.log

.PHONY: test
.PHONY: docs
