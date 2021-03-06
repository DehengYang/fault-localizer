* [fault localizer](#fault-localizer)
  * [An example for running runGZoltar\.sh](#an-example-for-running-rungzoltarsh)
    * [Summarized problems](#summarized-problems)
    * [Replication steps](#replication-steps)
  * [running runGZoltar\-closure\-1\.sh](#running-rungzoltar-closure-1sh)
    * [Summarized Problems](#summarized-problems-1)



## fault localizer 

This script is written based on two repos: 
+ https://github.com/GZoltar/gzoltar/blob/master/com.gzoltar.cli.examples/run.sh
+ https://github.com/SerVal-DTF/FL-VS-APR/blob/master/FaultLocalization/GZoltar-1.7.3/runGZoltar.sh

### An example for running runGZoltar.sh

To run gzoltar for localizing the buggy lines of **Closure_103**:

#### Summarized problems
+ `cat "$D4J_DIR/framework/projects/Closure/loaded_classes/103.src" | sed 's/$/$*:/' | sed ':a;N;$!ba;s/\n//g' >> "${output_dir}/classes.txt"` will cause error.
+ high time cost comparing against GZoltar v0.1.1
+ two of three buggy lines are not localized even considering subclass `com.google.javascript.jscomp.DisambiguateProperties$JSTypeSystem`

#### Replication steps
1) download Closure_103:
`./single-download.sh Closure 103`

2) run gzoltar:
`./runGZoltar.sh Closure 103`

3) data analysis:
+ the time cost of collecting coverage : 745 s
This is much longer than GZoltar v0.1.1 that cost no more than 2 minutes as I previously tried.

+ only one of the three buggy locs are localized.
```
com.google.javascript.jscomp$ControlFlowAnalysis#mayThrowException(com.google.javascript.rhino.Node):894;0.015819299929208316
```
(buggy locs of Closure_103 can be found at: http://program-repair.org/defects4j-dissection/#!/bug/Closure/103)
-> after including: `com.google.javascript.jscomp.DisambiguateProperties$JSTypeSystem`   (i.e., only consider this class) (`classes_to_debug="com.google.javascript.jscomp.DisambiguateProperties\$JSTypeSystem"`)
the time cost of collecting coverage is still kind of large: 656 s


+ `cat "$D4J_DIR/framework/projects/Closure/loaded_classes/103.src" | sed 's/$/$*:/' | sed ':a;N;$!ba;s/\n//g' >> "${output_dir}/classes.txt"` is commented as it will cause error:
```
* List all (JUnit/TestNG) unit test cases in a provided classpath.
[INFO] Start: Sun Mar 29 07:37:32 PDT 2020
Picked up JAVA_TOOL_OPTIONS: -Dfile.encoding=UTF8
Error: Could not find or load main class com.google.javascript.rhino.jstype.StringType$*:com.google.javascript.jscomp.MemoizedScopeCreator$*:com.google.javascript.jscomp.LightweightMessageFormatter$*:com.google.javascript.jscomp.ComposeWarningsGuard$*:com.google.javascript.rhino.FunctionNode$*:com.google.javascript.jscomp.TypeCheck$*:com.google.javascript.rhino.EvaluatorException$*:com.google.javascript.rhino.Node$*:com.google.javascript.jscomp.JSModule$*:com.google.javascript.jscomp.graph.StandardUnionFind$*:com.google.javascript.jscomp.LinkedFlowScope$*:com.google.javascript.rhino.jstype.NumberType$*:com.google.javascript.jscomp.PassConfig$*:com.google.javascript.rhino.jstype.PrototypeObjectType$*:com.google.javascript.jscomp.TypeInference$*:com.google.javascript.jscomp.Scope$*:com.google.javascript.jscomp.NodeTraversal$*:com.google.javascript.rhino.JSDocInfoBuilder$*:com.google.javascript.rhino.jstype.TemplateType$*:com.google.javascript.jscomp.JSSourceFile$*:com.google.javascript.jscomp.SourceFile$*:com.google.javascript.jscomp.parsing.TypeSafeDispatcher$*:com.google.javascript.rhino.ObjArray$*:com.google.javascript.rhino.jstype.JSTypeRegistry$*:com.google.javascript.jscomp.DefaultCodingConvention$*:com.google.javascript.jscomp.JSError$*:com.google.javascript.jscomp.parsing.Config$*:com.google.javascript.jscomp.ErrorFormat$*:com.google.javascript.rhino.ScriptRuntime$*:com.google.javascript.jscomp.DiagnosticType$*:com.google.javascript.jscomp.NodeUtil$*:com.google.javascript.jscomp.ChainableReverseAbstractInterpreter$*:com.google.javascript.jscomp.graph.DiGraph$*:com.google.javascript.rhino.jstype.ObjectType$*:com.google.javascript.jscomp.SourceAst$*:com.google.javascript.rhino.ObjToIntMap$*:com.google.javascript.rhino.jstype.FunctionType$*:com.google.javascript.jscomp.parsing.JsDocToken$*:com.google.javascript.jscomp.CheckUnreachableCode$*:com.google.javascript.jscomp.ScopeCreator$*:com.google.javascript.rhino.ScriptOrFnNode$*:com.google.javascript.jscomp.graph.GraphReachability$*:com.google.javascript.rhino.Token$*:com.google.javascript.jscomp.FunctionTypeBuilder$*:com.google.javascript.jscomp.CompilerOptions$*:com.google.javascript.jscomp.CodePrinter$*:com.google.javascript.jscomp.parsing.JsDocInfoParser$*:com.google.javascript.jscomp.graph.GraphvizGraph$*:com.google.javascript.jscomp.graph.LinkedDirectedGraph$*:com.google.javascript.jscomp.AbstractMessageFormatter$*:com.google.javascript.rhino.jstype.JSType$*:com.google.javascript.jscomp.Region$*:com.google.javascript.jscomp.CheckLevel$*:com.google.javascript.jscomp.parsing.ParserRunner$*:com.google.javascript.jscomp.DefaultPassConfig$*:com.google.javascript.jscomp.graph.SubGraph$*:com.google.javascript.rhino.jstype.NoType$*:com.google.javascript.jscomp.ControlFlowGraph$*:com.google.javascript.jscomp.AbstractCompiler$*:com.google.javascript.jscomp.ControlFlowAnalysis$*:com.google.javascript.rhino.jstype.UnionTypeBuilder$*:com.google.javascript.rhino.jstype.AllType$*:com.google.javascript.rhino.jstype.ValueType$*:com.google.javascript.rhino.TokenStream$*:com.google.javascript.jscomp.ProcessDefines$*:com.google.javascript.rhino.ErrorReporter$*:com.google.javascript.rhino.jstype.JSTypeNative$*:com.google.javascript.jscomp.CheckGlobalNames$*:com.google.javascript.jscomp.DiagnosticGroup$*:com.google.javascript.jscomp.CodeConsumer$*:com.google.javascript.rhino.jstype.StaticScope$*:com.google.javascript.jscomp.graph.Annotatable$*:com.google.javascript.jscomp.SemanticReverseAbstractInterpreter$*:com.google.javascript.jscomp.InferJSDocInfo$*:com.google.javascript.rhino.jstype.SimpleSlot$*:com.google.javascript.jscomp.DotFormatter$*:com.google.javascript.jscomp.TypeValidator$*:com.google.javascript.rhino.JSTypeExpression$*:com.google.javascript.jscomp.TightenTypes$*:com.google.javascript.jscomp.AnonymousFunctionNamingPolicy$*:com.google.javascript.rhino.jstype.NamedType$*:com.google.javascript.jscomp.ClosureCodingConvention$*:com.google.javascript.rhino.jstype.StaticSlot$*:com.google.javascript.jscomp.DisambiguateProperties$*:com.google.javascript.rhino.jstype.RecordType$*:com.google.javascript.jscomp.DataFlowAnalysis$*:com.google.javascript.jscomp.CheckAccessControls$*:com.google.javascript.jscomp.JSModuleGraph$*:com.google.javascript.rhino.JSDocInfo$*:com.google.javascript.jscomp.CodingConvention$*:com.google.javascript.jscomp.PropertyRenamingPolicy$*:com.google.javascript.jscomp.parsing.JsDocTokenStream$*:com.google.javascript.jscomp.CodeGenerator$*:com.google.javascript.jscomp.PassFactory$*:com.google.javascript.jscomp.TypedCodeGenerator$*:com.google.javascript.rhino.jstype.InstanceObjectType$*:com.google.javascript.jscomp.Compiler$*:com.google.javascript.rhino.RhinoException$*:com.google.javascript.jscomp.VarCheck$*:com.google.javascript.jscomp.DiagnosticGroupWarningsGuard$*:com.google.javascript.jscomp.graph.UnionFind$*:com.google.javascript.jscomp.MessageFormatter$*:com.google.javascript.jscomp.LoggerErrorManager$*:com.google.javascript.rhino.jstype.IndexedType$*:com.google.javascript.rhino.jstype.VoidType$*:com.google.javascript.jscomp.RhinoErrorReporter$*:com.google.javascript.jscomp.PotentialCheckManager$*:com.google.javascript.jscomp.graph.GraphNode$*:com.google.javascript.rhino.jstype.UnknownType$*:com.google.javascript.jscomp.JsAst$*:com.google.javascript.jscomp.TypedScopeCreator$*:com.google.javascript.jscomp.SyntacticScopeCreator$*:com.google.javascript.jscomp.parsing.Annotation$*:com.google.javascript.jscomp.CompilerPass$*:com.google.javascript.jscomp.graph.FixedPointGraphTraversal$*:com.google.javascript.rhino.EcmaError$*:com.google.javascript.jscomp.TypeInferencePass$*:com.google.javascript.rhino.jstype.EnumElementType$*:com.google.javascript.rhino.jstype.ErrorFunctionType$*:com.google.javascript.jscomp.NodeTypeNormalizer$*:com.google.javascript.rhino.jstype.NoObjectType$*:com.google.javascript.rhino.jstype.NullType$*:com.google.javascript.rhino.jstype.EnumType$*:com.google.javascript.jscomp.CodingConventionAnnotator$*:com.google.javascript.rhino.jstype.ArrowType$*:com.google.javascript.rhino.jstype.ProxyObjectType$*:com.google.javascript.jscomp.BasicErrorManager$*:com.google.javascript.jscomp.CreateSyntheticBlocks$*:com.google.javascript.jscomp.SourceExcerptProvider$*:com.google.javascript.rhino.jstype.ParameterizedType$*:com.google.javascript.jscomp.FlowScope$*:com.google.javascript.jscomp.graph.Annotation$*:com.google.javascript.jscomp.ReverseAbstractInterpreter$*:com.google.javascript.jscomp.CombinedCompilerPass$*:com.google.javascript.jscomp.Tracer$*:com.google.javascript.rhino.jstype.FunctionParamBuilder$*:com.google.javascript.jscomp.SymbolTable$*:com.google.javascript.rhino.Context$*:com.google.javascript.jscomp.DiagnosticGroups$*:com.google.javascript.rhino.jstype.Visitor$*:com.google.javascript.rhino.jstype.BooleanType$*:com.google.javascript.rhino.jstype.FunctionPrototypeType$*:com.google.javascript.jscomp.GoogleCodingConvention$*:com.google.javascript.rhino.jstype.UnionType$*:com.google.javascript.jscomp.parsing.IRFactory$*:com.google.javascript.jscomp.ConcreteType$*:com.google.javascript.jscomp.graph.AdjacencyGraph$*:com.google.javascript.jscomp.WarningsGuard$*:com.google.javascript.jscomp.ErrorManager$*:com.google.javascript.jscomp.graph.Graph$*:com.google.javascript.jscomp.CodeChangeHandler$*:com.google.javascript.jscomp.CompilerInput$*:com.google.javascript.jscomp.VariableRenamingPolicy$*:,excludes=,inclnolocationclasses=false,output=FILE
[ERROR] GZoltar runTestMethods command has failed for Closure-103b version!
```

### running runGZoltar-closure-1.sh

This is for fault localization of Closure 1.

The time cost of collecting coverage: 189 s (This is much less time-consuming than before)

#### Summarized Problems
+ Many `initializationError` tests in [sfl_tests.csv](./result/Closure-1/sfl_tests.csv)
This is due to the 35 `JUNIT,<test_name>#initializationError` in [tests.txt](./result/Closure-1/tests.txt) (maybe that's why the time cost is not so high, as many tests are not found and executed)



