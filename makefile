all: dependencies

dependencies:
	pub get

analyze: dependencies
	@dartanalyzer --no-hints --fatal-warnings lib/phonio.dart example/*.dart

analyze-hints: dependencies
	@echo "! (dartanalyzer lib/phonio.dart example/*.dart | grep '^\[')" | bash

analyze-all: analyze analyze-hints
