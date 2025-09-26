DIR_BACKEND_BUILD = ${DIR_BACKEND}/build

INIT = -X main.Version=${VERSION}

FEATURES_FLAGS ?=

ADD_GO_BUILD_FLAGS ?=

go-deps:
	cd ${DIR_BACKEND} && go mod vendor

go-deps-extract:
	rm -rf ./${DIR_BACKEND_REL}/vendor && tar xzf ${TQEM_ARTIFACTS_PATH}/${BUILD_ARCHIVE} ./${DIR_BACKEND_REL}/vendor

define GO_DEBUG
go-debug-$(1):
	$(eval DIR_BACKEND_BUILD_VARIANT=${DIR_BACKEND_BUILD}/$(1))

	cd ${DIR_BACKEND} && go build -mod=vendor ${ADD_GO_BUILD_FLAGS} -ldflags '${INIT} ${FEATURES_FLAGS}' -o ${DIR_BACKEND_BUILD_VARIANT}/${APP_NAME}
endef
$(foreach feature_variant,$(FEATURE_VARIANTS),$(eval $(call GO_DEBUG,$(feature_variant))))

define GO_RELEASE
go-release-$(1):
	$(eval DIR_BACKEND_BUILD_VARIANT=${DIR_BACKEND_BUILD}/$(1))

	cd ${DIR_BACKEND} && go build -mod=vendor ${ADD_GO_BUILD_FLAGS} -ldflags '-s -w ${INIT} ${FEATURES_FLAGS}' -o ${DIR_BACKEND_BUILD_VARIANT}/${APP_NAME}
endef
$(foreach feature_variant,$(FEATURE_VARIANTS),$(eval $(call GO_RELEASE,$(feature_variant))))

go-lint: go-deps
	cd ${DIR_BACKEND} && golangci-lint run --timeout=10m --modules-download-mode vendor --no-config -E misspell

go-sec: go-deps
	cd ${DIR_BACKEND} && golangci-lint run --timeout=10m --modules-download-mode vendor --no-config --disable-all -E gosec --exclude='G114,G306'

go-test:
	cd ${DIR_BACKEND} && go test -race -mod=vendor -v -cover -coverprofile ${DIR_BACKEND_BUILD}/cover.out ./...

go-test-junit: go-deps # Run unit test with junit report
	cd ${DIR_BACKEND} && go test -race -mod=vendor -v -coverprofile coverprofile ./... 2>&1 | go-junit-report -set-exit-code > ${TQEM_PROJECT_ROOT_PATH}/report.xml
	cd ${DIR_BACKEND} && go tool cover -func=coverprofile | grep total | awk '{ print $$1 " " $$3}'

go-coverage: go-test
	cd ${DIR_BACKEND} && go tool cover -html=${DIR_BACKEND_BUILD}/cover.out -o ${DIR_BACKEND_BUILD}/cover.html

go-generate-code: go-deps
	cd ${DIR_BACKEND} && go generate -v ./...
	git diff --exit-code ./${DIR_BACKEND_REL}

go-license:
	# workaround for go-licenses which cannot handle symlinks
	rm -f ${DIR_BACKEND}/LICENSE && cp -f LICENSE ${DIR_BACKEND}/LICENSE
	cd ${DIR_BACKEND} && em-go-licenses check .
	cd ${DIR_BACKEND} && em-go-licenses report . --template /etc/manifest.tpl > ${DIR_BACKEND_BUILD}/${APP_ID}.golang.manifest
	cd ${DIR_BACKEND} && em-go-licenses save . --force --save_path=${DIR_BACKEND_BUILD}/go-licenses
	git restore ${DIR_BACKEND}/LICENSE

define GO_PUSH
go-push-$(1):
	$(eval DIR_FEATURES_VARIANT = ${DEFAULT_VARIANT})

	$(eval DIR_PKG_BIN = ${DIR_PACKAGE}/$(1)/pkg_root${DIR_APP_ROOT}/bin)
	$(eval DIR_PKG_LICENSE = ${DIR_PACKAGE}/$(1)/pkg_root${DIR_APP_ROOT}/license)
	mkdir -p ${DIR_PKG_BIN} ${DIR_PKG_LICENSE}

	install -m755 ${DIR_BACKEND_BUILD}/${DIR_FEATURES_VARIANT}/${APP_NAME} ${DIR_PKG_BIN}/${APP_NAME}
	install -m644 ${DIR_BACKEND_BUILD}/${APP_ID}.golang.manifest ${DIR_PKG_LICENSE}
	cp -r ${DIR_BACKEND_BUILD}/go-licenses ${DIR_PKG_LICENSE}
endef
$(foreach variant,$(BUILD_VARIANTS),$(eval $(call GO_PUSH,$(variant))))

go-clean:
	rm -rf ${DIR_BACKEND_BUILD} ${DIR_BACKEND}/vendor

go-upgrade:
	cd ${DIR_BACKEND} && go get -u && go mod tidy && go mod vendor

backend-prepare:      go-deps
backend-deps-fetch:   go-deps
backend-deps-extract: go-deps-extract
backend-debug:        $(foreach feature_variant,$(FEATURE_VARIANTS), go-debug-$(feature_variant))
backend-release:      $(foreach feature_variant,$(FEATURE_VARIANTS), go-release-$(feature_variant))
backend-finish:       go-license $(foreach variant,$(BUILD_VARIANTS), go-push-$(variant))
backend-clean:        go-clean
backend-upgrade:      go-upgrade

.PHONY: go-deps go-deps-extract go-debug go-release go-lint go-sec go-test go-test-junit \
	go-coverage go-generate-code go-license go-clean go-upgrade
