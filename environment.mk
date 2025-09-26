IMAGE ?= common amd64 aarch64

COMPOSE_FILE ?= -f docker-compose.yml
# Additional docker-compose build options may be set (e.g. --no-cache)
BUILD_ARGS ?=

DOCKER_COMPOSE := docker compose $(COMPOSE_FILE) build $(BUILD_ARGS)

# The if-clause also applies if an empty string is set in CI pipelines
ifeq ($(strip ${BUILD_TAG}),)
	BUILD_TAG := latest
endif

# .env file is read by docker-compose
export DOCKER_COMPOSE_ENV = .env
export TQEM_TMP_PATH = tmp

# Default strings, if no docker registry images are defined
LOCAL_BASE = local/em/base
LOCAL_TOOLCHAIN = local/em/toolchain

BASE_REGISTRY ?= ${LOCAL_BASE}
BASE_DOCKER_TAG ?= latest
PUBLIC_TOOLCHAIN_REGISTRY ?= ${LOCAL_TOOLCHAIN}
TQEM_APPS_CACHE ?= ""

BUILD_RELEASE ?= false
EM_BUILD_REF ?= master

DOCKER_USER ?= tqemci

export define DOCKER_COMPOSE_ENV_CONTENT
BASE_REGISTRY=${BASE_REGISTRY}
BASE_DOCKER_TAG=${BASE_DOCKER_TAG}
PUBLIC_TOOLCHAIN_REGISTRY=${PUBLIC_TOOLCHAIN_REGISTRY}
BUILD_TAG=${BUILD_TAG}
DOCKER_USER=${DOCKER_USER}
endef
