.PHONY: all build release app package run test lint format verify clean

all: build

build:
	swift build

release:
	swift build -c release

app:
	./scripts/build-app.sh release

package:
	./scripts/package-release.sh

run: build
	swift run CadenceApp

test:
	swift test

lint:
	swift-format lint --recursive Sources Tests

format:
	swift-format format --in-place --recursive Sources Tests

verify:
	./scripts/verify.sh

clean:
	swift package clean
	rm -rf build .build
