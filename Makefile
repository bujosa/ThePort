APP_NAME = ThePort
WORKSPACE = $(APP_NAME).xcworkspace
SCHEME = $(APP_NAME)-Workspace
BUILD_DIR = .build_output

.PHONY: install generate build run release dmg clean edit icons

install:
	tuist install

generate: install
	tuist generate --no-open

build: generate
	xcodebuild \
		-workspace $(WORKSPACE) \
		-scheme $(SCHEME) \
		-destination 'platform=macOS' \
		-derivedDataPath $(BUILD_DIR) \
		build

run: build
	@echo "Opening $(APP_NAME)..."
	open $(BUILD_DIR)/Build/Products/Debug/$(APP_NAME).app

release: generate
	xcodebuild \
		-workspace $(WORKSPACE) \
		-scheme $(SCHEME) \
		-destination 'platform=macOS' \
		-derivedDataPath $(BUILD_DIR) \
		-configuration Release \
		build

dmg: release
	@echo "Creating $(APP_NAME).dmg..."
	@mkdir -p executables
	@rm -rf .dmg_staging executables/$(APP_NAME).dmg
	@mkdir -p .dmg_staging
	@cp -r $(BUILD_DIR)/Build/Products/Release/$(APP_NAME).app .dmg_staging/
	@ln -s /Applications .dmg_staging/Applications
	@hdiutil create -volname "$(APP_NAME)" -srcfolder .dmg_staging -ov -format UDZO executables/$(APP_NAME).dmg
	@rm -rf .dmg_staging
	@echo "executables/$(APP_NAME).dmg created successfully"

clean:
	rm -rf $(BUILD_DIR) *.xcodeproj *.xcworkspace Derived/
	tuist clean

edit:
	tuist edit

icons:
	swift scripts/generate-icons.swift
