SCRIPT_DIR=`pwd`
source "$SCRIPT_DIR/pathUtil.sh" || exit 1

# GZoltar Version
GZoltarVersion=1.7.3-SNAPSHOT
gzPath=/home/apr/apr_tools

# Absolute path of junit.jar
JUNIT_JAR=$gzPath/gzoltar/com.gzoltar.core/target/dependency/junit-4.12.jar
# Absolute path of hmacrest-core.jar
HAMCREST_JAR=$gzPath/gzoltar/com.gzoltar.core/target/dependency/hamcrest-core-1.3.jar
# Absolute path of com.gzoltar.cli-${GZoltarVersion}-jar-with-dependencies.jar
GZOLTAR_CLI_JAR=$gzPath/gzoltar/com.gzoltar.cli/target/com.gzoltar.cli-${GZoltarVersion}-jar-with-dependencies.jar
# Absolute path of com.gzoltar.agent.rt-${GZoltarVersion}-all.jar
GZOLTAR_AGENT_JAR=$gzPath/gzoltar/com.gzoltar.agent.rt/target/com.gzoltar.agent.rt-${GZoltarVersion}-all.jar

# dep
# /mnt/benchmarks/repairDir/Kali_Defects4J_Closure_18/build/classes:/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_18/build/test:
#deps=/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_18/build/lib/rhino.jar:/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_18/lib/args4j.jar:/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_18/lib/junit.jar:/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_18/lib/json.jar:/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_18/lib/ant-launcher.jar:/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_18/lib/jarjar.jar:/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_18/lib/jsr305.jar:/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_18/lib/protobuf-java.jar:/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_18/lib/ant.jar:/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_18/lib/guava.jar:/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_18/lib/caja-r4314.jar:/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_18/lib/rhino/testsrc/org/mozilla/javascript/tests/commonjs/module/modules.jar:/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_18/src/
depJunit=/home/apr/env/mavenDownload/junit/junit/4.11/junit-4.11.jar

# closure 103
#/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_103/build/classes:/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_103/build/test:
#/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_103/src/ 
deps=/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_103/lib/junit4-legacy.jar:/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_103/lib/protobuf_deploy.jar:/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_103/lib/google_common_deploy.jar:/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_103/lib/ant_deploy.jar:/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_103/lib/junit4-core.jar:/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_103/lib/libtrunk_rhino_parser_jarjared.jar:/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_103/lib/hamcrest-core-1.1.jar
#/mnt/benchmarks/repairDir/Kali_Defects4J_Closure_18/lib/junit.jar

pid="$1"       # Project name
bid="$2"       # bug id



# Output path of fault localization results.
output_dir="/home/apr/apr_tools/FL-VS-APR/FaultLocalization/GZoltar-1.7.3/result/${pid}-${bid}"

bug_dir="./$pid/${pid}_${bid}" # bug directory

mkdir -p $output_dir
test_classpath="$bug_dir$(_get_test_classpath $pid $bid)"
src_classes_dir="$bug_dir$(_get_src_classpath $pid $bid)"

echo "test_classpath: $test_classpath"
echo "src_classes_dir: $src_classes_dir"

tool="developer"                      # <developer|evosuite|randoop>
unit_tests_file="$output_dir/tests.txt" # all test methods.
ser_file="$output_dir/gzoltar.ser"

<<C1
java -cp $src_classes_dir:$test_classpath:$JUNIT_JAR:$HAMCREST_JAR:$GZOLTAR_CLI_JAR \
  com.gzoltar.cli.Main listTestMethods $test_classpath \
    --outputFile "$unit_tests_file"
C1

#<<C2
echo "using depJunit"

java -cp $src_classes_dir:$test_classpath:$depJunit:$HAMCREST_JAR:$GZOLTAR_CLI_JAR:$deps \
  com.gzoltar.cli.Main listTestMethods $test_classpath \
    --outputFile "$unit_tests_file"

#exit

D4J_DIR=/mnt/recursive-repairthemall/RepairThemAll/benchmarks/defects4j
cat "$D4J_DIR/framework/projects/Closure/loaded_classes/103.src" | sed 's/$/:/' | sed ':a;N;$!ba;s/\n//g'    > "./classes.txt"
#cat "$D4J_DIR/framework/projects/Closure/loaded_classes/103.src" | sed 's/$/$*:/' | sed ':a;N;$!ba;s/\n//g' >> "./classes.txt"
classes_to_debug=$(cat "./classes.txt")

#java -XX:MaxPermSize=4096M -javaagent:/home/apr/apr_tools/nopol-new/nopol/nopol/lib/GZoltar/com.gzoltar.agent.rt-1.7.3-SNAPSHOT-all.jar=destfile=/mnt/workingDir/Nopol_Defects4J_Closure_1/src/../gzBuild/gzoltar.ser,buildlocation=/mnt/workingDir/Nopol_Defects4J_Closure_1/src/../gzBuild,includes=$classes_to_debug,excludes="",inclnolocationclasses=false,output="FILE"
echo "[INFO] Start: $(date)" >&2
    (cd "$tmp_dir" > /dev/null 2>&1 && \
      java -XX:MaxPermSize=4096M -javaagent:$GZOLTAR_AGENT_JAR=destfile=$ser_file,buildlocation=$src_classes_dir,includes=$classes_to_debug,excludes="",inclnolocationclasses=false,output="FILE" \
        -cp $src_classes_dir:$JUNIT_JAR:$test_classpath:$GZOLTAR_CLI_JAR:$deps \
        com.gzoltar.cli.Main runTestMethods \
          --testMethods "$unit_tests_file" \
          --collectCoverage)
if [ $? -ne 0 ]; then
  echo "[ERROR] GZoltar runTestMethods command has failed for $pid-${bid}b version!" >&2
  # rm -rf "$tmp_dir"
fi

# backup
<<C2
echo "[INFO] Start: $(date)" >&2
    (cd "$tmp_dir" > /dev/null 2>&1 && \
      java -XX:MaxPermSize=4096M -javaagent:$GZOLTAR_AGENT_JAR=destfile=$ser_file,buildlocation=$src_classes_dir,inclnolocationclasses=false,output="FILE" \
        -cp $src_classes_dir:$JUNIT_JAR:$test_classpath:$GZOLTAR_CLI_JAR:$deps \
        com.gzoltar.cli.Main runTestMethods \
          --testMethods "$unit_tests_file" \
          --collectCoverage)
if [ $? -ne 0 ]; then
  echo "[ERROR] GZoltar runTestMethods command has failed for $pid-${bid}b version!" >&2
  # rm -rf "$tmp_dir"
fi
C2


[ -s "$ser_file" ] || die "[ERROR] $ser_file does not exist or it is empty!"

spectra_file="$output_dir/sfl/txt/spectra.csv"
matrix_file="$output_dir/sfl/txt/matrix.txt"
tests_file="$output_dir/sfl/txt/tests.csv"

java -XX:MaxPermSize=4096M -cp $src_classes_dir:$JUNIT_JAR:$test_classpath:$GZOLTAR_CLI_JAR \
      com.gzoltar.cli.Main faultLocalizationReport \
        --buildLocation "$src_classes_dir" \
        --granularity "line" \
        --inclPublicMethods \
        --inclStaticConstructors \
        --inclDeprecatedMethods \
        --dataFile "$ser_file" \
        --outputDirectory "$output_dir" \
        --family "sfl" \
        --formula "ochiai" \
        --metric "entropy" \
        --formatter "txt"
if [ $? -ne 0 ]; then
  echo "[ERROR] GZoltar faultLocalizationReport command has failed for $pid-${bid}b version!" >&2
  # rm -rf "$tmp_dir"
fi
echo "[INFO] End: $(date)" >&2
#rm -rf $ser_file

if [ -s "$matrix_file" ]; then
  mv $spectra_file "$output_dir/sfl_spectra.csv"
  mv $matrix_file "$output_dir/sfl_matrix.txt"
  mv $tests_file "$output_dir/sfl_tests.csv"
  mv $output_dir/sfl/txt/ochiai.ranking.csv $output_dir/sfl_ochiai_ranking.csv
  mv $output_dir/sfl/txt/statistics.csv $output_dir/sfl_statistics.csv
fi

rm -rf $output_dir/sfl/

echo "DONE!"

