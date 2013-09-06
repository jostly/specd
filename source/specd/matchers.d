module specd.matchers;

import specd.specd;

import std.stdio;
import std.conv, std.string;

version(SpecDTests) unittest {
	bool evaluated = false;
	int oneTimeCalculation() {
		evaluated = true;
		return 1;
	}

	describe("the must function")
		.should("wrap a lazy expression in a Match without evaluating it", (when) {
			auto m = oneTimeCalculation().must();
			assert(evaluated == false);
			assert(m.match() == 1);
			assert(evaluated == true);
		})
	;

}

Match!T must(T)(lazy T m) {
	return new Match!T({ return m(); });
}

class Match(T) {
	T delegate() match;
	// TODO I use this for comparing a generic type with the type of this Match. 
	// Might be a better way to do that.
	T dummyMatch;
	// Signal that the match is positive, ie it has not been negated with "not" in the chain
	// (or if it has, it has been negated again by a second "not")
	bool isPositiveMatch = true;

	this(T delegate() match) {
		this.match = match;
	}

	// Negated match

	auto not() {
		isPositiveMatch = !isPositiveMatch;
		return this;
	}

	// Sugar
	auto be() {
		return this;
	}

	// Help for matching booleans
	static if (is(T == bool)) {
		void be(bool expected, string file = __FILE__, size_t line = __LINE__) {
			if (expected)
				True(this, file, line);
			else
				False(this, file, line);
		}
	}


}

version(SpecDTests) unittest {

	describe("equal matching").should([		
		"work on string": {
			"foo".must.equal("foo");
		},
		"work on int": {
			2.must.equal(2);
		},
		"work on double": {
			1.3.must.equal(1.3);		
		},
		"work on object": {
			auto a = new Object;
			a.must.equal(a);
		},
		"throw a MatchException if it doesn't match": {
			try {
				1.must.equal(2);
				assert(false, "Expected a MatchException");
			} catch (MatchException e) {				
			}
		},
		"invert matching with not": {
			2.must.not.equal(1);
		}
	]);

	describe("between matching").should([
		"match a range": {
			1.must.be.between(1,3);
			2.must.be.between(1,3);
			3.must.be.between(1,3);
			4.must.not.be.between(1,3);
			0.must.not.be.between(1,3);
		}
	]);

	describe("contain matching").should([
		"match partial strings": {
			"frobozz".must.contain("oboz");
			"frobozz".must.not.contain("bracken");
		}
	]);

	describe("boolean matching").should([
		"match on True": {
			true.must.be.True;
		},
		"match on False": {
			false.must.be.False;
		},
		"match using be(true)": {
			true.must.be(true);
		}
	]);

	describe("null matching").should([
		"match on Null": {
			Object a = null;
			Object b = new Object();
			a.must.be.Null;
			b.must.not.be.Null;
		}
	]);

}

class MatchException : Exception {
	this(string s, string file = __FILE__, size_t line = __LINE__) {
		super(s, file, line);
	}
}

// TODO create a helper function for MatchException reporting
void equal(T, T1)(Match!T matcher, T1 expected, string file = __FILE__, size_t line = __LINE__)
	if (is(typeof(expected == matcher.dummyMatch) == bool))
{
	auto match = matcher.match();
	if ((expected == match) != matcher.isPositiveMatch)
		throw new MatchException("Expected " ~ 
			(matcher.isPositiveMatch ? "" : "not ") ~
			"<" ~ text(expected) ~ "> but got <" ~ 
			text(match) ~ ">", file, line);
}

void between(T, T1)(Match!T matcher, T1 first, T1 last, string file = __FILE__, size_t line = __LINE__) 
	if (is(typeof(matcher.dummyMatch >= first) == bool))
{
	auto match = matcher.match();
	bool inrange = (match >= first && match <= last);
	if (inrange != matcher.isPositiveMatch)
		throw new MatchException("Expected something " ~
			(matcher.isPositiveMatch ? "" : "not ") ~
			"between <" ~ text(first) ~ "> and <" ~ text(last) ~ "> but got <" ~ text(match) ~ ">", file, line);
}
void contain(T, T1)(Match!T matcher, T1 fragment, string file = __FILE__, size_t line = __LINE__) 
	if (is(typeof(indexOf(matcher.dummyMatch, fragment) != -1) == bool))
{
	auto match = matcher.match();
	bool contains = indexOf(match, fragment) != -1;
	if (contains != matcher.isPositiveMatch)
		throw new MatchException("Expected <" ~ text(match) ~ "> to " ~
			(matcher.isPositiveMatch ? "" : "not ") ~
			"contain <" ~ text(fragment) ~ ">", file, line);
}

void True(Match!bool matcher, string file = __FILE__, size_t line = __LINE__) {
	auto match = matcher.match();
	if (match != matcher.isPositiveMatch)
		throw new MatchException("Expected <" ~
			(matcher.isPositiveMatch ? "true" : "false") ~
			"> but got <" ~
			text(match) ~ ">", file, line);
}

void False(Match!bool matcher, string file = __FILE__, size_t line = __LINE__) {
	auto match = matcher.match();
	if (match == matcher.isPositiveMatch)
		throw new MatchException("Expected <" ~
			(matcher.isPositiveMatch ? "false" : "true") ~
			"> but got <" ~
			text(match) ~ ">", file, line);
}

void Null(T)(Match!T matcher, string file = __FILE__, size_t line = __LINE__)
	if (is(typeof(matcher.dummyMatch is null) == bool))
{
	auto match = matcher.match();
	bool isNull = match is null;
	if (isNull != matcher.isPositiveMatch)
		throw new MatchException("Expected " ~
			(matcher.isPositiveMatch ? "" : "not ") ~
			"<null> but got <" ~
			text(match) ~ ">", file, line);

}	