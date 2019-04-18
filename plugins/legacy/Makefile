TYPEDOC:= ./node_modules/.bin/typedoc

docs:
	$(TYPEDOC)
	cp CNAME docs/
	cp .nojekyll docs/

clean:
	rm -rf ./node_modules

publish:
	npm publish

update:
	ncu -u
	npm install

.PHONY: test
.PHONY: docs
