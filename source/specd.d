module specd;

import std.stdio, std.conv, std.string;

Spec[] allSpecs;

string colour(bool success) {
	if (success)
		return "\x1b[32m";
	else
		return "\x1b[31m";
}

string colourOff() {
	return "\x1b[39m";
}

private bool hasReported, reportedResult;

bool reportAllSpecs() {
	if (hasReported)
		return reportedResult;

	int successes = 0;
	int total = 0;
	foreach(spec; allSpecs) {
		spec.report(successes, total);
	}

	
	reportedResult = successes == total;
	writeln(colour(reportedResult),
		reportedResult ? "SUCCESS" : "FAILURE",
	 	" Failed: ", (total - successes), 
	 	" out of ", total,
	 	colourOff());

	hasReported = true;
	return reportedResult;
}

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


auto describe(string title) {
	
	auto spec = new Spec(title);
	allSpecs ~= spec;
	return spec;
}

class MatchException : Exception {
	this(string s, string file = __FILE__, size_t line = __LINE__) {
		super(s, file, line);
	}
}

/* TODO Maybe later?
interface Matcher {
	bool matches(B)(B candidate);
}

class EqualMatcher(A) : Matcher {
	A _expected;
	string _file;
	size_t _line;
	this(A expected, string file, size_t line) {
		_expected = expected;
		_file = file;
		_line = line;
	}

	bool matches(B)(B candidate) 
		if (is(typeof(candidate == expected) == bool))
	{
		return candidate == expected;
	}
}

auto equal(T)(T expected, string file = __FILE__, size_t line = __LINE__) {
	return new EqualMatcher(expected, file, line);
}
*/


auto must(T)(T match, string file = __FILE__, size_t line = __LINE__) {

	struct MatchStatement(T) {
		bool expectedComparison = true;

		// Matching
		void approximate(T1,T2)(T1 expected, T2 delta)
			if (is(typeof(expected == (match+delta)) == bool))
		{
			bool inrange = (match >= (expected-delta) && match <= (expected+delta));
			if (inrange != expectedComparison)
				throw new MatchException("Expected " ~ 
					(expectedComparison ? "" : "not ") ~
					"approximately <" ~ text(expected) ~ "> (+/- " ~ text(delta) ~ "), but got <" ~ 
					text(match) ~ ">", file, line);

		}
		void equal(T1)(T1 expected) 
			if (is(typeof(expected == match) == bool))
		{
			if ((expected == match) != expectedComparison)
				throw new MatchException("Expected " ~ 
					(expectedComparison ? "" : "not ") ~
					"<" ~ text(expected) ~ "> but got <" ~ 
					text(match) ~ ">", file, line);
		}
		void between(T1)(T1 first, T1 last) 
			if (is(typeof(match >= first) == bool))
		{
			bool inrange = (match >= first && match <= last);
			if (inrange != expectedComparison)
				throw new MatchException("Expected something " ~
					(expectedComparison ? "" : "not ") ~
					"between <" ~ text(first) ~ "> and <" ~ text(last) ~ "> but got <" ~ text(match) ~ ">", file, line);
		}
		void contain(T1)(T1 fragment) 
			if (is(typeof(indexOf(match, fragment) != -1) == bool))
		{
			bool contains = indexOf(match, fragment) != -1;
			if (contains != expectedComparison)
				throw new MatchException("Expected <" ~ text(match) ~ "> to " ~
					(expectedComparison ? "" : "not ") ~
					"contain <" ~ text(fragment) ~ ">", file, line);
		}

		static if (is(typeof(match is null) == bool)) {
			void Null() {
				bool isNull = match is null;
				if (isNull != expectedComparison)
					throw new MatchException("Expected " ~
						(expectedComparison ? "" : "not ") ~
						"<null> but got <" ~
						text(match) ~ ">", file, line);
			}
		} 

		static if (is(typeof(match == true) == bool)) {
			void True() {
				if (match != expectedComparison)
					throw new MatchException("Expected <" ~
						(expectedComparison ? "true" : "false") ~
						"> but got <" ~
						text(match) ~ ">", file, line);
			}
			void False() {
				if (match == expectedComparison)
					throw new MatchException("Expected <" ~
						(expectedComparison ? "false" : "true") ~
						"> but got <" ~
						text(match) ~ ">", file, line);
			}

			void be(bool expected) {
				if (expected)
					True();
				else
					False();
			}

		} 


		// Negate
		auto not() {
			expectedComparison = !expectedComparison;
			return this;
		}

		// Sugar
		auto be() {
			return this;
		}

	}

	return new MatchStatement!(T);
}
