#!/bin/bash


####!/usr/bin/env bash

PWD=$(cd `dirname ${BASH_SOURCE[0]}` && pwd)

export MALLOC_ARENA_MAX=1 # Iceberg's requirement
export TZ='America/Los_Angeles' # some D4J's requires this specific TimeZone

export _JAVA_OPTIONS="-Xmx6144M -XX:MaxHeapSize=2048M"
export MAVEN_OPTS="-Xmx1024M"
export ANT_OPTS="-Xmx6144M -XX:MaxHeapSize=2048M"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# Speed up grep command
alias grep="LANG=C grep"

#
# Prints error message to the stdout and exit.
#
die() {
  echo "$@" >&2
  exit 1
}

#
# Checkouts a D4J's project-bug.
#
_checkout() {
  local USAGE="Usage: ${FUNCNAME[0]} <pid> <bid> <fixed (f) or buggy (b)>"
  if [ "$#" != 3 ]; then
    echo "$USAGE" >&2
    return 1
  fi

  local pid="$1"
  local bid="$2"
  local version="$3" # either b or f

  local output_dir="/tmp/$USER-$$-$pid-$bid"
  rm -rf "$output_dir"; mkdir -p "$output_dir"
  "$D4J_HOME_FOR_FL/framework/bin/defects4j" checkout -p "$pid" -v "${bid}$version" -w "$output_dir" || return 1
  [ -d "$output_dir" ] || die "$output_dir does not exist!"

  if [ "$pid" == "Time" ]; then
    if [ "$bid" -eq "18" ] || [ "$bid" -eq "22" ] || [ "$bid" -eq "24" ] || [ "$bid" -eq "27" ]; then
      # For Time-{18, 22, 24, and 27}, test case 'org.joda.time.TestPeriodType::testForFields4'
      # only fails when executed in isolation, i.e., it does not fail when it is
      # executed in the same JVM as other test cases from the same test class
      # but it does fail if executed in a single JVM. As it does not cover any
      # buggy code, it is safe to conclude it is a dependent test case and could
      # be excluded. Ideally, it should be discarded by the D4J checkout command,
      # however, as the same test class, including test case 'testForFields4',
      # is also executed by other Time bugs we took a conservative approach and
      # only discard it for bugs Time-{18, 22, 24, and 27}.
      pushd . > /dev/null 2>&1
      cd "$output_dir"
        echo "--- org.joda.time.TestPeriodType::testForFields4" > extra.dependent_tests
        "$D4J_HOME_FOR_FL/framework/util/rm_broken_tests.pl" extra.dependent_tests $("$D4J_HOME_FOR_FL/framework/bin/defects4j" export -p dir.src.tests) || return 1
      popd > /dev/null 2>&1
    fi
  fi

  echo "$output_dir"
  return 0
}

#
# Returns the test classpath of a previously checkout D4J's project-bug.
#
_get_test_classpath() {
  local USAGE="Usage: ${FUNCNAME[0]} <checkout_dir>"
  if [ "$#" != 1 ]; then
    echo "$USAGE" >&2
    return 1
  fi

  local checkout_dir="$1"
  [ -d "$checkout_dir" ] || die "[ERROR] $checkout_dir does not exist!"

  cp=$(cd "$checkout_dir" > /dev/null 2>&1 && \
       $D4J_HOME_FOR_FL/framework/bin/defects4j compile > /dev/null 2>&1 && \
       $D4J_HOME_FOR_FL/framework/bin/defects4j export -p cp.test) || die "[ERROR] Get classpath has failed!"
  [ "$cp" != "" ] || die "[ERROR] test-classpath is empty!"

  echo "$cp"
  return 0
}

#
# Return full path of the target directory of source classes.
#
_get_src_classes_dir() {
  local USAGE="Usage: ${FUNCNAME[0]} <checkout_dir>"
  if [ "$#" != 1 ]; then
    echo "$USAGE" >&2
    return 1
  fi

  local checkout_dir="$1"
  [ -d "$checkout_dir" ] || die "[ERROR] $checkout_dir does not exist!"

  src_classes_dir=$(cd "$checkout_dir" > /dev/null 2>&1 && \
                     $D4J_HOME_FOR_FL/framework/bin/defects4j compile > /dev/null 2>&1 && \
                     $D4J_HOME_FOR_FL/framework/bin/defects4j export -p dir.bin.classes) || die "[ERROR] Get test classes dir has failed!"
  [ "$src_classes_dir" != "" ] || die "[ERROR] src-classes-dir is empty!"

  echo "$checkout_dir/$src_classes_dir" # Return full path
  return 0
}

#
# Return full path of the target directory of test classes.
#
_get_test_classes_dir() {
  local USAGE="Usage: ${FUNCNAME[0]} <pid> <bid> <checkout_dir>"
  if [ "$#" != 3 ]; then
    echo "$USAGE" >&2
    return 1
  fi

  local pid="$1"
  local bid="$2"
  local checkout_dir="$3"
  [ -d "$checkout_dir" ] || die "[ERROR] $checkout_dir does not exist!"

  test_classes_dir=$(cd "$checkout_dir" > /dev/null 2>&1 && \
                     $D4J_HOME_FOR_FL/framework/bin/defects4j compile > /dev/null 2>&1 && \
                     $D4J_HOME_FOR_FL/framework/bin/defects4j export -p dir.bin.tests)
  if [ $? -ne 0 ]; then
    if [ "$pid" == "Chart" ]; then
      test_classes_dir="build-tests"
    elif [ "$pid" == "Closure" ]; then
      test_classes_dir="build/test"
    elif [ "$pid" == "Lang" ]; then
      if [ "$bid" -ge "1" ] && [ "$bid" -le "20" ]; then
        test_classes_dir="target/tests"
      elif [ "$bid" -ge "21" ] && [ "$bid" -le "41" ]; then
        test_classes_dir="target/test-classes"
      elif [ "$bid" -ge "42" ] && [ "$bid" -le "65" ]; then
        test_classes_dir="target/tests"
      else
        die "[ERROR] Get test classes dir has failed!"
      fi
    elif [ "$pid" == "Math" ]; then
      test_classes_dir="target/test-classes"
    elif [ "$pid" == "Mockito" ]; then
      if [ "$bid" -ge "1" ] && [ "$bid" -le "11" ]; then
        test_classes_dir="build/classes/test"
      elif [ "$bid" -ge "12" ] && [ "$bid" -le "17" ]; then
        test_classes_dir="target/test-classes"
      elif [ "$bid" -ge "18" ] && [ "$bid" -le "21" ]; then
        test_classes_dir="build/classes/test"
      elif [ "$bid" -ge "22" ] && [ "$bid" -le "38" ]; then
        test_classes_dir="target/test-classes"
      else
        die "[ERROR] Get test classes dir has failed!"
      fi
    elif [ "$pid" == "Time" ]; then
      if [ "$bid" -ge "1" ] && [ "$bid" -le "11" ]; then
        test_classes_dir="target/test-classes"
      elif [ "$bid" -ge "12" ] && [ "$bid" -le "27" ]; then
        test_classes_dir="build/tests"
      else
        die "[ERROR] Get test classes dir has failed!"
      fi
    else
      die "[ERROR] Get test classes dir has failed!"
    fi
  fi
  [ "$test_classes_dir" != "" ] || die "[ERROR] test-classes-dir is empty!"
  [ -d "$checkout_dir/$test_classes_dir" ] || die "[ERROR] $checkout_dir/$test_classes_dir does not exist!"

  echo "$checkout_dir/$test_classes_dir" # Return full path
  return 0
}

#
# Collect the list of unit test methods.
#
_collect_list_of_unit_tests() {
  local USAGE="Usage: ${FUNCNAME[0]} <pid> <bid> <checkout_dir> <output_file>"
  if [ "$#" != 4 ]; then
    echo "$USAGE" >&2
    return 1
  fi

  [ "$D4J_HOME_FOR_FL" != "" ] || die "[ERROR] D4J_HOME_FOR_FL is not set!"
  [ -d "$D4J_HOME_FOR_FL" ] || die "[ERROR] $D4J_HOME_FOR_FL does not exist!"

  [ "$GZOLTAR_CLI_JAR" != "" ] || die "[ERROR] GZOLTAR_CLI_JAR is not set!"
  [ -s "$GZOLTAR_CLI_JAR" ] || die "[ERROR] $GZOLTAR_CLI_JAR does not exist!"

  local pid="$1"
  local bid="$2"
  local checkout_dir="$3"
  [ -d "$checkout_dir" ] || die "[ERROR] $checkout_dir does not exist!"
  local output_file="$4"
  >"$output_file" || die "[ERROR] Cannot write to $output_file!"

  test_classpath=$(_get_test_classpath "$checkout_dir")
  if [ $? -ne 0 ]; then
    echo "[ERROR] _get_test_classpath for $pid-${bid}b version has failed!" >&2
    return 1
  fi
  echo "[DEBUG] test_classpath: $test_classpath" >&2

  test_classes_dir=$(_get_test_classes_dir "$pid" "$bid" "$checkout_dir")
  if [ $? -ne 0 ]; then
    echo "[ERROR] _get_test_classes_dir for $pid-${bid}b version has failed!" >&2
    return 1
  fi
  echo "[DEBUG] test_classes_dir: $test_classes_dir" >&2

  local relevant_tests_file="$D4J_HOME_FOR_FL/framework/projects/$pid/relevant_tests/$bid"
  [ -s "$relevant_tests_file" ] || die "[ERROR] $relevant_tests_file does not exist or it is empty!"
  echo "[DEBUG] relevant_tests_file: $relevant_tests_file" >&2

  # Some export commands might have removed some build files
  (cd "$checkout_dir" > /dev/null 2>&1 && \
     $D4J_HOME_FOR_FL/framework/bin/defects4j compile > /dev/null 2>&1) || die "[ERROR] Failed to compile the project!"

  java -cp $D4J_HOME_FOR_FL/framework/projects/lib/junit-4.11.jar:$test_classpath:$GZOLTAR_CLI_JAR \
    com.gzoltar.cli.Main listTestMethods \
      "$test_classes_dir" \
      --outputFile "$output_file" \
      --includes $(cat "$relevant_tests_file" | sed 's/$/#*/' | sed ':a;N;$!ba;s/\n/:/g') || die "GZoltar listTestMethods command has failed!"
  [ -s "$output_file" ] || die "[ERROR] $output_file does not exist or it is empty!"

  return 0
}

#
# Collect the list of classes (and inner classes) that might be faulty.
#
_collect_list_of_likely_faulty_classes() {
  local USAGE="Usage: ${FUNCNAME[0]} <pid> <bid> <checkout_dir> <output_file>"
  if [ "$#" != 4 ]; then
    echo "$USAGE" >&2
    return 1
  fi

  [ "$D4J_HOME_FOR_FL" != "" ] || die "[ERROR] D4J_HOME_FOR_FL is not set!"
  [ -d "$D4J_HOME_FOR_FL" ] || die "[ERROR] $D4J_HOME_FOR_FL does not exist!"

  local pid="$1"
  local bid="$2"
  local checkout_dir="$3"
  [ -d "$checkout_dir" ] || die "[ERROR] $checkout_dir does not exist!"
  local output_file="$4"
  >"$output_file" || die "[ERROR] Cannot write to $output_file!"

  local loaded_classes_file="$D4J_HOME_FOR_FL/framework/projects/$pid/loaded_classes/$bid.src"
  [ -s "$loaded_classes_file" ] || die "[ERROR] $loaded_classes_file does not exist or it is empty!"
  echo "[DEBUG] loaded_classes_file: $loaded_classes_file" >&2

  # "normal" classes
  local normal_classes=$(cat "$loaded_classes_file" | sed 's/$/:/' | sed ':a;N;$!ba;s/\n//g')
  [ "$normal_classes" != "" ] || die "[ERROR] List of classes is empty!"
  local inner_classes=$(cat "$loaded_classes_file" | sed 's/$/$*:/' | sed ':a;N;$!ba;s/\n//g')
  [ "$inner_classes" != "" ] || die "[ERROR] List of inner classes is empty!"

  echo "$normal_classes$inner_classes" > "$output_file"
  return 0
}

#
# Runs GZoltar fault localization tool on a specific D4J's project-bug.
#
_run_gzoltar() {
  local USAGE="Usage: ${FUNCNAME[0]} <work_dir> <pid> <bid> <data_dir>"
  if [ "$#" != 4 ]; then
    echo "$USAGE" >&2
    return 1
  fi

  [ "$D4J_HOME_FOR_FL" != "" ] || die "[ERROR] D4J_HOME_FOR_FL is not set!"
  [ -d "$D4J_HOME_FOR_FL" ] || die "[ERROR] $D4J_HOME_FOR_FL does not exist!"

  [ "$GZOLTAR_CLI_JAR" != "" ] || die "[ERROR] GZOLTAR_CLI_JAR is not set!"
  [ -s "$GZOLTAR_CLI_JAR" ] || die "[ERROR] $GZOLTAR_CLI_JAR does not exist or it is empty!"

  [ "$GZOLTAR_AGENT_JAR" != "" ] || die "[ERROR] GZOLTAR_AGENT_JAR is not set!"
  [ -s "$GZOLTAR_AGENT_JAR" ] || die "[ERROR] $GZOLTAR_AGENT_JAR does not exist or it is empty!"

  local tmp_dir="$1"
  local pid="$2"
  local bid="$3"
  local data_dir="$4"

  local unit_tests_file="$tmp_dir/unit_tests.txt"
  >"$unit_tests_file" || die "[ERROR] Cannot write to $unit_tests_file!"
  _collect_list_of_unit_tests "$pid" "$bid" "$tmp_dir" "$unit_tests_file"

  # debugging
  exit

  if [ $? -ne 0 ]; then
    echo "[ERROR] Collection of unit test cases of the $pid-${bid}b version has failed!" >&2
    return 1
  fi

  local classes_to_debug_file="$tmp_dir/classes_to_debug.txt"
  >"$classes_to_debug_file" || die "[ERROR] Cannot write to $classes_to_debug_file!"
  _collect_list_of_likely_faulty_classes "$pid" "$bid" "$tmp_dir" "$classes_to_debug_file"
  if [ $? -ne 0 ]; then
    echo "[ERROR] Collection of likely faulty classes of the $pid-${bid}b version has failed!" >&2
    return 1
  fi
  local classes_to_debug=$(cat "$classes_to_debug_file")

  test_classpath=$(_get_test_classpath "$tmp_dir")
  if [ $? -ne 0 ]; then
    echo "[ERROR] _get_test_classpath for $pid-${bid}b version has failed!" >&2
    return 1
  fi
  src_classes_dir=$(_get_src_classes_dir "$tmp_dir")
  if [ $? -ne 0 ]; then
    echo "[ERROR] _get_src_classes_dir for $pid-${bid}b version has failed!" >&2
    return 1
  fi

  # Some export commands might have removed some build files
  (cd "$tmp_dir" > /dev/null 2>&1 && \
     $D4J_HOME_FOR_FL/framework/bin/defects4j compile > /dev/null 2>&1) || die "[ERROR] Failed to compile the project!"

  local ser_file="$data_dir/gzoltar.ser"
  echo "[INFO] Start: $(date)" >&2
  (cd "$tmp_dir" > /dev/null 2>&1 && \
    java -XX:MaxPermSize=2048M -javaagent:$GZOLTAR_AGENT_JAR=destfile=$ser_file,buildlocation=$src_classes_dir,includes=$classes_to_debug,excludes="",inclnolocationclasses=false,output="FILE" \
      -cp $src_classes_dir:$D4J_HOME_FOR_FL/framework/projects/lib/junit-4.11.jar:$test_classpath:$GZOLTAR_CLI_JAR \
      com.gzoltar.cli.Main runTestMethods \
        --testMethods "$unit_tests_file" \
        --collectCoverage)
  if [ $? -ne 0 ]; then
    echo "[ERROR] GZoltar runTestMethods command has failed for $pid-${bid}b version!" >&2
    return 1
  fi
  [ -s "$ser_file" ] || die "[ERROR] $ser_file does not exist or it is empty!"

  echo "[INFO] End: $(date)" >&2

  return 0
}

#
# Generates a text-based fault localization report given a previously computed
# .ser file.
#
_generate_fault_localization_report() {
  local USAGE="Usage: ${FUNCNAME[0]} <work_dir> <ser_file_path> <output_dir>"
  if [ "$#" != 3 ]; then
    echo "$USAGE" >&2
    return 1
  fi

  [ "$D4J_HOME_FOR_FL" != "" ] || die "[ERROR] D4J_HOME_FOR_FL is not set!"
  [ -d "$D4J_HOME_FOR_FL" ] || die "[ERROR] $D4J_HOME_FOR_FL does not exist!"

  [ "$GZOLTAR_CLI_JAR" != "" ] || die "[ERROR] GZOLTAR_CLI_JAR is not set!"
  [ -s "$GZOLTAR_CLI_JAR" ] || die "[ERROR] $GZOLTAR_CLI_JAR does not exist or it is empty!"

  local tmp_dir="$1"
  local ser_file_path="$2"
  local output_dir="$3"

  [ -d "$tmp_dir" ]       || die "$tmp_dir does not exist!"
  [ -s "$ser_file_path" ] || die "$ser_file_path does not exist or it is empty!"
  mkdir -p "$output_dir" || die "Failed to create $output_dir!"

  local src_classes_dir=$(_get_src_classes_dir "$tmp_dir")
  if [ $? -ne 0 ]; then
    echo "[ERROR] _get_src_classes_dir has failed!" >&2
    return 1
  fi

  java -cp $D4J_HOME_FOR_FL/framework/projects/lib/junit-4.11.jar:$test_classpath:$GZOLTAR_CLI_JAR \
    com.gzoltar.cli.Main faultLocalizationReport \
      --buildLocation "$src_classes_dir" \
      --outputDirectory "$output_dir" \
      --dataFile "$ser_file_path" \
      --granularity "line" \
      --inclPublicMethods \
      --inclStaticConstructors \
      --inclDeprecatedMethods \
      --family "sfl" \
      --formula "ochiai" \
      --formatter "txt" || die "GZoltar faultLocalizationReport command has failed!"

  local spectra_file="$output_dir/sfl/txt/spectra.csv"
   local matrix_file="$output_dir/sfl/txt/matrix.txt"
    local tests_file="$output_dir/sfl/txt/tests.csv"

  [ -s "$spectra_file" ] || die "[ERROR] $spectra_file does not exist or it is empty!"
   [ -s "$matrix_file" ] || die "[ERROR] $matrix_file does not exist or it is empty!"
    [ -s "$tests_file" ] || die "[ERROR] $tests_file does not exist or it is empty!"

  return 0
}
