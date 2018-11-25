#
# Makefile to generate yFuzz golang binaries
#
# Copyright 2018 Oath, Inc.
# Licensed under the terms of the Apache version 2.0 license. See LICENSE file for terms.
#
# By default it's not very noisy, call with verbose=true for more detailed information.
#

TARGET ?= $(shell basename `pwd`)
YFUZZ_BUILD_VERSION ?= $(shell git describe --tags --abbrev=0)_local
HAS_DEP := $(shell command -v dep;)

# Run go build or go install with the appropriate flags
define _build
	go $(1) -ldflags "-s -w -X github.com/yahoo/yfuzz/pkg/version.Version=${YFUZZ_BUILD_VERSION} \
													-X github.com/yahoo/yfuzz/pkg/version.Timestamp=$(shell date +'%Y/%m/%d_%H:%M:%S')"
endef

all: deps dep-check lint test build

clean:
	@echo Cleaning binaries, vendor for ${TARGET}.
	go clean
	if [ -f ${TARGET} ]; then rm ${TARGET}; fi
	rm -rf vendor

deps:
	@echo Installing dependencies for ${TARGET}.
ifndef HAS_DEP
	curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
endif
ifeq (${verbose},true)
	dep ensure -v
else
	dep ensure
endif
ifndef TRAVIS
	go get -u github.com/golangci/golangci-lint/cmd/golangci-lint
endif

dep-check:
	@echo Running dep check to verify consistency across Gopkg.toml, Gopkg.lock, and vendor.
	dep check

lint:
ifdef TRAVIS
	@echo Skipping lint in Travis, linting is done by https://golangci.com/
else
	@echo Running linters for ${TARGET}
	golangci-lint run -E golint -E interfacer -E unconvert -E goconst -E goimports ./...
endif

test:
	@echo Running tests for ${TARGET}.
ifeq (${verbose},true)
	go test -v ./...
else
	go test ./...
endif

build:
	@echo Building ${TARGET} ${YFUZZ_BUILD_VERSION}
	$(call _build,build -o ${TARGET})

install:
	@echo Installing ${TARGET} ${YFUZZ_BUILD_VERSION}
	$(call _build,install)

.PHONY: clean deps dep-check lint test build install
