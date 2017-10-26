import sys
import requests
import pytest
import os
import json
import logging
import allure

from kpitest.thingworx import  ThingworxServer
from .conftest import log_testcase,log_input,log_ret

@pytest.mark.order2
#@pytest.mark.incremental
@allure.feature("User Management")
class TestClass:

    @log_testcase
    def test_user_management_service_check(self, testServer):
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

    @log_testcase
    def test_CheckIfUserExists(self, testServer):
        url = testServer.get_thing_service('User_Management_Util','CheckIfUserExists')

        jsonbody={
            "UserId":"Administrator"
        }
        log_input(jsonbody)
        ret = requests.request('POST', url, headers=testServer.get_headers(),json=jsonbody, verify=testServer.validateSSL)
        log_ret(ret)

        assert(ret.status_code == 200)
        data = json.loads(ret.text)
        assert(data['rows'][0]['result']==True)
        jsonbody={
            "UserId":"FakeUser"
        }

        log_input(jsonbody)
        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=testServer.validateSSL)
        log_ret(ret)

        assert (ret.status_code == 200)
        data = json.loads(ret.text)
        assert (data['rows'][0]['result'] == False)

    @log_testcase
    def test_CreateNewUser(self,testServer):
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
        log_input(jsonbody)
        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=testServer.validateSSL)
        log_ret(ret)

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
        log_input(jsonbody)
        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=testServer.validateSSL)
        log_ret(ret)

        assert (ret.status_code == 200)

    @log_testcase
    def test_ModifyUserByUserId(self, testServer):
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

        log_input(jsonbody)
        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=testServer.validateSSL)
        log_ret(ret)

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

        log_input(jsonbody)
        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=testServer.validateSSL)
        log_ret(ret)

        assert (ret.status_code == 500)

    @log_testcase
    def test_DeleteUserById(self,testServer):
        url = testServer.get_thing_service('User_Management_Util', 'DeleteUserById')

        jsonbody = {
            "UserId": "xds"
        }

        log_input(jsonbody)
        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=testServer.validateSSL)
        log_ret(ret)
        assert (ret.status_code == 200)

        jsonbody = {
            "UserId": "xds"
        }

        log_input(jsonbody)
        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=testServer.validateSSL)
        log_ret(ret)
        assert (ret.status_code == 500)
