module specd.matchers;

import specd.specd;

import std.math;
import std.range;
import std.traits;
import std.stdio;
import std.conv, std.string;

version(SpecDTests) unittest {
	bool evaluated = false;
	int oneTimeCalculation() {
		evaluated = true;
		return 1;
	}

	describe("the must function")
		.should("wrap a lazy expression in a Match without evaluating it", {
			auto m = oneTimeCalculation().must();
			assert(evaluated == false);
			assert(m.match() == 1);
			assert(evaluated == true);
		})
	;

}

version(SpecDTests) unittest {
	import std.array;
	import std.format;
	auto a = 1;
	const(int) f() { return a; }
	describe("const(T)")
		.should("work with matchers", { f().must.equal(a); });

	string fmt(double d) {
	  auto w = appender!string();
	  formattedWrite(w, "%e", d);
	  return w.data;
	}

	double x = 1.0;
	double y =	1.0;
	double toleranceWeak = 0.00001;
	double toleranceStrict = 0.0000001;
	double z =	1.0 + 0.000001;
	describe(text("x and y (", fmt(x), ",", fmt(y), ")"))
	  .should("be approxEqual since they are equal", {
		  x.must.be.approxEqual(y, 0, 0);
		  x.must.approxEqual(y, 0, 0);
		});

	describe(text("x and z (", fmt(x), ",", fmt(z), ")"))
	  .should("be approxEqual", {
		  x.must.be.approxEqual(z, toleranceWeak, toleranceWeak);
		  x.must.approxEqual(z, toleranceWeak, toleranceWeak);
		});

	describe(text("at strict threshold x and z (", fmt(x), ",", fmt(z), ")"))
	  .should("*not* be approxEqual", {
		  x.must.not.be.approxEqual(z, toleranceStrict, toleranceStrict);
		  x.must.not.approxEqual(z, toleranceStrict, toleranceStrict);
		});

	describe("[x, y, z]")
	  .should("be approxEqual [z, y, x]", {
		  auto first = [x, y, z];
		  auto second = [z, y, x];
		  first.must.be.approxEqual(second, toleranceWeak, toleranceWeak);
		});

	describe("at strict threshold [x, y, z]")
	  .should("*not* be approxEqual [z, y, x]", {
		  [x, y, z].must.not.be
			.approxEqual([z, y, x], toleranceStrict, toleranceStrict);
		});

	describe("[x, x, x]")
	  .should("*not* be approxEqual [x, x]", {
		  [x, x, x].must.not.be
			.approxEqual([x, x], toleranceWeak, toleranceWeak);
		});
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

	describe("sameAs matching").should([
		"work on slices": {
			auto a = [1,2,3];
			auto b = a;
			b.must.be.sameAs(a);
		}, 
		"must fail on duplicate arrays": {
			auto a = [1,2,3];
			auto b = a.dup;
			b.must.not.be.sameAs(a);
			b.must.equal(a); 
		},
		"work on objects": {
			auto a = new Object();
			auto b = a;
			b.must.be.sameAs(a);
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
		this.dummyMatch = T.init;
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

	// Test for Object, so we can use the override flag properly
	static if (is(T == Object)) {		
		override bool opEquals(Object rhs) {
			equal(this, rhs);
			return true;
		}		
	} else {
		bool opEquals(T rhs) {
			equal(this, rhs);
			return true;
		}		
	}

    static if (isFloatingPoint!T) {
      bool approxEqual(T rhs, T maxRelDiff = 1e-2, T maxAbsDiff = 1e-5) {
		.approxEqual(this, rhs, maxRelDiff, maxAbsDiff);
		return true;
      }
    } else static if(isInputRange!T && isFloatingPoint!(ElementType!T)) {
      bool approxEqual(T rhs, ElementType!T maxRelDiff = 1e-2, ElementType!T maxAbsDiff = 1e-5) {
		.approxEqual(this, rhs, maxRelDiff, maxAbsDiff);
		return true;
      }
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



void sameAs(T, T1)(Match!T matcher, T1 expected)
	if (is(typeof(expected == matcher.dummyMatch) == bool))
{
	auto match = matcher.match();
	if ((expected is match) != matcher.isPositiveMatch)
		matcher.throwMatchException("Expected " ~ 
			(matcher.isPositiveMatch ? "" : "not ") ~
			"<" ~ text(expected) ~ "> but got <" ~ 
			text(match) ~ ">");
}



void approxEqual(T, T1, V)(Match!T matcher, T1 expected, V maxRelDiff, V maxAbsDiff)
  if (is(typeof(expected == matcher.dummyMatch) == bool))
{
	auto match = matcher.match();
	if ((std.math.approxEqual(expected, match, maxRelDiff, maxAbsDiff)) != matcher.isPositiveMatch)
		matcher.throwMatchException("Expected Approx " ~
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
