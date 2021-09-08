#!/bin/bash

SCRIPT_PATH=$(dirname $(readlink -f $0))
ROOT_DIR=${SCRIPT_PATH%/*}

mkdir $ROOT_DIR/build -p
mkdir $ROOT_DIR/build/tests -p
mkdir $ROOT_DIR/build/lib -p
mkdir $ROOT_DIR/data -p

WRF_DIR=$ROOT_DIR/build/WRF
WPS_DIR=$ROOT_DIR/build/WPS
LIB_DIR=$ROOT_DIR/build/lib
TEST_DIR=$ROOT_DIR/build/tests
DATA_DIR=$ROOT_DIR/data

# ========================== System Environment Tests ==========================
echo "Starting System Environment Tests"
if ! command -v gfortran &> /dev/null; then
    echo "gfortran could not be found"
    exit
elif ! command -v cpp &> /dev/null; then
    echo "cpp could not be found"
    exit
elif ! command -v gcc &> /dev/null; then
    echo "gcc could not be found"
    exit
fi

wget "https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/Fortran_C_tests.tar" \
     -O $TEST_DIR/Fortran_C_tests.tar -q
tar -xf $TEST_DIR/Fortran_C_tests.tar --directory $TEST_DIR

if ! gfortran $TEST_DIR/TEST_1_fortran_only_fixed.f -o $TEST_DIR/a.out; then
    echo "ERROR: TEST_1_fortran_only_fixed.f compilation error"
    exit
elif ! $TEST_DIR/a.out | grep -q 'SUCCESS'; then
    echo "ERROR: TEST_1 execution error"
    exit
fi
rm $TEST_DIR/a.out

if ! gfortran $TEST_DIR/TEST_2_fortran_only_free.f90 -o $TEST_DIR/a.out; then
    echo "ERROR: TEST_2_fortran_only_free.f90 compilation error"
    exit
elif ! $TEST_DIR/a.out | grep -q 'SUCCESS'; then
    echo "ERROR: TEST_2 execution error"
    exit
fi
rm $TEST_DIR/a.out

if ! gcc $TEST_DIR/TEST_3_c_only.c -o $TEST_DIR/a.out; then
    echo "ERROR: TEST_3_c_only.c compilation error"
    exit
elif ! $TEST_DIR/a.out | grep -q 'SUCCESS'; then
    echo "ERROR: TEST_3 execution error"
    exit
fi
rm $TEST_DIR/a.out

if ! gcc -c -m64 $TEST_DIR/TEST_4_fortran+c_c.c -o $TEST_DIR/TEST_4_fortran+c_c.o; then
    echo "ERROR: TEST_4_fortran+c_c.c compilation error"
    exit
elif ! gfortran -c -m64 $TEST_DIR/TEST_4_fortran+c_f.f90 -o $TEST_DIR/TEST_4_fortran+c_f.o; then
    echo "ERROR: TEST_4_fortran+c_f.f90 compilation error"
    exit
elif ! gfortran -m64 $TEST_DIR/TEST_4_fortran+c_f.o $TEST_DIR/TEST_4_fortran+c_c.o -o $TEST_DIR/a.out; then
    echo "ERROR: TEST_4 linking error"
    exit
elif ! $TEST_DIR/a.out | grep -q 'SUCCESS'; then
    echo "ERROR: TEST_4 execution error"
    exit
fi
rm $TEST_DIR/a.out

if !$TEST_DIR/TEST_sh.sh &> /dev/null && !$TEST_DIR/TEST_csh.csh &> /dev/null && !$TEST_DIR/TEST_perl.pl &> /dev/null;
then
    echo "ERROR: please check sh, csh and perl installation"
fi
echo "--- System Environment Tests successfully passed"


# ==================== Building Libraries ==========================
echo "Building Libraries"
MPICH_NAME="mpich-3.3"
NETCDF_NAME="netcdf-4.1.3"
JASPER_NAME="jasper-1.900.1"
ZLIB_NAME="zlib-1.2.11"
LIBPNG_NAME="libpng-1.6.37"

LIB_URLS=(
    "https://www.mpich.org/static/downloads/3.3/${MPICH_NAME}.tar.gz"
    "https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/${NETCDF_NAME}.tar.gz"
    "https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/${JASPER_NAME}.tar.gz"
    "https://zlib.net/${ZLIB_NAME}.tar.gz"
    "https://download.sourceforge.net/libpng/${LIBPNG_NAME}.tar.gz"
)
for URL in "${LIB_URLS[@]}"; do
    if [[ ! -f "$LIB_DIR/${URL##*/}" ]]; then
        wget $URL -O $LIB_DIR/${URL##*/} -q
    else
        echo "OK: $URL already exists."
    fi
done
echo "--- Download complete"

for URL in "${LIB_URLS[@]}"; do
    tar xzf $LIB_DIR/${URL##*/} --directory $LIB_DIR
done
echo "--- Extraction complete"

source ${ROOT_DIR}/wrf-tools/env.sh ${ROOT_DIR}

#cd $LIB_DIR/$NETCDF_NAME
#rm -rf $LIB_DIR/netcdf
#make clean &> $LIB_DIR/log.compile
#./configure --prefix=$DIR/netcdf --disable-dap --disable-netcdf-4 --disable-shared >> $LIB_DIR/log.compile 2>&1
#make >> $LIB_DIR/log.compile 2>&1
#make install >> $LIB_DIR/log.compile 2>&1
#
#cd $LIB_DIR/$MPICH_NAME
#rm -rf $LIB_DIR/mpich
#make clean >> $LIB_DIR/log.compile 2>&1
#./configure --prefix=$DIR/mpich >> $LIB_DIR/log.compile 2>&1
#make >> $LIB_DIR/log.compile 2>&1
#make install >> $LIB_DIR/log.compile 2>&1
#
#for LIB_NAME in $ZLIB_NAME $LIBPNG_NAME $JASPER_NAME; do
#    cd $LIB_DIR/$LIB_NAME
#    make clean >> $LIB_DIR/log.compile 2>&1
#    ./configure --prefix=$DIR/grib2 >> $LIB_DIR/log.compile 2>&1
#    make >> $LIB_DIR/log.compile 2>&1
#    make install >> $LIB_DIR/log.compile 2>&1
#done
echo "--- Building complete. Logs are available at $LIB_DIR/log.compile"

# ========================== Library Compatibility Tests ==========================
echo "Library Compatibility Tests"
wget "https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/Fortran_C_NETCDF_MPI_tests.tar" \
     -O $TEST_DIR/Fortran_C_NETCDF_MPI_tests.tar -q
tar -xf $TEST_DIR/Fortran_C_NETCDF_MPI_tests.tar --directory $TEST_DIR

cp ${NETCDF}/include/netcdf.inc $TEST_DIR
if ! gfortran -c $TEST_DIR/01_fortran+c+netcdf_f.f -o $TEST_DIR/01_fortran+c+netcdf_f.o; then
    echo "ERROR: 01_fortran+c+netcdf_f.f compilation error"
    exit
elif ! gcc -c $TEST_DIR/01_fortran+c+netcdf_c.c -o $TEST_DIR/01_fortran+c+netcdf_c.o; then
    echo "ERROR: 01_fortran+c+netcdf_c.c compilation error"
    exit
elif ! gfortran $TEST_DIR/01_fortran+c+netcdf_f.o $TEST_DIR/01_fortran+c+netcdf_c.o \
                -L${NETCDF}/lib -lnetcdff -lnetcdf -o $TEST_DIR/a.out; then
    echo "ERROR: TEST 1 fortran + c + netcdf linking error"
    exit
elif ! $TEST_DIR/a.out | grep -q 'SUCCESS'; then
    echo "ERROR: TEST 1 fortran + c + netcdf execution error"
    exit
fi
rm $TEST_DIR/a.out

if ! mpif90 -c $TEST_DIR/02_fortran+c+netcdf+mpi_f.f -o $TEST_DIR/02_fortran+c+netcdf+mpi_f.o; then
    echo "ERROR: 02_fortran+c+netcdf+mpi_f.f compilation error"
    exit
elif ! mpicc -c $TEST_DIR/02_fortran+c+netcdf+mpi_c.c -o $TEST_DIR/02_fortran+c+netcdf+mpi_c.o; then
    echo "ERROR: 02_fortran+c+netcdf+mpi_c.c compilation error"
    exit
elif ! mpif90 $TEST_DIR/02_fortran+c+netcdf+mpi_f.o $TEST_DIR/02_fortran+c+netcdf+mpi_c.o \
              -L${NETCDF}/lib -lnetcdff -lnetcdf -o $TEST_DIR/a.out; then
    echo "ERROR: TEST 2 Fortran + C + NetCDF + MPI linking error"
    exit
elif ! $TEST_DIR/a.out | grep -q 'SUCCESS'; then
    echo "ERROR: TEST 2 Fortran + C + NetCDF + MPI execution error"
    exit
fi
rm $TEST_DIR/a.out
echo "--- Library Compatibility Tests successfully passed"


# ========================== WRF installation ==========================
echo "WRF installation"
if [[ -d "$WRF_DIR" ]]; then
    echo "--- Found WRF at $WRF_DIR"
else
    echo "--- Downloading WRF"
    git clone https://github.com/wrf-model/WRF.git $WRF_DIR --quiet
fi
if [[ -d "$WPS_DIR" ]]; then
    echo "--- Found WPS at $WPS_DIR"
else
    echo "--- Downloading WPS"
    git clone https://github.com/wrf-model/WPS.git $WPS_DIR --quiet
fi

#cd $WRF_DIR
## option 34: GNU compiler + dmpar
#./configure <<< 34 &> /dev/null
#./compile em_real &> log.compile
#echo "--- WRF compilation complete"

#cd $WPS_DIR
#./clean &> /dev/null
### option 3: GNU compiler + dmpar
#./configure <<< 3 &> /dev/null
#./compile &> log.compile
#echo "--- WPS compilation complete"

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
