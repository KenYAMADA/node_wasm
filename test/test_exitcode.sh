#!/bin/sh
#
# test_exitcode.sh
#
# usage:
#  sh test_exitcode.sh compilername interpname filename 
#

compiler=../$1
interpreter=../$2
src=$3
jsfile=../sample/$src

wast_file=tmp/$src.wast
wasm_file=tmp/$src.wasm
wasm_exec=../node_run_wasm.js

interp_wasm_exit=0
interp_wast_file=tmp/$src_interp.wast
interp_wasm_file=tmp/$src_interp.wasm

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


# -- compile to wast ---
CompileToWast() {
  echo "--- compile src=$jsfile wast=$wast compiler=$compiler ---"
  node $compiler $jsfile
  if [ "$?" -eq "0" ]
  then
    echo "compile SUCCERSS"
    mv generated.wast $wast_file
  else
    echo "!! compile FAILED !!"
    exit 1
  fi
}

WastToWasm() {
  echo "--- wast $wast_file to wasm $wasm_file--"
  $wasmas $wast_file
  if [ "$?" -eq "0" ]
  then
    echo "wasm-as SUCCERSS"
  else
    echo "!! wasm-as FAILED !!"
    exit 1
  fi
}

ExecWasm() {
  echo "--- exec $wasm_file from node"
  #cp $wasm_file generated.wasm
  node $wasm_exec $wasm_file
  wasm_exit=$?
  echo "wasm exit code=$wasm_exit"
}

# -- compile on interpreter to wast ---
InterpCompileToWast() {
  echo "--- interp-compile src=$jsfile wast=$interp_wast_file compiler=$compiler interp=$interpreter ---"
  node $interpreter $compiler $jsfile
  if [ "$?" -eq "0" ]
  then
    echo "interp-compile SUCCERSS"
    mv generated.wast $interp_wast_file
  else
    echo "!! compile FAILED !!"
    exit 1
  fi
}

InterpWastToWasm() {
  echo "--- interp-wast $interp_wast_file to wasm $interp_wasm_file--"
  $wasmas $interp_wast_file
  if [ "$?" -eq "0" ]
  then
    echo "interp-wasm-as SUCCERSS"
  else
    echo "!! interp-wasm-as FAILED !!"
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

CompileToWast
WastToWasm
ExecWasm

InterpCompileToWast
InterpWastToWasm
InterpExecWasm

PreprocessForDirect
NodeDirect

CompareExitCode
CleanUp

exit 0


