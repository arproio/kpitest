import sys
import requests
import pytest
import os
import json
import logging

from kpitest.thingworx import  ThingworxServer
from .conftest import log_testcase,log_ret,log_input

#@pytest.mark.incremental
class TestClass:
    @log_testcase
    def test_RetrieveAllAlertsByUserId(self, testServer):
        url = testServer.get_thing_service('Alert_Management_Util','RetrieveAllAlertsByUserId')

        jsonbody={
            "UserId":"Administrator",
            "HistoricalDays":30
        }
        log_input(jsonbody)
        ret = requests.request('POST', url, headers=testServer.get_headers(),json=jsonbody, verify=testServer.validateSSL)
        log_ret(ret)

        assert(ret.status_code == 200)
        data = json.loads(ret.text)
        #assert(len(data['rows'])>0)

        jsonbody={
            "UserId":"FakeUser"
        }
        log_input(jsonbody)
        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=testServer.validateSSL)
        log_ret(ret)

        assert (ret.status_code == 200)
        data = json.loads(ret.text)
        assert (len(data['rows'])==0)

    @log_testcase
    def test_RetrieveConfiguredAlertsByAssetId(self, testServer):
        url = testServer.get_thing_service('Alert_Management_Util','RetrieveConfiguredAlertsByAssetId')

        jsonbody={
            "AssetInfo": [
                {"assetId": "asset1", "lineId": "line1", "LineName": "linename1"},
                {"assetId":"asset2", "lineId": "line2", "LineName": "linename2"}
            ]
        }
        log_input(jsonbody)
        ret = requests.request('POST', url, headers=testServer.get_headers(),json=jsonbody, verify=testServer.validateSSL)
        log_ret(ret)

        assert(ret.status_code == 200)
        data = json.loads(ret.text)
        assert(len(data['rows'])>0)

        jsonbody = {
            "AssetInfo": [
                {"assetId": "fake1", "lineId": "line1", "LineName": "linename1"},
                {"assetId": "fake2", "lineId": "line2", "LineName": "linename2"}
            ]
        }
        log_input(jsonbody)
        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=testServer.validateSSL)
        log_ret(ret)

        assert (ret.status_code == 200)
        data = json.loads(ret.text)
        assert (len(data['rows'])==0)

    @log_testcase
    def test_RetrieveConfiguredAlertsByLineId(self, testServer):
        url = testServer.get_thing_service('Alert_Management_Util','RetrieveConfiguredAlertsByLineId')

        jsonbody={"LineInfo": [
            {"LineId": "LineId1", "LineName": "LineName1"},
            {"LineId":"LineId2", "LineName": "LineName2"}
            ]
        }
        log_input(jsonbody)
        ret = requests.request('POST', url, headers=testServer.get_headers(),json=jsonbody, verify=testServer.validateSSL)
        log_ret(ret)

        assert(ret.status_code == 200)
        data = json.loads(ret.text)
        assert(len(data['rows'])>0)

        jsonbody = {"LineInfo": [
            {"LineId": "Fake01", "LineName": "LineName1"},
            {"LineId":"Fake02", "LineName": "LineName2"}
            ]
        }
        log_input(jsonbody)
        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=testServer.validateSSL)
        log_ret(ret)

        assert (ret.status_code == 200)
        data = json.loads(ret.text)
        assert (len(data['rows'])==0)

    @log_testcase
    def test_SubscribeToAlertByUserIdAssetId(self, testServer):
        url = testServer.get_thing_service('Alert_Management_Util','SubscribeToAlertByUserIdAssetId')

        jsonbody={"SubscriptionInfo": [
            {"userId": "p54284",
             "alertId": "Asset_RT_RTTFT_VR8600E_0724366--param_sealvoltage--Voltagetoohigh",
             "assetId": "Asset_RT_RTTFT_VR8600E_0724366"}
        ]}
        log_input(jsonbody)
        ret = requests.request('POST', url, headers=testServer.get_headers(),json=jsonbody, verify=testServer.validateSSL)
        log_ret(ret)

        assert(ret.status_code == 200)

        jsonbody = {"SubscriptionInfo": [
            {"userId": "fake",
             "alertId": "Asset_RT_RTTFT_VR8600E_0724366--param_sealvoltage--Voltagetoohigh",
             "assetId": "Asset_RT_RTTFT_VR8600E_0724366"}
        ]}
        log_input(jsonbody)
        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=testServer.validateSSL)
        log_ret(ret)

        assert (ret.status_code == 500)

    @log_testcase
    def test_SubscribeToAlertByUserIdLineId(self, testServer):
        url = testServer.get_thing_service('Alert_Management_Util','SubscribeToAlertByUserIdLineId')

        jsonbody={
            "SubscriptionInfo": [
                {
                    "userId": "p54284",
                    "alertId":"Asset_RT_RTTFT_VR8600E_0724366--param_sealvoltage--Voltagetoohigh--1--p54284",
                    "lineId": "1"}
            ]}
        log_input(jsonbody)
        ret = requests.request('POST', url, headers=testServer.get_headers(),json=jsonbody, verify=testServer.validateSSL)
        log_ret(ret)

        assert(ret.status_code == 200)

        jsonbody = {
            "SubscriptionInfo": [
                {
                    "userId": "fake",
                    "alertId": "Asset_RT_RTTFT_VR8600E_0724366--param_sealvoltage--Voltagetoohigh--1--p54284",
                    "lineId": "1"}
            ]}
        log_input(jsonbody)
        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=testServer.validateSSL)
        log_ret(ret)

        assert (ret.status_code == 500)

    @log_testcase
    def test_UnsubscribeFromAlertByUserIdAssetId(self, testServer):
        url = testServer.get_thing_service('Alert_Management_Util','UnsubscribeFromAlertByUserIdAssetId')

        jsonbody={
            "SubscriptionInfo": [
                {
                    "userId": "p54284",
                    "alertId": "Asset_RT_RTTFT_VR8600E_0724366--param_sealvoltage--Voltagetoohigh",
                    "assetId": "Asset_RT_RTTFT_VR8600E_0724366"}
            ]}
        log_input(jsonbody)
        ret = requests.request('POST', url, headers=testServer.get_headers(),json=jsonbody, verify=testServer.validateSSL)
        log_ret(ret)

        assert(ret.status_code == 200)

        jsonbody = {
            "SubscriptionInfo": [
                {
                    "userId": "fake",
                    "alertId": "Asset_RT_RTTFT_VR8600E_0724366--param_sealvoltage--Voltagetoohigh",
                    "assetId": "Asset_RT_RTTFT_VR8600E_0724366"}
            ]}
        log_input(jsonbody)
        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=testServer.validateSSL)
        log_ret(ret)

        assert (ret.status_code == 500)

    @log_testcase
    def test_UnsubscribeFromAlertByUserIdLineId(self, testServer):
        url = testServer.get_thing_service('Alert_Management_Util','UnsubscribeFromAlertByUserIdLineId')

        jsonbody={
            "SubscriptionInfo": [
                {
                    "userId": "p54284",
                    "alertId": "Asset_RT_RTTFT_VR8600E_0724366--param_sealvoltage--Voltagetoohigh--1--p54284",
                    "lineId": "1"}
            ]}
        log_input(jsonbody)
        ret = requests.request('POST', url, headers=testServer.get_headers(),json=jsonbody, verify=testServer.validateSSL)
        log_ret(ret)

        assert(ret.status_code == 200)

        jsonbody = {
            "SubscriptionInfo": [
                {
                    "userId": "fake",
                    "alertId": "Asset_RT_RTTFT_VR8600E_0724366--param_sealvoltage--Voltagetoohigh--1--p54284",
                    "lineId": "1"}
            ]}
        log_input(jsonbody)
        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=testServer.validateSSL)
        log_ret(ret)

        assert (ret.status_code == 500)