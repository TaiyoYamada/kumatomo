# SAM Build targets for Bref/Laravel

build-WebFunction:
	@echo "Building WebFunction..."
	cp -r . $(ARTIFACTS_DIR)
	# Optional: Remove files not needed in Lambda to reduce deployment size
	rm -rf $(ARTIFACTS_DIR)/tests
	rm -rf $(ARTIFACTS_DIR)/docker-compose.yml
	rm -rf $(ARTIFACTS_DIR)/Makefile
	rm -rf $(ARTIFACTS_DIR)/.git
	rm -rf $(ARTIFACTS_DIR)/.github

build-ArtisanFunction:
	@echo "Building ArtisanFunction..."
	cp -r . $(ARTIFACTS_DIR)
	rm -rf $(ARTIFACTS_DIR)/tests
	rm -rf $(ARTIFACTS_DIR)/docker-compose.yml
	rm -rf $(ARTIFACTS_DIR)/Makefile
	rm -rf $(ARTIFACTS_DIR)/.git
	rm -rf $(ARTIFACTS_DIR)/.github
