SRC = health-check.sh
BIN = health-check
INSTALL_PATH = /usr/local/bin
LOG_PATH = /var/log/system_crisis.log

install:
	@echo "Installing/Updating $(BIN)..."
	chmod +x $(SRC)
	cp -f $(SRC) $(INSTALL_PATH)/$(BIN)
	@touch $(LOG_PATH) 2>/dev/null || true
	@chmod 666 $(LOG_PATH) 2>/dev/null || true
	@echo "Done! Run it with: $(BIN)"

uninstall:
	@echo "Removing $(BIN)..."
	rm -f $(INSTALL_PATH)/$(BIN)
	@echo "Uninstallation complete."
