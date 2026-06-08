NPM_ROOT_DIR ?= .
NPM_PACKAGE_FILE ?= package.json
NPM_DEPS_DIR ?= ${NPM_ROOT_DIR}/node_modules
NPM_INSTALL = cd ${NPM_ROOT_DIR} && yarn install --immutable

npm-install:
	$(NPM_INSTALL)

${NPM_DEPS_DIR}:
	$(NPM_INSTALL)

npm-build: ${NPM_DEPS_DIR}
	cd ${NPM_ROOT_DIR} && yarn run build

npm-version-check:
	$(eval NPM_PACKAGE_VERSION = $(shell node -p "require('${NPM_ROOT_DIR}/${NPM_PACKAGE_FILE}').version"))
	git-helper.sh check-tag ${NPM_PACKAGE_VERSION}

npm-publish:
	cd ${NPM_ROOT_DIR} && YARN_NPM_AUTH_TOKEN=${NPM_DEPLOY_TOKEN} yarn npm publish

npm-clean:
	rm -rf ${NPM_DEPS_DIR}

all: npm-build

prepare:       npm-install
build:         npm-build
version-check: npm-version-check
deploy:        npm-publish
clean:         npm-clean

.PHONY: npm-install npm-build npm-version-check npm-publish npm-clean
