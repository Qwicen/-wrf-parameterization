#!/bin/bash

while [ $# -gt 0 ]; do
  case "$1" in
    --email=*)
      RDAEMAIL="${1#*=}"
      ;;
    --pass=*)
      RDAPWD="${1#*=}"
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

# ========================== Run WPS ==========================
python $ROOT_DIR/wrf-tools/templates/render_templates.py --wrf_root $ROOT_DIR

cd $WPS_DIR
echo "Running geogrid"
rm -f log.geogrid
rm -f geo_em.d*
./geogrid.exe &> log.geogrid
echo "--- Completed"

# TODO: link only necessary files
rm -f GRIBFILE.*
./link_grib.csh $DATA_DIR/GFS/*
ln -sf ungrib/Variable_Tables/Vtable.GFS Vtable

echo "Running metgrid"
rm -f met_em.d*.nc
./metgrid.exe >& log.metgrid
echo "--- Completed"