import os
import yaml
import argparse
from datetime import datetime
from jinja2 import Environment, FileSystemLoader

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--wrf_root', type=str)
    parsed_args = parser.parse_args()

    env = Environment(loader=FileSystemLoader(os.path.join(parsed_args.wrf_root, 'wrf-tools/templates')))
    template_wps = env.get_template('template_namelist.wps')
    template_wrf = env.get_template('template_namelist.input')

    with open(os.path.join(parsed_args.wrf_root, 'wrf-tools/config.yml'), "r") as file:
        config = yaml.load(file, Loader=yaml.CLoader)

    time = {key: config['time'][key] for key in config['time']}
    geogrid = {key: config['geogrid'][key] for key in config['geogrid']}
    domains = {key: ",".join([str(dom[key]) for dom in config['domains']]) for key in config['domains'][0].keys()}
    physics = {key: config["physics"][key] for key in config["physics"]}
    dynamics = {key: config["dynamics"][key] for key in config["dynamics"]}

    config_wps = template_wps.render({**time, **geogrid, **domains})
    with open(os.path.join(parsed_args.wrf_root, 'build/WPS', 'namelist.wps'), "w") as file:
        file.write(config_wps)

    start_date = datetime.strptime(config["time"]["START_DATE"], '%Y-%m-%d_%H:%M:%S')
    end_date = datetime.strptime(config["time"]["END_DATE"], '%Y-%m-%d_%H:%M:%S')
    delta = end_date - start_date
    time["RUN_DAYS"] = delta.days
    time["RUN_SECONDS"] = delta.seconds
    time["START_YEAR"] = start_date.year
    time["START_MONTH"] = start_date.month
    time["START_DAY"] = start_date.day
    time["START_HOUR"] = start_date.hour
    time["END_YEAR"] = end_date.year
    time["END_MONTH"] = end_date.month
    time["END_DAY"] = end_date.day
    time["END_HOUR"] = end_date.hour
    config_wrf = template_wrf.render({**time, **geogrid, **domains, **physics, **dynamics})
    with open(os.path.join(parsed_args.wrf_root, 'build/WRF/run', 'namelist.input'), "w") as file:
        file.write(config_wrf)
