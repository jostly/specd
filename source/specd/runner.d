module specd.runner;

import specd.reporter;

import core.runtime;

import std.stdio;

version(specrunner) {
	bool runner() {

		foreach( m; ModuleInfo )
        {
            if( m )
            {
                auto fp = m.unitTest;

                if( fp )
                {
                    fp();
                }
            }
        }

		auto reporter = new ConsoleReporter();

		bool completeSuccess = reporter.report();

		return completeSuccess;		
	}

	static this() {
		Runtime.moduleUnitTester(&runner);
	}

	
}