module specd.specd;

public import specd.mustmatchers;

import std.stdio;

version(SpecDTests) {
	void main() {
		reportAllSpecs();
	}
}

bool reportAllSpecs() {

	int successes = 0;
	int total = 0;
	foreach(spec; allSpecs) {
		spec.report(successes, total);
	}

	
	auto reportedResult = successes == total;
	writeln(Spec.colour(reportedResult),
		reportedResult ? "SUCCESS" : "FAILURE",
	 	" Failed: ", (total - successes), 
	 	" out of ", total,
	 	Spec.colourOff());

	return reportedResult;
}

auto describe(string title) {	
	auto spec = new Spec(title);
	allSpecs ~= spec;
	return spec;
}

private:

version(SpecDTests) unittest {


	int executionSequence = 0;
	int executionFlag = 0;
	bool executionRan = false;

	describe("A Specification with ordered parts").as(
		(it) { it.should("execute each part", (executionSequence++).must.equal(0)); },
		(it) { it.should("execute its parts in order", (executionSequence++).must.equal(1)); }
	);

	describe("A Specification with unordered parts").should([
		"execute each part": {
			executionFlag |= 1;
		},
		"execute its parts in any order": {
			executionFlag |= 2;
		}		
	])
	;

	assert(executionFlag == 3, "Did not execute all parts of the unordered specification");

	describe("A Specification with a single part")
		.should("execute the part", executionRan = true);

	assert(executionRan, "Did not execute the single specification");
}



Spec[] allSpecs;

class SpecResult {
	string test;
	MatchException exception;

	this(string test) {
		this.test = test;
		this.exception = null;
	}

	this(string test, MatchException exception) {
		this.test = test;
		this.exception = exception;
	}

	@property bool isSuccess() { return exception is null; }
}

class Spec {
	string title;
	SpecResult[] results;
	@property bool isSuccess() {
		foreach(result; results) {
			if (!result.isSuccess)
				return false;
		}
		return true;
	}

	this(string title) {
		this.title = title;
	}

	static string colour(bool success) {
		if (success)
			return "\x1b[32m";
		else
			return "\x1b[31m";
	}

	static string colourOff() {
		return "\x1b[39m";
	}

	void report(ref int successes, ref int total) {
		writeln(colour(isSuccess), title, " should", colourOff());
		foreach(result; results) {
			total++;
			writeln(colour(result.isSuccess), "  ", result.test, colourOff());
			if (result.isSuccess) {
				successes++;
			} else {
				writeln(result.exception);
			}
			
		}
	}

	void should(void delegate()[string] parts) {
		foreach (key, value; parts) {
			try {
				value();
				results ~= new SpecResult(key);
			} catch (MatchException e) {
				results ~= new SpecResult(key, e);
			}
		}
	}
	void as(void delegate(Spec it)[] parts ...) {			
		foreach(part; parts) {
			part(this);
		}
	}
	auto should(string text, lazy void test) {
		try {
			test();
			results ~= new SpecResult(text);
		} catch (MatchException e) {
			results ~= new SpecResult(text, e);
		}
		return this;
	}
	auto should(string text, void delegate(Spec it) test) {
		try {
			test(this);
			results ~= new SpecResult(text);
		} catch (MatchException e) {
			results ~= new SpecResult(text, e);
		}
		return this;
	}
}

