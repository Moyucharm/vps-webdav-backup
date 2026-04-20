.PHONY: install uninstall test clean

PREFIX ?= /usr/local
CONFIG_DIR ?= /etc
SYSTEMD_DIR ?= /etc/systemd/system

SCRIPT_NAME = vps-webdav-backup

install:
	@echo "Installing $(SCRIPT_NAME)..."
	install -m 755 src/$(SCRIPT_NAME).sh $(PREFIX)/bin/
	install -m 644 src/$(SCRIPT_NAME).conf $(CONFIG_DIR)/
	install -m 644 systemd/$(SCRIPT_NAME).service $(SYSTEMD_DIR)/
	install -m 644 systemd/$(SCRIPT_NAME).timer $(SYSTEMD_DIR)/
	@echo ""
	@echo "Installation complete!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Edit configuration: sudo nano $(CONFIG_DIR)/$(SCRIPT_NAME).conf"
	@echo "  2. Enable timer:      sudo systemctl enable --now $(SCRIPT_NAME).timer"
	@echo "  3. Test backup:       sudo systemctl start $(SCRIPT_NAME).service"
	@echo ""

uninstall:
	@echo "Uninstalling $(SCRIPT_NAME)..."
	-systemctl stop $(SCRIPT_NAME).timer 2>/dev/null || true
	-systemctl disable $(SCRIPT_NAME).timer 2>/dev/null || true
	rm -f $(PREFIX)/bin/$(SCRIPT_NAME).sh
	rm -f $(CONFIG_DIR)/$(SCRIPT_NAME).conf
	rm -f $(SYSTEMD_DIR)/$(SCRIPT_NAME).service
	rm -f $(SYSTEMD_DIR)/$(SCRIPT_NAME).timer
	systemctl daemon-reload
	@echo "Uninstallation complete!"

test:
	@echo "Running backup test..."
	systemctl start $(SCRIPT_NAME).service
	journalctl -u $(SCRIPT_NAME).service -f

clean:
	@echo "Nothing to clean."