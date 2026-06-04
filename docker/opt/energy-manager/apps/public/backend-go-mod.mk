DIR_BACKEND_BUILD = ${DIR_BACKEND}/build
DIR_BACKEND_VENDOR = ${DIR_BACKEND}/vendor

GO_MOD_VENDOR = cd ${DIR_BACKEND} && go mod vendor

ADD_GO_FEATURE_FLAGS ?=
ADD_GO_BUILD_FLAGS ?=

GO_INIT_LDFLAGS ?= $(if $(filter true,$(BACKEND_DEBUG_BUILD)),,-s -w )-X main.Version=${VERSION}

# BUILD
go-deps:
	$(GO_MOD_VENDOR)

${DIR_BACKEND_VENDOR}:
	$(GO_MOD_VENDOR)

go-deps-extract:
	rm -rf ./${DIR_BACKEND_REL}/vendor \
		&& tar xzf ${TQEM_DEPLOY_PATH}/${BUILD_ARCHIVE} ./${DIR_BACKEND_REL}/vendor

go-build: ${DIR_BACKEND_VENDOR}
	cd ${DIR_BACKEND} && go build -mod=vendor ${ADD_GO_BUILD_FLAGS} \
		-ldflags '${GO_INIT_LDFLAGS} ${ADD_GO_FEATURE_FLAGS}' \
		-o ${DIR_BACKEND_BUILD}/${FEATURE_VARIANT}/${APP_NAME}

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

go-push:
	$(eval DIR_PKG_BIN = ${DIR_PACKAGE}/${BUILD_VARIANT}/pkg_root${DIR_APP_ROOT}/bin)
	$(eval DIR_PKG_LICENSE = ${DIR_PACKAGE}/${BUILD_VARIANT}/pkg_root${DIR_APP_ROOT}/license)
	$(eval DIR_PKG_SBOM = ${DIR_PACKAGE}/${BUILD_VARIANT}/pkg_root${DIR_APP_ROOT}/sbom)
	mkdir -p ${DIR_PKG_BIN} ${DIR_PKG_LICENSE} ${DIR_PKG_SBOM}

	install -m755 ${DIR_BACKEND_BUILD}/${FEATURE_VARIANT}/${APP_NAME} ${DIR_PKG_BIN}/${APP_NAME}
	install -m644 ${DIR_BACKEND_BUILD}/${APP_ID}.golang.manifest ${DIR_PKG_LICENSE}
	install -m644 ${DIR_BACKEND_BUILD}/${APP_ID}.go-sbom.json ${DIR_PKG_SBOM}
	cp -r ${DIR_BACKEND_BUILD}/go-licenses ${DIR_PKG_LICENSE}

go-clean:
	rm -rf ${DIR_BACKEND_BUILD} ${DIR_BACKEND_VENDOR}

go-upgrade:
	cd ${DIR_BACKEND} && go get -u && go mod tidy && go mod vendor

GO_BUILD_PREREQS  = go-build
GO_FINISH_PREREQS = go-push

backend-prepare:         go-deps
backend-deps-fetch:      go-deps
backend-deps-extract:    go-deps-extract
backend-build:           $$(GO_BUILD_PREREQS)
backend-empkg-artifacts: go-license go-sbom
backend-finish:          $$(GO_FINISH_PREREQS)
backend-clean:           go-clean
backend-upgrade:         go-upgrade

.PHONY: go-deps go-deps-extract go-build go-license go-sbom go-push go-clean go-upgrade

# TEST
go-lint: ${DIR_BACKEND_VENDOR}
	cd ${DIR_BACKEND} && golangci-lint run

go-sec: ${DIR_BACKEND_VENDOR}
	cd ${DIR_BACKEND} && golangci-lint run --default=none -E gosec

go-test: ${DIR_BACKEND_VENDOR}
	cd ${DIR_BACKEND} && go test -race -mod=vendor -v -cover \
		-coverpkg=./... -coverprofile ${DIR_BACKEND_BUILD}/cover.out ./...
	cd ${DIR_BACKEND} && grep -v '/mocks'/ ${DIR_BACKEND_BUILD}/cover.out > ${DIR_BACKEND_BUILD}/cover.out.filtered && \
		mv ${DIR_BACKEND_BUILD}/cover.out.filtered ${DIR_BACKEND_BUILD}/cover.out

go-test-junit: ${DIR_BACKEND_VENDOR} # Run unit test with junit report
	cd ${DIR_BACKEND} && go test -race -mod=vendor -v -coverpkg=./... -coverprofile coverprofile ./... 2>&1 \
		| go-junit-report -set-exit-code > ${TQEM_PROJECT_ROOT_PATH}/report.xml
	cd ${DIR_BACKEND} && grep -v '/mocks'/ coverprofile > coverprofile.filtered && \
		mv coverprofile.filtered coverprofile
	cd ${DIR_BACKEND} && go tool cover -func=coverprofile | grep total | awk '{ print $$1 " " $$3}'

go-coverage: ${DIR_BACKEND_VENDOR}
	cd ${DIR_BACKEND} && go tool cover -html=${DIR_BACKEND_BUILD}/cover.out \
		-o ${DIR_BACKEND_BUILD}/cover.html

go-generate-code: ${DIR_BACKEND_VENDOR}
	cd ${DIR_BACKEND} && go generate -v ./...
	git-helper.sh check-clean "${DIR_BACKEND_REL}"

.PHONY: go-lint go-sec go-test go-test-junit go-coverage go-generate-code
