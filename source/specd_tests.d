import specd;

unittest {
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

unittest {
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