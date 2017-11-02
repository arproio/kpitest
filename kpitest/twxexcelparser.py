import pandas as pd
import numpy as np

import logging
import os

from .twxthing import TWX_Thing, TWX_Property,TWX_Template
from .helper import setup_log
from .thingworx import ThingworxServer

def parseSimulatorConfig(excel_config_file):
    ec = pd.ExcelFile(excel_config_file)
    templates = {}  #{name, template}

    for sheet in ec.sheet_names:

        df = (ec.parse(sheet)).replace(np.nan,'',regex=True)
        cols = list(df.columns.values)

        newTemplate = TWX_Template(name=sheet)
        new_remote_name = None

        for index, row in df.iterrows():
            rowdict = dict(zip(cols,row))
            new_remote_name = row['TemplateName']

            newProperty = TWX_Property(row['propertyName'],**rowdict)
            #logging.info(newProperty)

            newTemplate.allProperties[newProperty.name] = newProperty
            if newProperty.simulate and not newProperty.follow:
                newTemplate.simulateList.append(newProperty.name)
            elif newProperty.simulate and newProperty.follow:
                newTemplate.followedList.append(newProperty.name)

        if new_remote_name:
            #set template name correctly
            newTemplate.set_remote_template_name(new_remote_name)

        templates[newTemplate.name]=newTemplate

    return templates


if __name__=='__main__':
    setup_log()

    dir_path = os.path.dirname(os.path.realpath(__file__))
    configfile = os.path.join(dir_path,"..","config","sealedair-dev.json")
    testServer = ThingworxServer.fromConfigurationFile(configfile)

    excelfile = os.path.join(dir_path,"..","config","simulatorconfig.xlsx")

    templates=parseSimulatorConfig(excelfile)
    #print(templates.keys())
    for key, value in templates.items():
        #logging.info('{}--->{}'.format(key,value))
        newThing = TWX_Thing(value.name +"_01", value, testServer)
        #logging.info('{} ---> Thing ---> {}'.format(key,newThing))
        for index in range(5):
            logging.info("")
            logging.info("{} --> {}".format(index, newThing.name))
            logging.info("Updated Properties:{}".format(newThing.next()))
            logging.info("")
            logging.info("")
