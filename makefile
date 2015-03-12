all: dependencies

dependencies:
	pub get

analyze:
	@dartanalyzer --no-hints --fatal-warnings lib/phonio.dart

analyze-hints:
	@echo "! (dartanalyzer lib/phonio.dart | grep '^\[')" | bash

analyze-all: analyze analyze-hints
