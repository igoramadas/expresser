COVERALLS :=./node_modules/coveralls/bin/coveralls.js
MOCHA:= ./node_modules/.bin/mocha
MOCHAEXEC:= ./node_modules/.bin/_mocha
ISTANBUL:= ./node_modules/.bin/nyc
TYPEDOC:= ./node_modules/.bin/typedoc

test:
	tsc
	@NODE_ENV=test $(MOCHA) --trace-warnings --exit -u tdd -R spec --timeout 4000

test-cover:
	echo TRAVIS_JOB_ID $(TRAVIS_JOB_ID)
	@NODE_ENV=test $(ISTANBUL) $(MOCHAEXEC) --exit --report lcovonly -R spec --timeout 4000 && \
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

publish:
	tsc --removeComments
	npm publish

update:
	rm -rf node_modules/jaul
	rm -rf node_modules/anyhow
	rm -rf node_modules/setmeup
	ncu -u
	npm install
	npm link jaul
	npm link anyhow
	npm link setmeup

.PHONY: test
.PHONY: docs
