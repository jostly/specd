module specd.specification;

import specd.mustmatchers;

import std.stdio;

auto describe(string title) {	
	return new SpecificationGroup(title);
}

version(SpecDTests) unittest {

	int executionSequence = 0;
	int executionFlag = 0;
	bool executionRan = false;

	describe("A SpecificationGroup with ordered parts").as(
		(it) { it.should("execute each part", (executionSequence++).must.equal(0)); },
		(it) { it.should("execute its parts in order", (executionSequence++).must.equal(1)); }
	);

	describe("A SpecificationGroup with unordered parts").should([
		"execute each part": {
			executionFlag |= 1;
		},
		"execute its parts in any order": {
			executionFlag |= 2;
		}		
	])
	;

	assert(executionFlag == 3, "Did not execute all parts of the unordered SpecificationGroup");

	describe("A SpecificationGroup with a single part")
		.should("execute the part", executionRan = true);

	assert(executionRan, "Did not execute the single specification");
}

class Specification {
package:
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
public:
	@property bool isSuccess() { return exception is null; }
}

class SpecificationGroup {
package:
	alias Block = void delegate();
	alias ItBlock = void delegate(SpecificationGroup);

	static SpecificationGroup[] allSpecs;

	string title;
	Specification[] results;

	this(string title) {
		this.title = title;
		allSpecs ~= this;
	}

public:
	@property bool isSuccess() {
		foreach(result; results) {
			if (!result.isSuccess)
				return false;
		}
		return true;
	}

	@property Specification[] specifications() { return results; }

	void as(ItBlock[] parts ...) {			
		foreach(part; parts) {
			part(this);
		}
	}

	auto should(Block[string] parts) {
		foreach (key, value; parts) {
			try {
				value();
				results ~= new Specification(key);
			} catch (MatchException e) {
				results ~= new Specification(key, e);
			}
		}
		return this;
	}
	auto should(string text, lazy void test) {
		try {
			test();
			results ~= new Specification(text);
		} catch (MatchException e) {
			results ~= new Specification(text, e);
		}
		return this;
	}
	auto should(string text, ItBlock test) {
		try {
			test(this);
			results ~= new Specification(text);
		} catch (MatchException e) {
			results ~= new Specification(text, e);
		}
		return this;
	}
}
