PLATFORM_IOS = iOS Simulator,id=$(call udid_for,iOS 18.5,iPhone \d\+ Pro [^M])

warm-simulator:
	@test "$(PLATFORM_IOS)" != "" \
		&& xcrun simctl boot $(PLATFORM_ID) \
		&& open -a Simulator --args -CurrentDeviceUDID $(PLATFORM_IOS) \
		|| exit 0

test-compatibility: warm-simulator
	xcodebuild \
		-skipMacroValidation \
		-project Example/Example.xcodeproj \
		-scheme Compatibility \
		-destination generic/platform="$(PLATFORM_IOS)"

format:
	find . \
		-path '*/Documentation.docc' -prune -o \
		-name '*.swift' \
		-not -path '*/.*' -print0 \
		| xargs -0 swift format --ignore-unparsable-files --in-place

.PHONY: format test-compatibility warm-simulator

define udid_for
$(shell xcrun simctl list devices available '$(1)' | grep '$(2)' | sort -r | head -1 | awk -F '[()]' '{ print $$(NF-3) }')
endef
