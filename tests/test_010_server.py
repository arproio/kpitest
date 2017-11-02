# -*- coding: utf-8 -*-

import pytest
import requests
import sys
import os
import json
import csv

from kpitest.thingworx import ThingworxServer

import logging
from .conftest import log_testcase
import allure

@pytest.mark.order1
@pytest.mark.incremental
@allure.feature("Server Management")
class TestClass:
    def get_configuration_file(self):
        return "config/gateway.json"

    @log_testcase
    @allure.step(title="check configuration file")
    def test_existance_configurationfile(self,configurationfile,configurationpath,loadfilespath,loadfiles):
        logging.info("loadfiles:{}".format(loadfiles))
        logging.info("loadfiles path:{}".format(loadfilespath))
        logging.info("configuration path:{}".format(configurationpath))
        logging.info("configuration file:{}".format(configurationfile))

        assert(os.path.exists(os.path.join(configurationpath,configurationfile)))
        if loadfiles:
            assert(os.path.exists(loadfilespath))

    @allure.step(title="check server url components")
    def test_server(self,testServer):
        assert(testServer)
        assert(testServer.configuration['server'])
        assert(testServer.configuration['port'])
        assert(testServer.configuration['protocol'])

        testServer = ThingworxServer.fromConfiguration('gateway.desheng.io',443,'fakeKey','https')
        assert (testServer)
        assert (testServer.configuration['server'])
        assert (testServer.configuration['port'])
        assert (testServer.configuration['protocol'])

    @allure.step(title="check default headers components")
    def test_server_headers(self,testServer):
        assert (testServer)
        headers = testServer.get_headers()
        assert(headers['cache-control']=='no-cache')
        assert(headers['Content-Type']=='application/json')
        assert(headers['Accept']=='application/json')

    @allure.step(title="check server url completeness")
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

    @log_testcase
    @allure.step(title="try to get all things as list from server")
    def test_get_things(self, testServer):
        ret = testServer.get_things()
        assert(ret.status_code==200)

        data = json.loads(ret.text)
        assert(len(data['rows'])>300)
        assert(data['dataShape'])

    @log_testcase
    @allure.step(title="check template exists or not")
    def test_check_template(self,testServer):
        assert(testServer.check_template('GenericThing'))

    @log_testcase
    @allure.step(title="check thing exists or not")
    def test_check_thing(self, testServer):
        assert (testServer.check_thing('AlertHistoryStream'))


    @log_testcase
    @allure.step(title="try to load all files required")
    def test_import_files(self, testServer,loadfilespath,loadfiles):
        if not loadfiles:
            logging.info("Bypass file loading......")
            return    # don't load files

        assert(os.path.exists(loadfilespath))
        loadfileslist=os.path.join(loadfilespath,"load_files_list.csv")
        assert(os.path.exists(loadfileslist))

        with open(loadfileslist, "r") as infile:
            reader = csv.DictReader(infile)
            for row in reader:
                #ensure header is bypast
                logging.info("Processing: {},{},{}".format(row['Action'], row['Entity'], row['Comment']))
                ret = None
                if row['Action'].startswith('Delete'):
                    ret = testServer.delete_entity(row['Action'],row['Entity'])

                if row['Action']=='Import':
                    ret = testServer.import_file(os.path.join(loadfilespath,row['Entity']))

                logging.info("Response:{}".format(ret))
                assert(ret.status_code == 200)
