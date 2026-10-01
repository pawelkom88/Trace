SCHEME = Trace
PROJECT = Trace.xcodeproj
ARCHIVE_PATH = build/Trace.xcarchive
EXPORT_PATH = build/export
EXPORT_PLIST = scripts/ExportOptions.plist

export:

archive:
	xcodebuild archive \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-archivePath $(ARCHIVE_PATH) \
		-destination 'generic/platform=iOS' \
		-allowProvisioningUpdates

validate:
	xcodebuild -validateArchive \
		-archivePath $(ARCHIVE_PATH) \
		-authenticationKeyPath "$(APP_STORE_CONNECT_API_KEY_PATH)" \
		-authenticationKeyID "$(APP_STORE_CONNECT_API_KEY_ID)" \
		-authenticationKeyIssuerID "$(APP_STORE_CONNECT_API_ISSUER_ID)"

upload:
	xcodebuild -uploadArchive \
		-archivePath $(ARCHIVE_PATH) \
		-authenticationKeyPath "$(APP_STORE_CONNECT_API_KEY_PATH)" \
		-authenticationKeyID "$(APP_STORE_CONNECT_API_KEY_ID)" \
		-authenticationKeyIssuerID "$(APP_STORE_CONNECT_API_ISSUER_ID)"

ship: archive validate upload

clean:
	rm -rf build/Trace.xcarchive build/export

version:
	@grep MARKETING_VERSION project.yml
	@grep CURRENT_PROJECT_VERSION project.yml
