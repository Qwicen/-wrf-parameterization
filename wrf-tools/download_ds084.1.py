#!/usr/bin/env python
import os
import sys
import yaml
import requests
import argparse
from datetime import datetime, timedelta


def check_file_status(filepath, file_size):
    sys.stdout.write('\r')
    sys.stdout.flush()
    size = int(os.stat(filepath).st_size)
    percent_complete = (size/file_size)*100
    sys.stdout.write('%.3f %s' % (percent_complete, '% Completed'))
    sys.stdout.flush()


def get_file_list_from_config(cfg):
    start_date = datetime.strptime(cfg["time"]["START_DATE"], '%Y-%m-%d_%H:%M:%S')
    end_date = datetime.strptime(cfg["time"]["END_DATE"], '%Y-%m-%d_%H:%M:%S')
    delta = timedelta(seconds=int(cfg["time"]["INTERVAL_SECONDS"]))

    file_list = []
    cur_date = start_date
    while cur_date <= end_date:
        ymd_substr = f"{start_date.year}{start_date.month:0>2}{start_date.day:0>2}"
        name = f"{start_date.year}/{ymd_substr}/gfs.0p25.{ymd_substr}{start_date.hour:0>2}.f{cur_date.hour:0>3}.grib2"
        file_list.append(name)
        cur_date += delta

    return file_list


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--wrf_root', type=str, required=True)
    parser.add_argument('--email', type=str, required=True)
    parser.add_argument('--pwd', type=str, required=True)
    parser.add_argument('--data_path', type=str, required=True)
    args = parser.parse_args()

    url = 'https://rda.ucar.edu/cgi-bin/login'
    ret = requests.post(url, data={'email': args.email, 'passwd': args.pwd, 'action': 'login'})
    if ret.status_code != 200:
        print('Bad Authentication')
        print(ret.text)
        exit(1)
    else:
        print(f"Authentication successful: {url}")

    dspath = 'https://rda.ucar.edu/data/ds084.1/'

    with open(os.path.join(args.wrf_root, "config.yml"), "r") as file:
        config = yaml.load(file, Loader=yaml.CLoader)

    file_list = get_file_list_from_config(config)
    for file in file_list:
        filename = dspath+file
        file_base = os.path.join(args.data_path, os.path.basename(file))
        print('Downloading', file_base)
        req = requests.get(filename, cookies=ret.cookies, allow_redirects=True, stream=True)
        filesize = int(req.headers['Content-length'])
        if not os.path.isfile(file_base):
            with open(file_base, 'wb') as outfile:
                chunk_size = 1048576
                for chunk in req.iter_content(chunk_size=chunk_size):
                    outfile.write(chunk)
                    if chunk_size < filesize:
                        check_file_status(file_base, filesize)
            check_file_status(file_base, filesize)
        else:
            print(f'OK: {file_base} exists.')
        print()
