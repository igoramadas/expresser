# MAKE EXPRESSER

all: clean update build

build:
	npm run build

clean:
	npm run clean

publish:
	npm publish

test:
	npm test

update:
	-rm -rf ./node_modules
	-rm -f package-lock.json
	npm install
	npm run build

.PHONY: test
