DIR_FRONTEND_BUILD = ${DIR_FRONTEND}/dist
DIR_CON_FRONTEND   = ${DIR_FRONTEND}/container/frontend
DIR_CON_APP        = ${DIR_CON_FRONTEND}/apps/${APP_ID}

-include ${DIR_FRONTEND}/.env

yarn-deps:
	cd ${DIR_FRONTEND} && COREPACK_ENABLE_DOWNLOAD_PROMPT=0 yarn install --immutable

yarn-deps-extract:
	rm -rf ./${DIR_FRONTEND_REL}/node_modules \
		&& tar xzf ${TQEM_DEPLOY_PATH}/${BUILD_ARCHIVE} ./${DIR_FRONTEND_REL}/node_modules

yarn-test-unit: yarn-deps
	cd ${DIR_FRONTEND} && yarn test:unit

yarn-audit:
	cd ${DIR_FRONTEND} && yarn npm audit

yarn-release:
	cd ${DIR_FRONTEND} && BUILD_VARIANT=${BUILD_VARIANT} yarn run build \
		--output-path ${DIR_FRONTEND_BUILD}

yarn-push:
	$(eval DIR_PKG_WWW = ${DIR_PACKAGE}/${BUILD_VARIANT}/pkg_root${DIR_APP_ROOT}/www)
	$(eval DIR_PKG_LICENSE = ${DIR_PACKAGE}/${BUILD_VARIANT}/pkg_root${DIR_APP_ROOT}/license)
	$(eval DIR_PKG_SBOM = ${DIR_PACKAGE}/${BUILD_VARIANT}/pkg_root${DIR_APP_ROOT}/sbom)
	mkdir -p ${DIR_PKG_WWW} ${DIR_PKG_LICENSE} ${DIR_PKG_SBOM}

	rsync --recursive --force \
		--exclude 'cyclonedx' --exclude '.well-known' --exclude 'ThirdPartyNotice.txt' \
		${DIR_FRONTEND_BUILD}/${BUILD_VARIANT}/* ${DIR_PKG_WWW}

	cp ${DIR_FRONTEND_BUILD}/${BUILD_VARIANT}/ThirdPartyNotice.txt \
		${DIR_PKG_LICENSE}/${APP_ID}.frontend.licenses

	# TODO: Remove fallback after implementing SBOM generation for all applications
	if [ -f ${DIR_FRONTEND_BUILD}/${BUILD_VARIANT}/cyclonedx/bom.json ]; then \
		cp ${DIR_FRONTEND_BUILD}/${BUILD_VARIANT}/cyclonedx/bom.json \
			${DIR_PKG_SBOM}/${APP_ID}.frontend-sbom.json; \
	else \
		@echo "Warning: Cannot find SBOM for ${APP_ID} with ${BUILD_VARIANT} variant."; \
		@echo "The shipping of the SBOM file to the empkg is skipped."; \
	fi

yarn-clean:
	rm -rf ${DIR_FRONTEND}/node_modules ${DIR_FRONTEND_BUILD} node_modules

yarn-upgrade:
	cd ${DIR_FRONTEND} && yarn upgrade
	$(MAKE) yarn-outdated

yarn-outdated:
	@echo "Checking for outdated packages with 'yarn outdated'. This lists packages that can be updated."
	cd ${DIR_FRONTEND} && yarn outdated || true

frontend-prepare:      yarn-deps
frontend-deps-fetch:   yarn-deps
frontend-deps-extract: yarn-deps-extract
frontend-release:      yarn-release
frontend-finish:       yarn-push
frontend-clean:        yarn-clean
frontend-upgrade:      yarn-upgrade

.PHONY: yarn-deps yarn-deps-extract yarn-test-unit yarn-audit yarn-release \
	yarn-push yarn-clean yarn-upgrade yarn-outdated \
