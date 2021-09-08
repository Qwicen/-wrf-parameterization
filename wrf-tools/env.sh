if [ -z "$1" ]; then
    echo "Please, provide ROOT_DIR"
    exit 1
fi

export DIR=$1/build/lib

export CC=gcc
export CXX=g++
export FC=gfortran
export FCFLAGS=-m64
export F77=gfortran
export FFLAGS=-m64

export JASPERLIB=$DIR/grib2/lib
export JASPERINC=$DIR/grib2/include

export LDFLAGS=-L$DIR/grib2/lib
export CPPFLAGS=-I$DIR/grib2/include

export NETCDF=$DIR/netcdf

export LD_LIBRARY_PATH=$DIR/grib2/lib:$LD_LIBRARY_PATH
export PATH=$NETCDF/bin:$DIR/mpich/bin:$PATH

