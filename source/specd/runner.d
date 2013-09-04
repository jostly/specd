module specd.runner;

import specd.reporter;

version(specrunner) {
	int main() {
		auto reporter = new ConsoleReporter();

		bool completeSuccess = reporter.report();
		if (completeSuccess) {
			return 0;
		} else {
			return 10; // Indicate failures so scripts can check result of running unit tests
		}
	}
}