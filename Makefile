CONFIG = debug
PLATFORM_IOS = iOS Simulator,id=$(call udid_for,iOS 17.2,iPhone \d\+ Pro [^M])

format:
	find . \
		-path '*/Documentation.docc' -prune -o \
		-name '*.swift' \
		-not -path '*/.*' -print0 \
		| xargs -0 swift format --ignore-unparsable-files --in-place

test-compatibility:
	xcodebuild \
		-skipMacroValidation \
		-configuration $(CONFIG) \
		-scheme CompatibilityTests \
		-project Example/Example.xcodeproj \
		-destination generic/platform="$PLATFORM_IOS" || exit 1; 

.PHONY: format

define udid_for
$(shell xcrun simctl list devices available '$(1)' | grep '$(2)' | sort -r | head -1 | awk -F '[()]' '{ print $$(NF-3) }')
endef
