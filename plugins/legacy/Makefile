TYPEDOC:= ./node_modules/.bin/typedoc

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
	rm -f package-lock.json
	ncu -u
	npm install

.PHONY: docs test
