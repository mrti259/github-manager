NPM = cd app && npm

install:
	$(NPM) install

start:
	$(NPM) start

test:
	$(NPM) test

build:
	$(NPM) run build -- --emptyOutDir --outDir ../docs
