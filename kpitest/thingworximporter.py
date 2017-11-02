import logging
import os
import requests
import json
import csv

from .twxthing import TWX_Thing, TWX_Property,TWX_Template
from .twxexcelparser import parseSimulatorConfig

from .helper import setup_log,parse_commandline
from .thingworx import ThingworxServer

def get_server(args):
    configurationpath = args.config_path
    configurationfile = args.config
    testServer = ThingworxServer.fromConfigurationFile(os.path.join(configurationpath, configurationfile))
    testServer.validateSSL = args.sslvalidation
    #print("sslvalidation:{}".format(testServer.validateSSL))
    testServer.otherConfigs['export_path'] = args.export_path
    testServer.otherConfigs['export_config'] = args.export_config


    testServer.simulatorConfigurationFile = os.path.join(configurationpath,'simulatorconfig.xlsx')

    return testServer

def load_files(testServer):
    loadfilespath = testServer.otherConfigs['export_path']
    loadfilename = testServer.otherConfigs['export_config']

    loadfileslist = os.path.join(loadfilespath, loadfilename)

    if not os.path.exists(loadfileslist):
        raise ValueError("Can't find list file:{}".format(loadfileslist))

    with open(loadfileslist, "r") as infile:
        reader = csv.DictReader(infile)
        for row in reader:
            # ensure header is bypast
            logging.info("Processing: {},{},{}".format(row['Action'], row['Entity'], row['Comment']))
            ret = None
            if row['Action'].startswith('Delete'):
                ret = testServer.delete_entity(row['Action'], row['Entity'])

            if row['Action'] == 'Import':
                ret = testServer.import_file(os.path.join(loadfilespath, row['Entity']))

            logging.info("Response:{}".format(ret))
            if ret.status_code == 200:
                logging.info("{} has been loaded".format(row['Entity']))
            else:
                logging.info("{} is failed to load".format(row['Entity']))
                print("{} is failed to load".format(row['Entity']))
                return

def main():
    setup_log()
    testServer = get_server(parse_commandline())
    load_files(testServer)


if __name__ == '__main__':
    main()