test-compatibility:
	xcodebuild \
		-skipMacroValidation \
		-project Example/Example.xcodeproj \
		-scheme Compatibility \
		-destination generic/platform=iOS

format:
	find . \
		-path '*/Documentation.docc' -prune -o \
		-name '*.swift' \
		-not -path '*/.*' -print0 \
		| xargs -0 swift format --ignore-unparsable-files --in-place

.PHONY: format test-compatibility
