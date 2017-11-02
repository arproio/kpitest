
import random
from .twxproperty import TWX_Property
from .twxtemplate import TWX_Template
from .thingworx import ThingworxServer
import copy
import requests
import json
import logging

class TWX_Thing():
    def __init__(self,name,template,server):
        self.name=name
        self.template = template
        self.server = server
        self.created = False
        self.defaultValues={}

    def get_valuestream(self):
        valuestreams={
            'TT_VS_RTTFT_VR86001X': 'VS_VR8600-1X',
            'TT_VS_RTTFT_VS95TS_V_0_0_1': 'VS_VS95TS',
            'TT_VS_RTTFT_VR8600E_V_0_0_1': 'VS_VR8600-E',
            'TT_VS_RDB_VPP3002':'VS_VPP3002'
        }
        return valuestreams[self.template.remoteTemplateName]

    def build_default_value(self):
        for key, property in self.template.allProperties.items():
            if property.binaryType: # 0 or 1
                self.defaultValues[property.name] = 0
            elif property.intType:
                if property.selectType:
                    self.defaultValues[property.name] = \
                        property.selectValues[random.randint(0,len(property.selectValues)-1)]
                elif property.incrementalType:
                    self.defaultValues[property.name] = 0   # start from 0.
                else:
                    self.defaultValues[property.name] = random.randint(property.minValue,property.maxValue)
            else:   #float
                self.defaultValues[property.name] = random.uniform(property.minValue,property.maxValue)

    def get_property_value(self,property, previousValue):
        if property.incrementalType:
            return previousValue + 1

        currentValue = None

        if property.binaryType:  # 0 or 1
            if random.random() > 0.5:
                currentValue = 1
            else:
                currentValue = 0

        elif property.intType:
            if property.selectType:
                currentValue = \
                    property.selectValues[random.randint(0, len(property.selectValues) - 1)]
            else:
                currentValue = random.randint(property.minValue, property.maxValue)
        else:  # float
            currentValue = random.uniform(property.minValue, property.maxValue)

        return currentValue

    def self_create_thing(self):
        url = self.server.get_create_thing_url()

        # print('url:{}'.format(url))
        headers = self.server.get_headers()

        body = {
            'name': self.name,
            'description': 'This is a test from my python code',
            'thingTemplateName': self.template.remoteTemplateName
        }

        logging.info("Create Thing Input:{}".format(json.dumps(body,indent=2)))

        # create thing with basic info
        ret = requests.request('POST', url, json=body, headers=headers, verify=self.server.validateSSL)
        logging.info("Create Thing Status:{}, TEXT:{}".format(ret.status_code,ret.text))

        # Enable Thing
        if ret.status_code == 200:
            url = self.server.get_thing_service_url(self.name,'EnableThing')
            ret = requests.request("POST", url, headers=headers, verify=self.server.validateSSL)
            logging.info('EnableThing-Status code:{}'.format(ret.status_code))

        # Restart Thing
        if ret.status_code == 200:
            url = self.server.get_thing_service_url(self.name, 'RestartThing')
            #url = "https://gateway.desheng.io/Thingworx/Things/myPythonThing/Services/RestartThing"
            ret = requests.request("POST", url, headers=headers, verify=self.server.validateSSL)
            logging.info('RestartThing-Status code:{}'.format(ret.status_code))

        # assign Value Stream
        if ret.status_code == 200:
            url = self.server.get_thing_service_url(self.name, 'SetValueStream')
            #url = "https://gateway.desheng.io/Thingworx/Things/myPythonThing/Services/SetValueStream"
            body_valuestream = {
                'name': self.get_valuestream()
            }

            ret = requests.request("POST", url, json=body_valuestream, headers=headers, verify=self.server.validateSSL)
            logging.info('AddValueStream-Status code:{}'.format(ret.status_code))

        return ret.status_code == 200

    def next(self):
        updatedProperties = {}
        if not self.defaultValues:   #first time.
            self.build_default_value()
            updatedProperties =  copy.deepcopy(self.defaultValues)
            return updatedProperties

        for key in self.template.simulateList:
            # we start to simulate them.
            property = self.template.allProperties[key]
            if random.random() <= property.chance:
                previousValue = self.defaultValues[key]
                currentValue = self.get_property_value(property,previousValue)
                self.defaultValues[key] = currentValue
                updatedProperties[key] = currentValue

        #defal with follow up property
        for key in self.template.followedList:
            property = self.template.allProperties[key]
            if property.follow in updatedProperties.keys():
                #folloed property has changed.
                previousValue = self.defaultValues[key]
                currentValue = self.get_property_value(property, previousValue)
                self.defaultValues[key] = currentValue
                updatedProperties[key] = currentValue

        return updatedProperties



    def __str__(self):
        str = self.name + " -> template:" + self.template.remoteTemplateName
        for key, value in self.defaultValues.items():
            str += "\n\t{}:{}".format(key,value)

        return str




