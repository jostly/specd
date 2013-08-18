module specd;

import std.stdio, std.conv, std.string;

auto describe(string title) {
	struct Spec {

		void should(void delegate()[string] parts) {
			foreach (key, value; parts) {
				writeln("  ", key);
				value();
			}
		}
		void as(void delegate(Spec it)[] parts ...) {			
			foreach(part; parts) {
				part(this);
			}
		}
		auto should(string text, lazy void test) {
			writeln("  ", text);
			test();
			return this;
		}
		auto should(string text, void delegate(Spec it) test) {
			writeln("  ", text);
			test(this);
			return this;
		}
	}
	writeln(title, " should");

	return new Spec;
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

		// Sugar
		auto not() {
			expectedComparison = !expectedComparison;
			return this;
		}
		auto be() {
			return this;
		}

	}

	return new MatchStatement!(T);
}
