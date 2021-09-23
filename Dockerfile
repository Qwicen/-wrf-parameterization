FROM ubuntu

COPY environment.yml /wrf/
COPY ./wrf-tools /wrf/wrf-tools
WORKDIR /wrf

RUN apt-get update
RUN apt-get install -y wget git tcsh m4 gcc g++ gfortran make perl && \
    rm -rf /var/lib/apt/lists/*

RUN wget \
    https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && bash Miniconda3-latest-Linux-x86_64.sh -b \
    && rm -f Miniconda3-latest-Linux-x86_64.sh

ENV PATH=/root/miniconda3/envs/wrf/bin:$PATH
RUN /root/miniconda3/bin/conda env create -f environment.yml
RUN bash ./wrf-tools/install_wrf.sh


