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

	describe("opEquals matching").should([
		"match == for basic types": {
			1.must == 1;
			1.must.not == 2;
		},
		"match == for objects": {
			Object a = new Object();
			Object b = new Object();
			a.must == a;
			a.must.not == b;			
		}
	]);


	describe("comparison matching").should([
		"match greater_than": {
			1.must.be.greater_than(0);
			1.must.not.be.greater_than(1);
			1.must.be_!">" (0);
		},
		"match greater_than_or_equal_to": {
			1.must.be.greater_than_or_equal_to(1);
			1.must.not.be.greater_than_or_equal_to(2);
		},
		"match less_than": {
			1.must.be.less_than(2);
			1.must.not.be.less_than(1);
		},
		"match less_than_or_equal_to": {
			1.must.be.less_than_or_equal_to(1);
			1.must.not.be.less_than_or_equal_to(0);
		}
	]);

	class TestException : Exception {
		this(string s) {
			super(s);
		}

	}

	int throwAnException() {
		throw new TestException("foo");
	}

	void throwAnExceptionAndReturnVoid() {
		throw new TestException("bar");
	}

	describe("Exception matching").should([
		"match when an exception is thrown": {
			throwAnException().must.throw_!TestException;
			1.must.not.throw_!TestException;
		},
		"work with void function calls": {
			calling(throwAnExceptionAndReturnVoid()).must.throw_!TestException;
		}
	]);
}

private struct Calling {};

Match!Calling calling(lazy void m, string file = __FILE__, size_t line = __LINE__) {
	return new Match!Calling({ m(); return Calling(); }, file, line);
}

auto must(T)(lazy T m, string file = __FILE__, size_t line = __LINE__) {
	static if (is(T : Match!Calling)) {
		return m(); // Allow the form calling(foo()).must.throw....
	} else {
		return new Match!T({ return m(); }, file, line);
	}	
}

class Match(T) {
	T delegate() match;
	// TODO I use this for comparing a generic type with the type of this Match. 
	// Might be a better way to do that.
	T dummyMatch;
	// Signal that the match is positive, ie it has not been negated with "not" in the chain
	// (or if it has, it has been negated again by a second "not")
	bool isPositiveMatch = true;
	string file;
	size_t line;

	this(T delegate() match, string file, size_t line) {
		this.match = match;
		this.file = file;
		this.line = line;
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
		void be(bool expected) {
			if (expected)
				True(this);
			else
				False(this);
		}
	}

	bool opEquals(T rhs) {
		equal(this, rhs);
		return true;
	}

	alias Object.opEquals opEquals;

	void throwMatchException(string reason) {
		throw new MatchException(reason, file, line);
	}
}


class MatchException : Exception {
	this(string s, string file = __FILE__, size_t line = __LINE__) {
		super(s, file, line);
	}
}


void equal(T, T1)(Match!T matcher, T1 expected)
	if (is(typeof(expected == matcher.dummyMatch) == bool))
{
	auto match = matcher.match();
	if ((expected == match) != matcher.isPositiveMatch)
		matcher.throwMatchException("Expected " ~ 
			(matcher.isPositiveMatch ? "" : "not ") ~
			"<" ~ text(expected) ~ "> but got <" ~ 
			text(match) ~ ">");
}

private string comparisonInWords(string op)() {
	if (op == "<")
		return "less than";
	else if (op == "<=")
		return "less than or equal to";
	else if (op == ">")
		return "greater than";
	else if (op == ">=")
		return "greater than or equal to";
	else
		return "*unknown operation*";
}

private void comparison(string op, T, T1)(Match!T matcher, T1 expected) {
	auto match = matcher.match();
	auto cmp = mixin("match " ~ op ~ " expected");
	if (cmp != matcher.isPositiveMatch)
		matcher.throwMatchException("Expected something " ~ 
			(matcher.isPositiveMatch ? "" : "not ") ~
			comparisonInWords!op ~
			" <" ~ text(expected) ~ "> but got <" ~ 
			text(match) ~ ">");

}

void greater_than(T, T1)(Match!T matcher, T1 expected)
	if (is(typeof(matcher.dummyMatch > expected) == bool))
{
	comparison!">"(matcher, expected);
}

void greater_than_or_equal_to(T, T1)(Match!T matcher, T1 expected)
	if (is(typeof(matcher.dummyMatch >= expected) == bool))
{
	comparison!">="(matcher, expected);
}

void less_than(T, T1)(Match!T matcher, T1 expected)
	if (is(typeof(matcher.dummyMatch < expected) == bool))
{
	comparison!"<"(matcher, expected);
}

void less_than_or_equal_to(T, T1)(Match!T matcher, T1 expected)
	if (is(typeof(matcher.dummyMatch <= expected) == bool))
{
	comparison!"<="(matcher, expected);
}

void be_(string op, T, T1)(Match!T matcher, T1 expected)
	if (is(typeof(matcher.dummyMatch > expected) == bool) &&
		(op == ">" || op == ">=" || op == "<" || op == "<="))
{
	comparison!op(matcher, expected);
}

void between(T, T1)(Match!T matcher, T1 first, T1 last) 
	if (is(typeof(matcher.dummyMatch >= first) == bool))
{
	auto match = matcher.match();
	bool inrange = (match >= first && match <= last);
	if (inrange != matcher.isPositiveMatch)
		matcher.throwMatchException("Expected something " ~
			(matcher.isPositiveMatch ? "" : "not ") ~
			"between <" ~ text(first) ~ "> and <" ~ text(last) ~ "> but got <" ~ text(match) ~ ">");
}
void contain(T, T1)(Match!T matcher, T1 fragment) 
	if (is(typeof(indexOf(matcher.dummyMatch, fragment) != -1) == bool))
{
	auto match = matcher.match();
	bool contains = indexOf(match, fragment) != -1;
	if (contains != matcher.isPositiveMatch)
		matcher.throwMatchException("Expected <" ~ text(match) ~ "> to " ~
			(matcher.isPositiveMatch ? "" : "not ") ~
			"contain <" ~ text(fragment) ~ ">");
}

void True(Match!bool matcher) {
	auto match = matcher.match();
	if (match != matcher.isPositiveMatch)
		matcher.throwMatchException("Expected <" ~
			(matcher.isPositiveMatch ? "true" : "false") ~
			"> but got <" ~
			text(match) ~ ">");
}

void False(Match!bool matcher) {
	auto match = matcher.match();
	if (match == matcher.isPositiveMatch)
		matcher.throwMatchException("Expected <" ~
			(matcher.isPositiveMatch ? "false" : "true") ~
			"> but got <" ~
			text(match) ~ ">");
}

void Null(T)(Match!T matcher)
	if (is(typeof(matcher.dummyMatch is null) == bool))
{
	auto match = matcher.match();
	bool isNull = match is null;
	if (isNull != matcher.isPositiveMatch)
		matcher.throwMatchException("Expected " ~
			(matcher.isPositiveMatch ? "" : "not ") ~
			"<null> but got <" ~
			text(match) ~ ">");

}	

void throw_(E, T)(Match!T matcher)
	if (is(E : Throwable))
{
	string exception = "";
	try {
		matcher.match();
		if (matcher.isPositiveMatch)
			exception = "Expected " ~
				E.stringof ~ " thrown, but nothing was thrown";

	} catch (E e) {
		if (!matcher.isPositiveMatch) 
			exception = "Expected no " ~
				E.stringof ~ " thrown, but got " ~ typeof(e).stringof;
	}

	if (exception != "")
		matcher.throwMatchException(exception);
}