# Makefile for dns_speed_test_parallel.sh

SCRIPT = dns_speed_test_parallel.sh
CONF   = dns_servers.txt

BIN_DIR = /usr/local/bin
CONF_DIR = /etc/dns_test_speed

INSTALL_SCRIPT = $(BIN_DIR)/$(SCRIPT)
INSTALL_CONF   = $(CONF_DIR)/$(CONF)

.PHONY: all install uninstall sync-conf

all: help

help:
	@echo "Available targets:"
	@echo "  make install     - Install script to $(BIN_DIR) and config to $(CONF_DIR)"
	@echo "  make uninstall   - Remove installed script and config"
	@echo "  make sync-conf   - Merge $(CONF).bak into config files (deduplicated)"
	@echo "  make help        - Show this help message"

install:
	@echo "Installing..."
	install -Dm755 $(SCRIPT) $(INSTALL_SCRIPT)
	install -Dm644 $(CONF) $(INSTALL_CONF)
	@echo "Installed $(SCRIPT) to $(BIN_DIR)"
	@echo "Installed $(CONF) to $(CONF_DIR)"

uninstall:
	@echo "Uninstalling..."
	rm -f $(INSTALL_SCRIPT)
	rm -f $(INSTALL_CONF)
	@if [ -d "$(CONF_DIR)" ]; then rmdir --ignore-fail-on-non-empty $(CONF_DIR); fi
	@echo "Uninstalled successfully."

sync-conf:
	@echo "Syncing configuration..."
	@if [ -f "$(CONF).bak" ]; then \
		cat $(CONF).bak $(CONF) 2>/dev/null | sort -u > $(CONF).tmp && mv $(CONF).tmp $(CONF); \
		echo "Updated local $(CONF) without duplicates"; \
	fi
	@if [ -f "$(INSTALL_CONF)" ] && [ -f "$(CONF).bak" ]; then \
		cat $(CONF).bak $(INSTALL_CONF) | sort -u > $(INSTALL_CONF).tmp && mv $(INSTALL_CONF).tmp $(INSTALL_CONF); \
		echo "Updated system $(INSTALL_CONF) without duplicates"; \
	fi
