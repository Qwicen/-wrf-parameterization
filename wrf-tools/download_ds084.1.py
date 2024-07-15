#!/usr/bin/env python
import os
import sys
import yaml
import requests
import argparse
from datetime import datetime, timedelta


def get_file_list_from_config(cfg):
    start_date = datetime.strptime(cfg["time"]["START_DATE"], '%Y-%m-%d_%H:%M:%S')
    end_date = datetime.strptime(cfg["time"]["END_DATE"], '%Y-%m-%d_%H:%M:%S')
    delta = timedelta(seconds=int(cfg["time"]["INTERVAL_SECONDS"]))

    file_list = []
    cur_date = start_date
    while cur_date <= end_date:
        ymd_str = f"{start_date.year}{start_date.month:0>2}{start_date.day:0>2}"
        hours_from_start = (cur_date - start_date).days * 24 + cur_date.hour
        name = f"{start_date.year}/{ymd_str}/gfs.0p25.{ymd_str}{start_date.hour:0>2}.f{hours_from_start:0>3}.grib2"
        file_list.append(name)
        cur_date += delta

    return file_list


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--wrf_root', type=str, required=True)
    parser.add_argument('--orcid', type=str, required=True)
    parser.add_argument('--token', type=str, required=True)
    parser.add_argument('--data_path', type=str, required=True)
    args = parser.parse_args()

    url = 'https://rda.ucar.edu/cgi-bin/login'
    ret = requests.post(url, data={'orcid_id': args.orcid, 'api_token': args.token, 'action': 'tokenlogin'})
    if ret.status_code != 200:
        print('Bad Authentication')
        print(ret.text)
        #exit(1)
    else:
        print(f"Authentication successful: {url}")

    dspath = 'https://data.rda.ucar.edu/ds084.1/'

    with open(os.path.join(args.wrf_root, "wrf-tools/config/config.yml"), "r") as file:
        config = yaml.load(file, Loader=yaml.CLoader)

    file_list = get_file_list_from_config(config)
    for file in file_list:
        filename = dspath+file
        file_base = os.path.join(args.data_path, os.path.basename(file))
        print('Downloading', file_base)
        req = requests.get(filename, cookies=ret.cookies, allow_redirects=True, stream=True)
        if not os.path.isfile(file_base):
            with open(file_base, 'wb') as outfile:
                chunk_size = 1048576
                for chunk in req.iter_content(chunk_size=chunk_size):
                    outfile.write(chunk)
        else:
            print(f'OK: {file_base} exists.')
        print()
