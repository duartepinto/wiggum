#!/bin/bash

TMP_FILE="$(mktemp /tmp/tmp.XXXXXXXXX)"
FAILED_OUTPUT=failed-tests.txt

function usage()
{
    echo -e "Usage: $0 [COMMAND] [OPTIONS...]\n\nA simple sbt helper script to help run and capture non-deterministic tests. Runs the test multiple times and in each iteration, if it captures an error, it will append the text outputted in that iteration to a file."

    echo "Examples:"
    echo -e "\t$0 -p \"*foo-project\" -s \"*BarSpec\" -t \"test baz\""
    echo -e "\t$0 --it-test -s \"com.path.to.spec.BarSpec\""
    echo -e "\t$0 --it-test \t"

    echo "Commands:"
    echo -e "\t--it-test\tRuns integration tests. Only accepts '-s' and '-o' options"

    echo "Options:"
    echo -e "\t-p|--project\tSpecify the project to run (-p \"<project_name>\")"
    echo -e "\t-s|--spec\tSpecify the specification to run (-s \"<full_spec_name>\" / -s \"*<spec_name>\" )"
    echo -e "\t-t|--test\tSpecify a single spec2 example to run (-t \"<example_name>\")"
    echo -e "\t-o|--output\tSpecify the file output where the captured errors will be stored (-t \"<example_name>\")"
    echo -e "\t-h|--help\tShow this"
    echo ""
}

PROJECT=testOnly
SPEC="*"
TEST=
IT_TEST=false

while [[ $# -gt 0 ]]
do
key="$1"
case $key in
  -h | --help)
    usage
    exit
    ;;
  -p|--project)
    PROJECT="$2/testOnly"
    shift # past argument
    shift # past value
    ;;

  -s|--spec)
    SPEC="$2"
    shift # past argument
    shift # past value
    ;;
  -t|--test)
    TEST="-- ex \"$2\""
    shift # past argument
    shift # past value
    ;;
  -o|--output)
    FAILED_OUTPUT=$2
    shift # past argument
    shift # past value
    ;;
  --it-test)
    IT_TEST=true
    shift # past argument
    ;;
  *)
    echo "ERROR: unknown parameter \"$PARAM\""
    usage
    exit 1
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if $IT_TEST; then
  if [ "$SPEC" == "*" ]; then
    COMAND="it:test"
  else
    COMAND="it:testOnly $SPEC"
  fi
else
  COMAND="$PROJECT $SPEC $TEST"
fi

echo Comand: "$COMAND"
ERRORS=0
for TRIES in {1..9999}
do

echo "================= Try $TRIES ================="
sbtn "$COMAND" | tee  $TMP_FILE

## Previously the verification was done this way to catch colors. Not needed, the color chars are just ignored
#if perl -pe 's/\x1b\[[0-9;]*m//g' $TMP_FILE | grep -q "\[.*error.*]"; then

if grep -q "\[.*error.*]" $TMP_FILE; then
  ERRORS=$((ERRORS + 1))
  echo "FOUND ERROR $ERRORS"
  echo "====================== ERROR $ERRORS ======================" >> $FAILED_OUTPUT
  cat $TMP_FILE >> $FAILED_OUTPUT
fi

done
sbtn shutdown
rm -f "$TMP_FILE"
