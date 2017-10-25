import sys
import requests
import pytest
import os
import json
import logging

from kpitest.thingworx import  ThingworxServer

#@pytest.mark.incremental
class TestClass:
    def setup_method(self, method):
        #self.testServer = ThingworxServer.fromConfigurationFile(os.path.join(configurationpath,configurationfile))
        #self.dir_path = os.path.dirname(os.path.realpath(__file__))
        #logging.info("full path:{}".format(os.path.join(configurationpath,configurationfile)))
        pass

    def test_import_user_management_service(self, configurationfile,configurationpath,loadfilespath,loadfiles):
        if not loadfiles:
            logging.info("Bypass file loading......")
            return    # don't load files

        testServer=ThingworxServer.fromConfigurationFile(os.path.join(configurationpath,configurationfile))
        for file in os.listdir(loadfilespath):
            filename = os.fsdecode(file)
            logging.info("checking file name:{}".format(filename))
            if filename.endswith(".xml") or filename.endswith(".twx"):
                logging.info("start to import:{}".format(filename))

                ret = testServer.import_file(os.path.join(loadfilespath,filename))
                assert(ret.status_code == 200)
                assert(ret.text == "success")

    def test_user_management_service_check(self, configurationfile,configurationpath,loadfilespath,loadfiles):

        testServer = ThingworxServer.fromConfigurationFile(os.path.join(configurationpath, configurationfile))
        ret = testServer.get_things()
        assert(ret.status_code == 200)
        assert(ret.text)
        thingsdata = json.loads(ret.text)
        found_userutil=False
        found_alertutil=False

        for i in range(len(thingsdata['rows'])):
            row = thingsdata['rows'][i]
            if row['name'] == 'User_Management_Util':
                found_userutil = True

            if row['name'] == 'Alert_Management_Util':
                found_alertutil = True

            if found_alertutil and found_userutil:
                break

        assert(found_alertutil)
        assert(found_userutil)

    def test_CheckIfUserExists(self, configurationfile,configurationpath):
        testServer = ThingworxServer.fromConfigurationFile(os.path.join(configurationpath, configurationfile))
        url = testServer.get_thing_service('User_Management_Util','CheckIfUserExists')

        jsonbody={
            "UserId":"Administrator"
        }
        ret = requests.request('POST', url, headers=testServer.get_headers(),json=jsonbody, verify=False)
        logging.info("test user id:Administrator, status_code:{}, text:{}".format(ret.status_code,
                                                                                  ret.text))

        assert(ret.status_code == 200)
        data = json.loads(ret.text)
        assert(data['rows'][0]['result']==True)
        jsonbody={
            "UserId":"FakeUser"
        }
        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=False)
        logging.info("test user id:FakeUser, status_code:{}, text:{}".format(ret.status_code,
                                                                                  ret.text))

        assert (ret.status_code == 200)
        data = json.loads(ret.text)
        assert (data['rows'][0]['result'] == False)

    def test_CreateNewUser(self,configurationfile,configurationpath):
        testServer = ThingworxServer.fromConfigurationFile(os.path.join(configurationpath, configurationfile))
        url = testServer.get_thing_service('User_Management_Util', 'CreateNewUser')

        jsonbody = {
            "UserId": "Administrator",
            "ClientId":"001",
            "Email":"xds@gmail.com",
            "FirstName":"Desheng",
            "LastName":"NotXu",
            "Phone":"123-465-7890",
            "Language":"zh_CN",
            "EmailPreference":True,
            "PhonePreference":False
        }

        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=False)
        logging.info("test user id:Administrator, status_code:{}, text:{}".format(ret.status_code,
                                                                                  ret.text))
        assert (ret.status_code == 500)
        #data = json.loads(ret.text)
        #assert (data['rows'][0]['result'] == True)

        jsonbody = {
            "UserId": "xds",
            "ClientId": "001",
            "Email": "xds@gmail.com",
            "FirstName": "Desheng",
            "LastName": "NotXu",
            "Phone": "123-465-7890",
            "Language": "zh_CN",
            "EmailPreference": True,
            "PhonePreference": False
        }

        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=False)
        logging.info("test user id:xds, status_code:{}, text:{}".format(ret.status_code,
                                                                                  ret.text))
        assert (ret.status_code == 200)

    def test_ModifyUserByUserId(self, configurationfile, configurationpath):
        testServer = ThingworxServer.fromConfigurationFile(os.path.join(configurationpath, configurationfile))
        url = testServer.get_thing_service('User_Management_Util', 'ModifyUserByUserId')

        jsonbody = {
            "UserId": "xds",
            "ClientId": "002",
            "Email": "xds@gmail.com",
            "FirstName": "Desheng",
            "LastName": "NotSameXu2",
            "Phone": "123-465-7890",
            "Language": "zh_CN",
            "EmailPreference": "false",
            "PhonePreference": "true"
        }

        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=False)
        logging.info("modify test user id:xds, status_code:{}, text:{}".format(ret.status_code,
                                                                                  ret.text))
        assert (ret.status_code == 200)
        # data = json.loads(ret.text)
        # assert (data['rows'][0]['result'] == True)

        jsonbody = {
            "UserId": "xds001",
            "ClientId": "001",
            "Email": "xds@gmail.com",
            "FirstName": "Desheng",
            "LastName": "NotXu",
            "Phone": "123-465-7890",
            "Language": "zh_CN",
            "EmailPreference": True,
            "PhonePreference": False
        }

        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=False)
        logging.info("modify fake test user id:xds001, status_code:{}, text:{}".format(ret.status_code,
                                                                        ret.text))
        assert (ret.status_code == 500)

    def test_DeleteUserById(self,configurationfile,configurationpath):
        testServer = ThingworxServer.fromConfigurationFile(os.path.join(configurationpath, configurationfile))
        url = testServer.get_thing_service('User_Management_Util', 'DeleteUserById')

        jsonbody = {
            "UserId": "xds"
        }

        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=False)
        logging.info("First delete test user id:xds, status_code:{}, text:{}".format(ret.status_code,
                                                                                  ret.text))
        assert (ret.status_code == 200)

        jsonbody = {
            "UserId": "xds"
        }

        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=False)
        logging.info("Second delete test user id:xds, status_code:{}, text:{}".format(ret.status_code,
                                                                                  ret.text))
        assert (ret.status_code == 500)
