#!/bin/bash

while [ $# -gt 0 ]; do
  case "$1" in
    --n_jobs=*)
      N_JOBS="${1#*=}"
      ;;
    *)
      printf "***************************\n"
      printf "* Error: Invalid argument.*\n"
      printf "***************************\n"
      exit 1
  esac
  shift
done

SCRIPT_PATH=$(dirname $(readlink -f $0))
ROOT_DIR=${SCRIPT_PATH%/*}

WRF_DIR=$ROOT_DIR/build/WRF
WPS_DIR=$ROOT_DIR/build/WPS
DATA_DIR=$ROOT_DIR/data

source ${ROOT_DIR}/wrf-tools/env.sh ${ROOT_DIR}

# ========================== Check WRF installation ==========================
echo "Checking WRF installation at ${ROOT_DIR}/build "

EXECUTABLES=(
    "$WRF_DIR/run/wrf.exe"
    "$WRF_DIR/run/real.exe"
    "$WPS_DIR/geogrid.exe"
    "$WPS_DIR/metgrid.exe"
    "$WPS_DIR/ungrib.exe"
)
for FILE in "${EXECUTABLES[@]}"; do
    if [[ -f "$FILE" ]]; then
        echo "--- Found ${FILE##*/}"
    else
        echo "ERROR: $FILE does not exist, terminating."
        exit 1
    fi
done

# ========================== Run WRF ==========================
python $ROOT_DIR/wrf-tools/templates/render_templates.py --wrf_root $ROOT_DIR

cd $WRF_DIR/run
rm -f wrfout*
rm -f auxhist7*
rm -f wrfbdy*
rm -f wrfinput*
rm -f rsl.*
rm -f met_em*

ln -s $ROOT_DIR/wrf-tools/config/my_output_fields_d01.txt .
ln -s $WPS_DIR/met_em* .
python $ROOT_DIR/wrf-tools/templates/render_templates.py --wrf_root $ROOT_DIR

echo "Running real.exe"
mpirun -np $N_JOBS ./real.exe
echo "--- Completed"

echo "Running wrf.exe"
mpirun -np $N_JOBS ./wrf.exe
echo "--- Completed"