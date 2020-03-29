die() {
  echo "$@" >&2
  exit 1
}


##### basic configuration
SCRIPT_DIR=`pwd`
source "$SCRIPT_DIR/pathUtil.sh" || exit 1

JUNIT_JAR=lib/junit-4.12.jar
HAMCREST_JAR=lib/hamcrest-core-1.3.jar

gz_version=1.7.3-SNAPSHOT

GZOLTAR_CLI_JAR=lib/com.gzoltar.cli-${gz_version}-jar-with-dependencies.jar
GZOLTAR_AGENT_JAR=lib/com.gzoltar.agent.rt-${gz_version}-all.jar


##### d4j bug configuration & not used at present
depJunit=/home/apr/env/mavenDownload/junit/junit/4.11/junit-4.11.jar


##### bug settings
pid="Clsoure"       # Project name
bid="1"       # bug id

bug_dir="./$pid/${pid}_${bid}" # bug directory

# closure 1
deps=${bug_dir}/build/lib/rhino.jar:${bug_dir}/lib/args4j.jar:${bug_dir}/lib/junit.jar:${bug_dir}/lib/json.jar:${bug_dir}/lib/ant-launcher.jar:${bug_dir}/lib/jarjar.jar:${bug_dir}/lib/jsr305.jar:${bug_dir}/lib/protobuf-java.jar:${bug_dir}/lib/ant.jar:${bug_dir}/lib/guava.jar:${bug_dir}/lib/caja-r4314.jar:${bug_dir}/lib/rhino/testsrc/org/mozilla/javascript/tests/commonjs/module/modules.jar

output_dir="result/${pid}-${bid}"
mkdir -p $output_dir
unit_tests_file="$output_dir/tests.txt" # all test methods.
ser_file="$output_dir/gzoltar.ser"

test_classpath="$bug_dir$(_get_test_classpath $pid $bid)"
src_classes_dir="$bug_dir$(_get_src_classpath $pid $bid)"

echo "test_classpath: $test_classpath"
echo "src_classes_dir: $src_classes_dir"

D4J_DIR=/mnt/recursive-repairthemall/RepairThemAll/benchmarks/defects4j

##### collect all tests
# :$deps
java -cp $src_classes_dir:$test_classpath:$JUNIT_JAR:$HAMCREST_JAR:$GZOLTAR_CLI_JAR \
  com.gzoltar.cli.Main listTestMethods $test_classpath \
    --outputFile "$unit_tests_file"

##### get classes to debug
cat "$D4J_DIR/framework/projects/$pid/loaded_classes/$bid.src" | sed 's/$/:/' | sed ':a;N;$!ba;s/\n//g'  >  "${output_dir}/classes.txt"
cat "$D4J_DIR/framework/projects/Closure/loaded_classes/103.src" | sed 's/$/$*:/' | sed ':a;N;$!ba;s/\n//g' >> "${output_dir}/classes.txt"
classes_to_debug=$(cat "${output_dir}/classes.txt")

##### collect test execution data (generate gzoltar.ser)
echo "${pid}_$bid" >> time.txt
startTime=$(date +%s)
echo "start time `date '+%Y%m%d %H%M%S'`"  >> time.txt
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

endTime=$(date +%s)
echo "end time `date '+%Y%m%d %H%M%S'`"  >> time.txt
repairTime=$(($endTime-$startTime))
echo -e "time cost: $repairTime s\n\n"  >> time.txt

[ -s "$ser_file" ] || die "[ERROR] $ser_file does not exist or it is empty!"



##### fl report
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

