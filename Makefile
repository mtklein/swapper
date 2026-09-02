PREFIX ?= $(HOME)/.local
BIN = $(PREFIX)/bin/swapper

.PHONY: build install link uninstall

build:
	swift build -c release

# Build, copy the binary, create example scripts if absent, and start the launchd agent.
install: build
	install -d $(PREFIX)/bin
	install .build/release/swapper $(BIN)
	$(BIN) init
	$(BIN) install

# Symlink the scripts tracked in this repo into ~/.config/swapper.
link:
	install -d $(HOME)/.config/swapper
	ln -sf $(CURDIR)/docked.sh $(CURDIR)/mobile.sh $(HOME)/.config/swapper/

uninstall:
	-$(BIN) uninstall
	rm -f $(BIN)
