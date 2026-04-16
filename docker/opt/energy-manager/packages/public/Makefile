# Set empty targets here and override them in the included files
all:
prepare:
build:
version-check:
deploy:
clean:

# There is no default package type, it has to be defined by the including Makefile
ifeq ($(TQEM_TOOLCHAIN_PACKAGE),npm)
  include /opt/energy-manager/packages/public/npm.mk
endif

.PHONY: all prepare build version-check deploy clean
