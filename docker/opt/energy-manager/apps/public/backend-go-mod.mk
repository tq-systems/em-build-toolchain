DIR_BACKEND_BUILD = ${DIR_BACKEND}/build

INIT = -X main.Version=${VERSION}

ADD_GO_FEATURE_FLAGS ?=
ADD_GO_BUILD_FLAGS ?=

go-deps:
	cd ${DIR_BACKEND} && go mod vendor

go-deps-extract:
	rm -rf ./${DIR_BACKEND_REL}/vendor \
		&& tar xzf ${TQEM_DEPLOY_PATH}/${BUILD_ARCHIVE} ./${DIR_BACKEND_REL}/vendor

go-debug-build:
	cd ${DIR_BACKEND} && go build -mod=vendor ${ADD_GO_BUILD_FLAGS} \
		-ldflags '${INIT} ${ADD_GO_FEATURE_FLAGS}' \
		-o ${DIR_BACKEND_BUILD}/${FEATURE_VARIANT}/${APP_NAME}

go-release-build:
	cd ${DIR_BACKEND} && go build -mod=vendor ${ADD_GO_BUILD_FLAGS} \
		-ldflags '-s -w ${INIT} ${ADD_GO_FEATURE_FLAGS}' \
		-o ${DIR_BACKEND_BUILD}/${FEATURE_VARIANT}/${APP_NAME}

go-lint: go-deps
	cd ${DIR_BACKEND} && golangci-lint run --timeout=10m --modules-download-mode vendor \
		--no-config -E misspell

go-sec: go-deps
	cd ${DIR_BACKEND} && golangci-lint run --timeout=10m --modules-download-mode vendor \
		--no-config --disable-all -E gosec --exclude='G114,G306'

go-test:
	cd ${DIR_BACKEND} && go test -race -mod=vendor -v -cover \
		-coverprofile ${DIR_BACKEND_BUILD}/cover.out ./...

go-test-junit: go-deps # Run unit test with junit report
	cd ${DIR_BACKEND} && go test -race -mod=vendor -v -coverprofile coverprofile ./... 2>&1 \
		| go-junit-report -set-exit-code > ${TQEM_PROJECT_ROOT_PATH}/report.xml
	cd ${DIR_BACKEND} && go tool cover -func=coverprofile | grep total | awk '{ print $$1 " " $$3}'

go-coverage: go-test
	cd ${DIR_BACKEND} && go tool cover -html=${DIR_BACKEND_BUILD}/cover.out \
		-o ${DIR_BACKEND_BUILD}/cover.html

go-generate-code: go-deps
	cd ${DIR_BACKEND} && go generate -v ./...
	git-helper.sh git_check_clean "${DIR_BACKEND_REL}"


go-license:
	# workaround for go-licenses which cannot handle symlinks
	rm ${DIR_BACKEND}/LICENSE && cp -f LICENSE ${DIR_BACKEND}/LICENSE
	cd ${DIR_BACKEND} && em-go-licenses check .
	cd ${DIR_BACKEND} && em-go-licenses report . \
		--template /etc/manifest.tpl > ${DIR_BACKEND_BUILD}/${APP_ID}.golang.manifest
	cd ${DIR_BACKEND} && em-go-licenses save . --force --save_path=${DIR_BACKEND_BUILD}/go-licenses
	git restore ${DIR_BACKEND}/LICENSE

go-sbom:
	cyclonedx-gomod app -json -output ${DIR_BACKEND_BUILD}/${APP_ID}.go-sbom.json ${DIR_BACKEND}

go-metadata: go-license go-sbom

go-push:
	$(eval DIR_PKG_BIN = ${DIR_PACKAGE}/${BUILD_VARIANT}/pkg_root${DIR_APP_ROOT}/bin)
	$(eval DIR_PKG_LICENSE = ${DIR_PACKAGE}/${BUILD_VARIANT}/pkg_root${DIR_APP_ROOT}/license)
	$(eval DIR_PKG_SBOM = ${DIR_PACKAGE}/${BUILD_VARIANT}/pkg_root${DIR_APP_ROOT}/sbom)
	mkdir -p ${DIR_PKG_BIN} ${DIR_PKG_LICENSE} ${DIR_PKG_SBOM}

	install -m755 ${DIR_BACKEND_BUILD}/${FEATURE_VARIANT}/${APP_NAME} ${DIR_PKG_BIN}/${APP_NAME}
	install -m644 ${DIR_BACKEND_BUILD}/${APP_ID}.golang.manifest ${DIR_PKG_LICENSE}
	install -m644 ${DIR_BACKEND_BUILD}/${APP_ID}.go-sbom.json ${DIR_PKG_SBOM}
	cp -r ${DIR_BACKEND_BUILD}/go-licenses ${DIR_PKG_LICENSE}

go-finish: go-metadata
	$(MAKE) go-push

go-clean:
	rm -rf ${DIR_BACKEND_BUILD} ${DIR_BACKEND}/vendor

go-upgrade:
	cd ${DIR_BACKEND} && go get -u && go mod tidy && go mod vendor

backend-prepare:       go-deps
backend-deps-fetch:    go-deps
backend-deps-extract:  go-deps-extract
backend-debug-build:   go-debug-build
backend-release-build: go-release-build
backend-finish:        go-finish
backend-clean:         go-clean
backend-upgrade:       go-upgrade

.PHONY: go-deps go-deps-extract go-debug-build go-release-build \
	go-lint go-sec go-test go-test-junit go-coverage go-generate-code \
	go-license go-sbom go-metadata go-push go-finish go-clean go-upgrade
