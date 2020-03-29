#!/usr/bin/env bash

SCRIPT_DIR=$(cd `dirname $0` && pwd)
source "$SCRIPT_DIR/utils.sh" || exit 1

export GZOLTAR_CLI_JAR="$SCRIPT_DIR/lib/com.gzoltar.cli-1.7.3-SNAPSHOT-jar-with-dependencies.jar"
export GZOLTAR_AGENT_JAR="$SCRIPT_DIR/lib/com.gzoltar.agent.rt-1.7.3-SNAPSHOT-all.jar"

[ -s "$GZOLTAR_CLI_JAR" ] || die "$GZOLTAR_CLI_JAR does not exist or it is empty!"
[ -s "$GZOLTAR_AGENT_JAR" ] || die "$GZOLTAR_AGENT_JAR does not exist or it is empty!"

# --- VARIABLES THAT SHOULD BE UPDATED [BEGIN] ---------------------------------

export D4J_HOME="_________________"

pid="Closure" # For example, Closure
bid="103" # For example, 103

# --- VARIABLES THAT SHOULD BE UPDATED [END] -----------------------------------

hostname
java -version

data_dir="$SCRIPT_DIR/result/$pid/$bid"
rm -rf "$data_dir"; mkdir -p "$data_dir"

echo ""
echo "[INFO] Checkout $pid-${bid}b"
work_dir=$(_checkout "$pid" "$bid" "b")
if [ $? -ne 0 ]; then
  echo "[ERROR] Checkout of the $pid-${bid}b version has failed!"
fi

echo ""
echo "[INFO] Run GZoltar on $pid-${bid}b"
_run_gzoltar "$work_dir" "$pid" "$bid" "$data_dir" || die "[ERROR] Execution of GZoltar on $pid-${bid}b has failed!"

echo ""
echo "[INFO] Generate fault localization report for $pid-${bid}b"
_generate_fault_localization_report "$work_dir" "$data_dir/gzoltar.ser" "$data_dir" || die "[ERROR] Failed to generate a fault localization report!"

rm -rf "$work_dir" # Clean up

echo "DONE!"
exit 0
