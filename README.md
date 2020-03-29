## fault localizer

This script is modified from https://github.com/GZoltar/gzoltar/blob/master/com.gzoltar.cli.examples/run.sh & https://github.com/SerVal-DTF/FL-VS-APR/blob/master/FaultLocalization/GZoltar-1.7.3/runGZoltar.sh



### An example

To run gzoltar for localizing the buggy lines of Closure_103:

1) download Closure_103:
`./single-download.sh Closure 103`

2) run gzoltar:
`./runGZoltar.sh Closure 103`

+ time cost: about 16 minutes
+ only one of the three buggy locs are localized.
`com.google.javascript.jscomp$ControlFlowAnalysis#mayThrowException(com.google.javascript.rhino.Node):894;0.015819299929208316`
(buggy locs of Closure_103 can be found at: http://program-repair.org/defects4j-dissection/#!/bug/Closure/103)
