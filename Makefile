COVERALLS :=./node_modules/coveralls/bin/coveralls.js
MOCHA:= ./node_modules/.bin/mocha
MOCHAEXEC:= ./node_modules/.bin/_mocha
ISTANBUL:= ./node_modules/.bin/nyc
TYPEDOC:= ./node_modules/.bin/typedoc
TSC:= ./node_modules/.bin/tsc

test:
	tsc
	@NODE_ENV=test $(MOCHA) --trace-warnings --exit -u tdd -R spec

test-cover:
	tsc
	echo TRAVIS_JOB_ID $(TRAVIS_JOB_ID)
	@NODE_ENV=test $(ISTANBUL) $(MOCHAEXEC) --exit --report lcovonly -R spec && \
	cat ./coverage/lcov.info | $(COVERALLS) || true

cover:
	tsc
	@NODE_ENV=test $(ISTANBUL) $(MOCHAEXEC) --exit -R spec ./test/*.js

docs:
	$(TYPEDOC)
	cp CNAME docs/
	cp .nojekyll docs/

clean:
	rm -rf ./node_modules
	rm -f package-lock.json

publish:
	npm publish

update:
	-ncu -u
	-npm install
	$(TSC)

.PHONY: docs test
