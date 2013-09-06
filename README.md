# specd

Write unit tests as specifications, not assertions.

	describe("a specifications DSL").as((it) {
		it.should("read as natural language", (so) {
			"DSL useage".must.contain("use");

		});
		it.should("not be clunky, therefore", "statements".must.not.equal("overly verbose"));
	});

	describe("specd")
		.should("be easy to use, yet expressive", 
			"user".must.not.be.between("rock", "hard place"))
	;

## Getting started

Write specifications in a unittest block:

	unittest {
		describe("a string")
			.should("have a length property", "foo".length.must.equal(3))
		;
	}

To automatically run the tests with reporting, compile with version /specrunner/:

	dmd /source/ -unittest -version=specrunner

or if you're using dub, create a configuration in package.json:

	"configurations": [
		{
			"name": "test",
			"versions": ["specrunner"],
			"targetType": "executable"
		}
	]

Compiling with /specrunner/ will add a simple main():

	version(specrunner) {
		int main() {
			return reportAllSpecs() ? 0 : 10;
		}
	}

If you prefer to activate it yourself, just call reportAllSpecs(). It returns true if
all tests succeded, false otherwise.

## Specifications

A specification describes something, and so you begin by writing

	describe("Unit under test")

Follow this with the actual specifications as chained method calls, like so:

	describe("Unit under test")
		.should("fulfill first requirement", (...test code...))
		.should("fulfill second requirement", (...test code...))
	;

### Test as lazy expression

This is the simplest test code, written as a lazy expression. It is suitable for tests
where setup is a oneliner, typically functional code or value objects:

	describe("A vector")
		.should("implement vector addition", (vector(1,2,3) + vector(4,5,6)).must.equal(vector(5,7,9)) )
	;

### Test as a delegate

When you need to do more test setup, writing a test as a delegate allows that:

	describe("A loop")
		.should("run through the loop the specified times", (when) {
			int n = 0;
			foreach(i; 0..10) {
				n++;
			}

			n.must.equal(10);

		})
	;

### Tests as an associative array of delegates

Instead of chaining calls to should, you can use an associative array describing tests:

	describe("must matching").should([		
		"work on string": {
			"foo".must.equal("foo");
		},
		"work on int": {
			2.must.equal(2);
		},
		"work on double": {
			1.3.must.equal(1.3);		
		}
	]);

Note that these tests are executed in an unspecified order. If order is important, use should
chaining or the ordered array described below.

### Tests as an ordered array of delegates

When the execution order of tests is important, and you want to avoid should chaining, you can 
write the tests as an array of delegates. Each delegate takes an argument to the specification
chain, allowing you to write them like:

	describe("A Specification with ordered parts").as(
		(it) { it.should("execute each part", (executionSequence++).must.equal(0)); },
		(it) { it.should("execute its parts in order", (executionSequence++).must.equal(1)); }
	);


## Matchers

You can write tests using assert(), but that will terminate the test run on the first error. It is 
instead suggested to use the matchers provided by specd, written on the form

	a.must.equal(b);

If the arguments do not match, a MatchException is thrown.

### Equal matches

Any pair of types that can be compared for equality can be used in an equal match. For example, these
matches pass.

	"foo".must.equal("foo");
	1.must.equal(1.0);
	[1, 2, 3].must.equal([1f, 2f, 3f]);

Another way of expressing this is:

	"foo".must == "foo";
	"bar".must.not == "foo";

They are functionally equivalent.

### Comparison matches

Any pair of types that can be compared against each other (>, >=, <, <=) can be used in a comparison match:

	1.must.be.greater_than(0);
	"foo".must.not.be.less_than_or_equal_to("bar");

If these are too wordy for your taste, you can use the alternative shorter form:

	1.must.be_!"<" (2);

Note the underscore, which is there to avoid a conflict with the no-args be(), and also to make the whole
line a little more readable. The two forms are functionally equivalent, and are reported the same way,
using words for the operator.

### Range matches

Any types that can be compared for less than and greater than can be compared for a range:

	12.must.be.between(1, 15);
	"c".must.be.between("a", "d");
	2.must.between(2,3);

The "be" is optional sugar to make the statement read better - it has no impact on functionality when
used like that.

### Contain matches

Any type where indexOf(A, B) is valid can be used to check for containment:

	[1,2,3].must.contain(2);
	"foo".must.contain("oo");

### Negating matches

Any match can be negated using not:

	1.must.not.equal(2);
	"foo".must.not.contain("bar");

### Approximate matches

Floating point values can be compared with a variable precision, since absolute equality is often
difficult to achieve for non-integer values:

	sqrt(2).must.approximate(1.4142, 0.0001);

The second argument is the maximum variance. The above is exactly equivalent to writing:

	sqrt(2).must.be.between(1.4142-0.0001, 1.4142+0.0001);

### Matching boolean values

Matching boolean values can be done with equals, but if you prefer, there is an alternative syntax:

	bool a = true;
	a.must.equal(true);
	a.must.be.True;
	a.must.not.be.False;

### Matching null values

Any type that can be null can be matched for null:

	somePointer.must.not.be.Null;
	someObjectReference.must.be.Null;

Note that you cannot use equals when testing for null, since testing for equality to null is not valid D.

### Matching (not) thrown exceptions

You can match on an expression throwing or not throwing an exception:

	something().must.throw_!SomeException;
	something().must.not.throw_!SomeOtherException;

The above works when the expression on the left returns a value. If the return type is void, you must wrap
it in calling():

	calling( somethingReturningVoid() ).must.throw_!SomeOtherException;

## Writing custom matchers

Extending with custom matchers is as simple as defining new functions which take a Matcher as the first
argument. D will rewrite a call to matcher.foo(...) to a call to your function void foo(matcher, ...)

Look at the matchers supplied in matcher.d for an example on how to write them.



