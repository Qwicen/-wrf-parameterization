import os
import glob
import argparse

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--data_wps_dir', type=str, required=True)
    parser.add_argument('--wps_dir', type=str, required=True)
    args = parser.parse_args()

    paths = glob.glob(f"{args.data_wps_dir}/FILE*")

    for path in paths:
        filename = os.path.basename(path)
        wps_filename = f"{args.wps_dir}/{filename}"
        os.symlink(path, wps_filename)
    print("Ungrib data linked successfully")

main()