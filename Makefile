format:
	find . \
		-path '*/Documentation.docc' -prune -o \
		-name '*.swift' \
		-not -path '*/.*' -print0 \
		| xargs -0 swift format --ignore-unparsable-files --in-place

.PHONY: format

