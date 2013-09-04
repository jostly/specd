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
		writeln(colour(group.isSuccess), group.title, " should", colourOff());
	}

	override void reportSpecification(Specification spec) {
		writeln(colour(spec.isSuccess), "  ", spec.test, colourOff());
		if (!spec.isSuccess)
			writeln(spec.exception);
	}

	override void reportSummary(int totalNumberOfSpecs, int numberOfFailedSpecs) {
		auto success = numberOfFailedSpecs == 0;
		writeln(colour(success), success ? "SUCCESS" : "FAILURE",
			" Failed: ", numberOfFailedSpecs,
			" out of ", totalNumberOfSpecs,
			colourOff());
	}

	string colour(bool success) {
		if (success)
			return "\x1b[32m";
		else
			return "\x1b[31m";
	}

	string colourOff() {
		return "\x1b[39m";
	}	
}
