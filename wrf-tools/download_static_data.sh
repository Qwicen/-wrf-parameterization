#!/bin/bash

SCRIPT_PATH=$(dirname $(readlink -f $0))
ROOT_DIR=${SCRIPT_PATH%/*}

mkdir $ROOT_DIR/data -p
DATA_DIR=$ROOT_DIR/data

# ========================== Static Geography Data ==========================
echo "Static Geography Data"
if [[ ! -d "$DATA_DIR/WPS_GEOG" ]]; then
  if [[ ! -f "$DATA_DIR/geog_high_res_mandatory.tar.gz" ]]; then
      wget "https://www2.mmm.ucar.edu/wrf/src/wps_files/geog_high_res_mandatory.tar.gz" \
           -O $DATA_DIR/geog_high_res_mandatory.tar.gz -q
  fi
  echo "--- Extracting data"
  tar -xf $DATA_DIR/geog_high_res_mandatory.tar.gz --directory $DATA_DIR
  echo "--- Extraction complete"
else
  echo "--- OK: WPS_GEOG already exists"
fi
