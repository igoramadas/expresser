COVERALLS :=./node_modules/coveralls/bin/coveralls.js
MOCHA:= ./node_modules/.bin/mocha
MOCHAEXEC:= ./node_modules/.bin/_mocha
ISTANBUL:= ./node_modules/.bin/istanbul
TYPEDOC:= ./node_modules/.bin/typedoc

test:
	tsc
	@NODE_ENV=test $(MOCHA) --trace-warnings --exit -u tdd -R spec --timeout 4000

test-cover:
	echo TRAVIS_JOB_ID $(TRAVIS_JOB_ID)
	@NODE_ENV=test $(ISTANBUL) cover \
	$(MOCHAEXEC) -exit --report lcovonly -- -R spec --timeout 4000 && \
	cat ./coverage/lcov.info | $(COVERALLS) || true

cover:
	tsc
	$(ISTANBUL) cover $(MOCHAEXEC) -- --exit -R spec ./test/*.js

docs:
	$(TYPEDOC)
	cp CNAME docs/

clean:
	rm -rf ./node_modules

update:
	npm update
	npm link anyhow
	npm link jaul
	npm link setmeup

.PHONY: test
.PHONY: docs
