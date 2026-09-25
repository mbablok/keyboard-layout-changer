APP_NAME    := KeyboardLayoutChanger
BUILD_DIR   := build
APP         := $(BUILD_DIR)/$(APP_NAME).app
INSTALL_DIR ?= $(HOME)/Applications
# Build and test for the hardware's native architecture. When make itself runs under Rosetta,
# `uname -m` reports x86_64 and `swift test` loads xctest's x86_64 slice, silently skipping XCTest.
NATIVE_ARCH := $(shell [ "$$(sysctl -n hw.optional.arm64 2>/dev/null)" = 1 ] && echo arm64 || echo x86_64)
SWIFT       := arch -$(NATIVE_ARCH) swift

.PHONY: all test app install uninstall clean

all: app

test:
	$(SWIFT) test

app:
	$(SWIFT) build -c release --product $(APP_NAME)
	rm -rf "$(APP)"
	mkdir -p "$(APP)/Contents/MacOS"
	cp "$$($(SWIFT) build -c release --show-bin-path)/$(APP_NAME)" "$(APP)/Contents/MacOS/$(APP_NAME)"
	cp Resources/Info.plist "$(APP)/Contents/Info.plist"
	codesign --force --sign - "$(APP)"

install: app
	-pkill -x $(APP_NAME)
	mkdir -p "$(INSTALL_DIR)"
	rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	cp -R "$(APP)" "$(INSTALL_DIR)/"
	open "$(INSTALL_DIR)/$(APP_NAME).app"

uninstall:
	-pkill -x $(APP_NAME)
	rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"

clean:
	rm -rf .build "$(BUILD_DIR)"
