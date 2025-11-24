.PHONY: deps clean run debug-apk release-apk

FLUTTER ?= flutter

deps:
	$(FLUTTER) pub get

clean:
	$(FLUTTER) clean

run:
	$(FLUTTER) run

debug-apk:
	$(FLUTTER) build apk --debug

release-apk:
	$(FLUTTER) build apk --release
