#!/bin/sh
#
# test_exitcode.sh
#
# usage:
#  sh test_exitcode.sh translatername interpname filename 
#

translater=../$1
interpreter=../$2
src=$3
jsfile=../sample/$src

wast_file=tmp/$src.wast
wasm_file=tmp/$src.wasm
#wasm_exec=../node_run_wasm.js
wasm_exec=../run_wasm_simple.js

interp_wasm_exit=0
interp_wast_file=tmp/interp_$src.wast
interp_wasm_file=tmp/interp_$src.wasm

direct_file=tmp/node_direct_$src
direct_exit=0
wasm_exit=0

exitcode_file=tmp/exitcode_$src.txt
echo "" > $exitcode_file

# --- for wast to wasm  --
wasmas=wasm-as
if [ $WASMAS_FOR_TEST ]
then
  wasmas=$WASMAS_FOR_TEST
fi


# -- translate to wast ---
TranslateToWast() {
  echo "--- translate src=$jsfile wast=$wast_file translater=$translater ---"
  node $translater $jsfile
  if [ "$?" -eq "0" ]
  then
    echo "translate SUCCERSS"
    mv generated.wast $wast_file
  else
    echo "ERROR! ... translate FAILED !"
    exit 1
  fi
}

WastToWasm() {
  echo "--- wast $wast_file to wasm $wasm_file --"
  $wasmas $wast_file
  if [ "$?" -eq "0" ]
  then
    echo "wasm-as SUCCERSS"
  else
    echo "ERROR! ... wasm-as FAILED !"
    exit 1
  fi
}

ExecWasm() {
  echo "--- exec $wasm_file from node"
  node $wasm_exec $wasm_file
  wasm_exit=$?
  echo "wasm exit code=$wasm_exit"
}

# -- translate on interpreter to wast ---
InterpTranslateToWast() {
  echo "--- interp-translate src=$jsfile wast=$interp_wast_file translater=$translater interp=$interpreter ---"
  node $interpreter $translater $jsfile
  if [ "$?" -eq "0" ]
  then
    echo "interp-translate SUCCERSS"
    mv generated.wast $interp_wast_file
  else
    echo "ERROR! ... interp-translate FAILED !"
    exit 1
  fi
}

InterpWastToWasm() {
  echo "--- interp-wast $interp_wast_file to interp-wasm $interp_wasm_file --"
  $wasmas $interp_wast_file
  if [ "$?" -eq "0" ]
  then
    echo "interp-wasm-as SUCCERSS"
  else
    echo "ERROR! ... interp-wasm-as FAILED !"
    exit 1
  fi
}

InterpExecWasm() {
  echo "--- interp-exec $interp_wasm_file from node"
  #cp $interp_wasm_file generated.wasm
  node $wasm_exec $interp_wasm_file
  interp_wasm_exit=$?
  echo "interp-wasm exit code=$interp_wasm_exit"
}

PreprocessForDirect() {
  echo "-- preprocess for exit code:  src=$jsfile tmp=$direct_file --"
  echo "process.exit(" > $direct_file
  cat $jsfile | sed -e "s/;\$//" >>  $direct_file  #  remove ';' at line end
  echo ");" >> $direct_file
}

NodeDirect() {
  echo "-- node $src --"
  node $direct_file
  direct_exit=$?
  echo "direct exit code=$direct_exit"
}

CompareExitCode() {
  if [ "$direct_exit" -eq "$wasm_exit" ]
  then
    echo "OK ... node <-> wasm exit code match: $direct_exit == $wasm_exit"
  else
    echo "ERROR! ... node <-> wasm exit code NOT MATCH : $direct_exit != $wasm_exit"
    echo "ERROR! ... node <-> wasm exit code NOT MATCH : $direct_exit != $wasm_exit" > $exitcode_file
    exit 1
  fi

  if [ "$direct_exit" -eq "$interp_wasm_exit" ]
  then
    echo "OK ... node <-> interp-wasm exit code match: $direct_exit == $interp_wasm_exit"
  else
    echo "ERROR! ... node <-> interp-wasm exit code NOT MATCH : $direct_exit != $interp_wasm_exit"
    echo "ERROR! ... node <-> interp-wasm exit code NOT MATCH : $direct_exit != $interp_wasm_exit" > $exitcode_file
    exit 1
  fi
}

CleanUp() {
  #rm generated.wasm
  rm $direct_file
  rm $wast_file
  rm $wasm_file
  rm $interp_wast_file
  rm $interp_wasm_file
  rm $exitcode_file

  echo ""
}

TranslateToWast
WastToWasm
ExecWasm

InterpTranslateToWast
InterpWastToWasm
InterpExecWasm

PreprocessForDirect
NodeDirect

CompareExitCode
CleanUp

exit 0


