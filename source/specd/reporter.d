module specd.reporter;

import specd.specd;

import std.stdio;

interface Reporter {

	void reportSpecificationGroup(SpecificationGroup group);

	void reportSpecification(Specification specification);

	void reportSummary(int totalNumberOfSpecs, int numberOfFailedSpecs);

	final bool report() {
		int total = 0;
		int failures = 0;
		foreach(specGroup; SpecificationGroup.allSpecs) {
			reportSpecificationGroup(specGroup);
			foreach(spec; specGroup.specifications) {
				++total;
				if (!spec.isSuccess) {
					++failures;
				}
				reportSpecification(spec);
			}
		}
		reportSummary(total, failures);
		return failures == 0;
	}
}

class ConsoleReporter : Reporter {
	override void reportSpecificationGroup(SpecificationGroup group) {
		writeln(mark(group.isSuccess), group.title, " should", markOff());
	}

	override void reportSpecification(Specification spec) {
		writeln(mark(spec.isSuccess), "  ", spec.test, markOff());
		if (!spec.isSuccess)
			writeln(spec.exception);
	}

	override void reportSummary(int totalNumberOfSpecs, int numberOfFailedSpecs) {
		auto success = numberOfFailedSpecs == 0;
		writeln(mark(success), success ? "SUCCESS" : "FAILURE",
			" Failed: ", numberOfFailedSpecs,
			" out of ", totalNumberOfSpecs,
			markOff());
	}

version(Posix) {
	string mark(bool success) {
		if (success)
			return "\x1b[32m";
		else
			return "\x1b[31m";
	}

	string markOff() {
		return "\x1b[39m";
	}		
} else {
	string mark(bool success) { return success ? "[ OK ] " : "[FAIL] "; }
	string markOff() { return ""; }
}

}
