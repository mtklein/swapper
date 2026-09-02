PREFIX ?= $(HOME)/.local
BIN = $(PREFIX)/bin/swapper

.PHONY: build test install uninstall

build:
	swift build -c release

test:
	swift test

# Build, copy the binary, create example scripts if absent, and start the launchd agent.
install: build
	install -d $(PREFIX)/bin
	install .build/release/swapper $(BIN)
	$(BIN) init
	$(BIN) install

uninstall:
	-$(BIN) uninstall
	rm -f $(BIN)
