# MAKE EXPRESSER

all: clean update build docs

build:
	npm run build

clean:
	npm run clean

docs:
	npm run docs

publish:
	npm publish

test:
	npm test

update:
	-ncu -u -x chai,chalk,get-port
	-ncu -u --target minor
	-rm -rf ./node_modules
	-rm -f package-lock.json
	npm install --force or --legacy-peer-deps
	npm run build

.PHONY: docs test
