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

def get_template_outgoingdepencies(testServer, templateName):
    url = testServer.get_thingtemplate_dependency_url(templateName)
    ret = requests.request("POST", url, headers=testServer.get_headers(),verify=testServer.validateSSL)
    oneleveldependencies = {}
    if ret.status_code == 200 and ret.text :
        jsondata = json.loads(ret.text)
        logging.info("Export List:{}".format(json.dumps(jsondata, indent = 2)))

        for row in jsondata['rows']:
            oneleveldependencies[row['name']] = row['type']
            logging.info("found:{}, type:{}".format(row['name'],row['type']))
    else:
        logging.info("Status Code:{} with message:{}".format(ret.status_code,ret.text))

    return oneleveldependencies


def downloadtodefaultname(testServer, twxType, twxName):
    url = testServer.get_twx_download_url(twxType, twxName)
    headers = testServer.get_headers()
    headers['Accept'] = 'text/xml'

    ret = requests.request("GET", url, headers=headers, verify=testServer.validateSSL)
    filename = os.path.join(testServer.otherConfigs['export_path'],twxName+".xml")

    ret.raise_for_status()
    with open(filename,'wb') as handle:
        for block in ret.iter_content(1024):
            handle.write(block)

    return filename

def collections(testServer):
    '''
    parser template name and value stream name from configuration file

    :param testServer:
    :return:
    '''

    dependencies = get_template_outgoingdepencies(testServer,testServer.otherConfigs['ThingTemplate'])
    with open(os.path.join(testServer.otherConfigs['export_path'], testServer.otherConfigs['export_config']),
              "w") as exportfile:
        writer = csv.writer(exportfile)
        writer.writerow(["Action","Entity","Comment"])

        #download dependencies
        for twxName, twxType in dependencies.items():
            fileName = downloadtodefaultname(testServer, twxType, twxName)
            logging.info("{} has been downloaded".format(fileName))

            writer.writerow(["Import",fileName,""])

        #download value stream
        if testServer.otherConfigs['ValueStream']:
            fileName = downloadtodefaultname(testServer, 'Thing', testServer.otherConfigs['ValueStream'])
            writer.writerow(["Import", fileName, ""])

        #download template
        fileName = downloadtodefaultname(testServer,'ThingTemplate',testServer.otherConfigs['ThingTemplate'])
        writer.writerow(["Import", fileName, ""])



    logging.info("CSV file has been written to:{}".format(
        os.path.join(testServer.otherConfigs['export_path'], testServer.otherConfigs['export_config'])
    ))



    #print(testServer.otherConfigs['export_path'])
    #print(testServer.otherConfigs['export_config'])

    #for key, value in testServer.otherConfigs.items():
    #    print("Key:{}".format(key))
    #    print("Value:{}".format(value))


def main():
    setup_log()
    testServer = get_server(parse_commandline())
    collections(testServer)


if __name__ == '__main__':
    main()