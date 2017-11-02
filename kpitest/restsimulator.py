import logging
import os
import requests
import json

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

    testServer.simulatorConfigurationFile = os.path.join(configurationpath,'simulatorconfig.xlsx')

    return testServer

def collections():

    setup_log()

    testServer = get_server(parse_commandline())

    templates = parseSimulatorConfig(testServer.simulatorConfigurationFile)

    # print(templates.keys())
    myThings={}

    for key, value in templates.items():
        logging.info('{}--->{}'.format(key, value))
        if not testServer.check_template(value.remoteTemplateName):
            logging.info("template {} with full name {} doesn't exist, bypass.".format(key,value.remoteTemplateName))
            continue

        for index in range(2):
            newThing = TWX_Thing(value.name + '_Simulator_{}'.format(index), value, testServer)
            myThings[newThing.name] = newThing
            if testServer.check_thing(newThing.name):
                newThing.created = True
                logging.info("Thing:{} exists on Server.".format(newThing.name))
            else:
                logging.info("Start to create thing:{}".format(newThing.name))
                if newThing.self_create_thing():
                    newThing.created = True
                    logging.info("Thing:{} created successfully.".format(newThing.name))
                else:
                    logging.info("Failed to Create Thing:{}".format(newThing.name))


    return myThings

def main():
    myThings = collections()

    for index in range(2):
        for key, thing in myThings.items():
            print("{}->Key:{}-->{}-->Thing:{}".format(index,key,thing.created,thing))
            updatedProperties = thing.next()
            for propertyName, propertyValue in updatedProperties.items():
                url = thing.server.get_thing_property_update_url(thing.name,propertyName)
                body = {
                    propertyName:propertyValue
                }
                logging.info("Update Property:{}".format(json.dumps(body,indent=2)))
                ret = requests.request("PUT",url, headers=thing.server.get_headers(),json=body, verify=thing.server.validateSSL)
                logging.info("Response:{} with text:{}".format(ret.status_code, ret.text))




if __name__ == '__main__':
    main()