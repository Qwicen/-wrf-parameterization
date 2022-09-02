#!/usr/bin/env python
import os
import sys
import yaml
import requests
import argparse
import time
import random
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
        ymd_str = f"{start_date.year}{start_date.month:0>2}{start_date.day:0>2}"
        hours_from_start = (cur_date - start_date).days * 24 + cur_date.hour
        name = f"{start_date.year}/{ymd_str}/gfs.0p25.{ymd_str}{start_date.hour:0>2}.f{hours_from_start:0>3}.grib2"
        file_list.append(name)
        cur_date += delta

    return file_list


def sleep_some_random_time():
    sleep_time = 3 + random.randint(0, 7)
    print(f"Going to sleep {sleep_time} seconds. Current time is {time.ctime()}")
    time.sleep(sleep_time)


def process_file(dspath, file, gfs_dir, cookies):
    filename = dspath + file
    file_base = os.path.join(gfs_dir, os.path.basename(file))
    print(f'Downloading {file_base}')

    if not os.path.isfile(file_base):
        sleep_some_random_time()
        req = requests.get(filename, cookies=cookies, allow_redirects=True, stream=True)
        filesize = int(req.headers['Content-length'])
        print(f'File size is {filesize}')
        too_small_file_size = filesize < 2 ** 10

        tmp_filename = file_base + '_TMP'
        with open(tmp_filename, 'wb') as outfile:
            chunk_size = 1048576
            for chunk in req.iter_content(chunk_size=chunk_size):
                if too_small_file_size:
                    print(chunk)
                outfile.write(chunk)
                if chunk_size < filesize:
                    check_file_status(tmp_filename, filesize)
        check_file_status(tmp_filename, filesize)
        if too_small_file_size:
            raise RuntimeError("File size is too low!")
        os.rename(tmp_filename, file_base)
    else:
        print(f'OK: {file_base} exists.')
    print()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--wrf_root', type=str, required=True)
    parser.add_argument('--email', type=str, required=True)
    parser.add_argument('--pwd', type=str, required=True)
    parser.add_argument('--data_path', type=str, required=True)
    args = parser.parse_args()
    print(f'Script started at {time.ctime()}')

    url = 'https://rda.ucar.edu/cgi-bin/login'
    ret = requests.post(url, data={'email': args.email, 'passwd': args.pwd, 'action': 'login'})
    if ret.status_code != 200:
        print('Bad Authentication')
        print(ret.text)
        exit(1)
    else:
        print(f"Authentication successful: {url}")

    dspath = 'https://rda.ucar.edu/data/ds084.1/'

    with open(os.path.join(args.wrf_root, "wrf-tools/config/config.yml"), "r") as file:
        config = yaml.load(file, Loader=yaml.CLoader)

    max_retry_cnt = 20
    file_list = get_file_list_from_config(config)
    for file in file_list:
        for i in range(max_retry_cnt):
            try:
                process_file(dspath, file, args.data_path, ret.cookies)
            except BaseException as e:
                if i + 1 == max_retry_cnt:
                    raise e
                else:
                    print(f"Some exception happened {e}.")
                    sleep_some_random_time()
            else:
                break


if __name__ == '__main__':
    main()