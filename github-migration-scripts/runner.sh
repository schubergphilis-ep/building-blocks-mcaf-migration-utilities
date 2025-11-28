#!/usr/bin/env bash
set -euo pipefail

# Usage: ./runner.sh input.txt ./other-script.sh

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <input-file> <script-to-run>" >&2
  exit 1
fi

INPUT_FILE="$1"
OTHER_SCRIPT="$2"

if [ ! -f "$INPUT_FILE" ]; then
  echo "Input file not found: $INPUT_FILE" >&2
  exit 1
fi

if [ ! -x "$OTHER_SCRIPT" ]; then
  echo "Script is not executable: $OTHER_SCRIPT" >&2
  exit 1
fi

while IFS= read -r arg1 arg2 || [ -n "${arg1-}" ]; do
  # Skip empty or comment lines
  if [ -z "${arg1-}" ] || [ "${arg1#\#}" != "$arg1" ]; then
    continue
  fi

  echo "[INFO] Running: $OTHER_SCRIPT '$arg1' '$arg2'"
  "$OTHER_SCRIPT" $arg1 $arg2
done < "$INPUT_FILE"
