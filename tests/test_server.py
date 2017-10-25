# -*- coding: utf-8 -*-

import pytest
import requests
import sys
import os
import json

from kpitest.thingworx import ThingworxServer

import logging

@pytest.mark.incremental
class TestClass:
    def get_configuration_file(self):
        return "config/gateway.json"

    def test_existance_configurationfile(self,configurationfile,configurationpath,loadfilespath,loadfiles):
        logging.info("loadfiles:{}".format(loadfiles))
        logging.info("loadfiles path:{}".format(loadfilespath))
        logging.info("configuration path:{}".format(configurationpath))
        logging.info("configuration file:{}".format(configurationfile))

        assert(os.path.exists(os.path.join(configurationpath,configurationfile)))
        if loadfiles:
            assert(os.path.exists(loadfilespath))

    def test_server(self,configurationfile,configurationpath,loadfilespath,loadfiles):
        testServer = ThingworxServer.fromConfigurationFile(os.path.join(configurationpath, configurationfile))
        assert(testServer)
        assert(testServer.configuration['server'])
        assert(testServer.configuration['port'])
        assert(testServer.configuration['protocol'])

        testServer = ThingworxServer.fromConfiguration('gateway.desheng.io',443,'fakeKey','https')
        assert (testServer)
        assert (testServer.configuration['server'])
        assert (testServer.configuration['port'])
        assert (testServer.configuration['protocol'])

    def test_server_headers(self, configurationfile,configurationpath,loadfilespath,loadfiles):
        testServer = ThingworxServer.fromConfigurationFile(os.path.join(configurationpath, configurationfile))
        assert (testServer)
        headers = testServer.get_headers()
        assert(headers['cache-control']=='no-cache')
        assert(headers['Content-Type']=='application/json')
        assert(headers['Accept']=='application/json')

    def test_service_url(self, configurationfile,configurationpath,loadfilespath,loadfiles):
        testServer = ThingworxServer.fromConfigurationFile(os.path.join(configurationpath, configurationfile))
        assert (testServer)
        with open(os.path.join(configurationpath,configurationfile),"r") as datafile:
            jsondata = json.load(datafile)
            thingName = 'fakeThing'
            serviceName = 'fakeService'
            fakeurl='{}://{}:{}/Thingworx/Things/{}/services/{}'.format(jsondata['protocol'],
                                                                        jsondata['server'],
                                                                        jsondata['port'],
                                                                        thingName,
                                                                        serviceName)
            assert(testServer.get_thing_service(thingName,serviceName) == fakeurl)

    def test_get_things(self, configurationfile,configurationpath,loadfilespath,loadfiles):
        testServer = ThingworxServer.fromConfigurationFile(os.path.join(configurationpath, configurationfile))
        ret = testServer.get_things()
        assert(ret.status_code==200)

        data = json.loads(ret.text)
        assert(len(data['rows'])>300)
        assert(data['dataShape'])