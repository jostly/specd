// D import file generated from 'source/specd.d'
module specd;
import std.stdio;
import std.conv;
import std.string;
auto describe(string title)
{
	struct Spec
	{
		void should(void delegate()[string] parts);
		void as(void delegate(Spec it)[] parts...);
		void should(string text, lazy void test);
		void should(string text, void delegate() test);
	}
	return new Spec;
}

class MatchException : Exception
{
	this(string s, string file = __FILE__, size_t line = __LINE__);
}
template must(T)
{
	auto must(T match, string file = __FILE__, size_t line = __LINE__)
	{
		template MatchStatement(T)
		{
			struct MatchStatement
			{
				bool expectedComparison = true;
				template equal(T1) if (is(typeof(expected == match) == bool))
				{
					void equal(T1 expected)
					{
						if ((expected == match) != expectedComparison)
							throw new MatchException("Expected <" ~ text(expected) ~ "> but got <" ~ text(match) ~ ">", file, line);
					}

				}
				template between(T1) if (is(typeof(match >= first) == bool))
				{
					void between(T1 first, T1 last)
					{
						bool inrange = match >= first && match <= last;
						if (inrange != expectedComparison)
							throw new MatchException("Expected something between <" ~ text(first) ~ "> and <" ~ text(last) ~ "> but got <" ~ text(match) ~ ">", file, line);
					}

				}
				template contain(T1) if (is(typeof(indexOf(match, fragment) != -1) == bool))
				{
					void contain(T1 fragment)
					{
						bool contains = indexOf(match, fragment) != -1;
						if (contains != expectedComparison)
							throw new MatchException("Expected <" ~ text(match) ~ "> to contain <" ~ text(fragment) ~ ">", file, line);
					}

				}
				auto not()
				{
					expectedComparison = !expectedComparison;
					return this;
				}

				auto be()
				{
					return this;
				}

			}
		}
		return new MatchStatement!(T);
	}

}
