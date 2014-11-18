module specd.runner;

import specd.reporter;
import core.runtime;

version(NoAutoSpecDRun) {}
else:
version(unittest) {
    shared static this() {
        Runtime.moduleUnitTester = function() {

            foreach( m; ModuleInfo ) {   
                if( m ) {
                    auto fp = m.unitTest;

                    if( fp ) {
                        fp();
                    }
                }
            }

            auto reporter = new ConsoleReporter();

            bool completeSuccess = reporter.report();

            return completeSuccess; 
        };
    }
}

