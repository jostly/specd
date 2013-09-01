module specd.mustmatchers;

import specd.specd;

import std.conv, std.string;

version(SpecDTests) unittest {

	describe("must matching").should([		
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
		},
		"match a range with between": {
			1.must.be.between(1,3);
			2.must.be.between(1,3);
			3.must.be.between(1,3);
			4.must.not.be.between(1,3);
			0.must.not.be.between(1,3);
		},
		"match partial strings": {
			"frobozz".must.contain("oboz");
			"frobozz".must.not.contain("bracken");
		}
	]);
}

class MatchException : Exception {
	this(string s, string file = __FILE__, size_t line = __LINE__) {
		super(s, file, line);
	}
}


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
