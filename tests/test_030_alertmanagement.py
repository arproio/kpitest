import sys
import requests
import pytest
import os
import json
import logging

from kpitest.thingworx import  ThingworxServer

#@pytest.mark.incremental
class TestClass:
    def test_RetrieveAllAlertsByUserId(self, configurationfile,configurationpath):
        testServer = ThingworxServer.fromConfigurationFile(os.path.join(configurationpath, configurationfile))
        url = testServer.get_thing_service('Alert_Management_Util','RetrieveAllAlertsByUserId')

        jsonbody={
            "UserId":"Administrator",
            "HistoricalDays":30
        }
        ret = requests.request('POST', url, headers=testServer.get_headers(),json=jsonbody, verify=False)
        logging.info("test test_RetrieveAllAlertsByUserId id:Administrator, status_code:{}, text:{}".format(ret.status_code,
                                                                                  ret.text))

        assert(ret.status_code == 200)
        data = json.loads(ret.text)
        #assert(len(data['rows'])>0)

        jsonbody={
            "UserId":"FakeUser"
        }
        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=False)
        logging.info("test test_RetrieveAllAlertsByUserId id:FakeUser, status_code:{}, text:{}".format(ret.status_code,
                                                                                  ret.text))

        assert (ret.status_code == 200)
        data = json.loads(ret.text)
        assert (len(data['rows'])==0)

    def test_RetrieveConfiguredAlertsByAssetId(self, configurationfile,configurationpath):
        testServer = ThingworxServer.fromConfigurationFile(os.path.join(configurationpath, configurationfile))
        url = testServer.get_thing_service('Alert_Management_Util','RetrieveConfiguredAlertsByAssetId')

        jsonbody={
            "AssetInfo": [
                {"assetId": "asset1", "lineId": "line1", "LineName": "linename1"},
                {"assetId":"asset2", "lineId": "line2", "LineName": "linename2"}
            ]
        }
        ret = requests.request('POST', url, headers=testServer.get_headers(),json=jsonbody, verify=False)
        logging.info("test assetInfo with asset1 and asset2, status_code:{}, text:{}".format(ret.status_code,
                                                                                  ret.text))

        assert(ret.status_code == 200)
        data = json.loads(ret.text)
        assert(len(data['rows'])>0)

        jsonbody = {
            "AssetInfo": [
                {"assetId": "fake1", "lineId": "line1", "LineName": "linename1"},
                {"assetId": "fake2", "lineId": "line2", "LineName": "linename2"}
            ]
        }
        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=False)
        logging.info("test assetInfo with fake1 and fake2, status_code:{}, text:{}".format(ret.status_code,
                                                                                  ret.text))

        assert (ret.status_code == 200)
        data = json.loads(ret.text)
        assert (len(data['rows'])==0)

    def test_RetrieveConfiguredAlertsByLineId(self, configurationfile,configurationpath):
        testServer = ThingworxServer.fromConfigurationFile(os.path.join(configurationpath, configurationfile))
        url = testServer.get_thing_service('Alert_Management_Util','RetrieveConfiguredAlertsByLineId')

        jsonbody={"LineInfo": [
            {"LineId": "LineId1", "LineName": "LineName1"},
            {"LineId":"LineId2", "LineName": "LineName2"}
            ]
        }
        logging.info("converted JSON:{}".format(json.dumps(jsonbody, indent=2)))
        ret = requests.request('POST', url, headers=testServer.get_headers(),json=jsonbody, verify=False)
        logging.info("test LineID with LineId1 and LineId2, status_code:{}, text:{}".format(ret.status_code,
                                                                                  ret.text))

        assert(ret.status_code == 200)
        data = json.loads(ret.text)
        assert(len(data['rows'])>0)

        jsonbody = {"LineInfo": [
            {"LineId": "Fake01", "LineName": "LineName1"},
            {"LineId":"Fake02", "LineName": "LineName2"}
            ]
        }
        logging.info("converted JSON:{}".format(json.dumps(jsonbody, indent=2)))
        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=False)
        logging.info("test LineID with fake1 and fake2, status_code:{}, text:{}".format(ret.status_code,
                                                                                  ret.text))

        assert (ret.status_code == 200)
        data = json.loads(ret.text)
        assert (len(data['rows'])==0)

    def test_SubscribeToAlertByUserIdAssetId(self, configurationfile,configurationpath):
        testServer = ThingworxServer.fromConfigurationFile(os.path.join(configurationpath, configurationfile))
        url = testServer.get_thing_service('Alert_Management_Util','SubscribeToAlertByUserIdAssetId')

        jsonbody={"SubscriptionInfo": [
            {"userId": "p54284",
             "alertId": "Asset_RT_RTTFT_VR8600E_0724366--param_sealvoltage--Voltagetoohigh",
             "assetId": "Asset_RT_RTTFT_VR8600E_0724366"}
        ]}
        logging.info("converted JSON:{}".format(json.dumps(jsonbody, indent=2)))
        ret = requests.request('POST', url, headers=testServer.get_headers(),json=jsonbody, verify=False)
        logging.info("test SubscriptionInfo with p54284, status_code:{}, text:{}".format(ret.status_code,
                                                                                  ret.text))

        assert(ret.status_code == 200)

        jsonbody = {"SubscriptionInfo": [
            {"userId": "fake",
             "alertId": "Asset_RT_RTTFT_VR8600E_0724366--param_sealvoltage--Voltagetoohigh",
             "assetId": "Asset_RT_RTTFT_VR8600E_0724366"}
        ]}
        logging.info("converted JSON:{}".format(json.dumps(jsonbody, indent=2)))
        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=False)
        logging.info("test SubscriptionInfo with fake, status_code:{}, text:{}".format(ret.status_code,
                                                                                  ret.text))

        assert (ret.status_code == 500)

    def test_SubscribeToAlertByUserIdLineId(self, configurationfile,configurationpath):
        testServer = ThingworxServer.fromConfigurationFile(os.path.join(configurationpath, configurationfile))
        url = testServer.get_thing_service('Alert_Management_Util','SubscribeToAlertByUserIdLineId')

        jsonbody={
            "SubscriptionInfo": [
                {
                    "userId": "p54284",
                    "alertId":"Asset_RT_RTTFT_VR8600E_0724366--param_sealvoltage--Voltagetoohigh--1--p54284",
                    "lineId": "1"}
            ]}
        logging.info("converted JSON:{}".format(json.dumps(jsonbody, indent=2)))
        ret = requests.request('POST', url, headers=testServer.get_headers(),json=jsonbody, verify=False)
        logging.info("test SubscriptionInfo with p54284, status_code:{}, text:{}".format(ret.status_code,
                                                                                  ret.text))

        assert(ret.status_code == 200)

        jsonbody = {
            "SubscriptionInfo": [
                {
                    "userId": "fake",
                    "alertId": "Asset_RT_RTTFT_VR8600E_0724366--param_sealvoltage--Voltagetoohigh--1--p54284",
                    "lineId": "1"}
            ]}
        logging.info("converted JSON:{}".format(json.dumps(jsonbody, indent=2)))
        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=False)
        logging.info("test SubscriptionInfo with fake, status_code:{}, text:{}".format(ret.status_code,
                                                                                  ret.text))

        assert (ret.status_code == 500)

    def test_UnsubscribeFromAlertByUserIdAssetId(self, configurationfile,configurationpath):
        testServer = ThingworxServer.fromConfigurationFile(os.path.join(configurationpath, configurationfile))
        url = testServer.get_thing_service('Alert_Management_Util','UnsubscribeFromAlertByUserIdAssetId')

        jsonbody={
            "SubscriptionInfo": [
                {
                    "userId": "p54284",
                    "alertId": "Asset_RT_RTTFT_VR8600E_0724366--param_sealvoltage--Voltagetoohigh",
                    "assetId": "Asset_RT_RTTFT_VR8600E_0724366"}
            ]}
        logging.info("converted JSON:{}".format(json.dumps(jsonbody, indent=2)))
        ret = requests.request('POST', url, headers=testServer.get_headers(),json=jsonbody, verify=False)
        logging.info("test UnsubscriptionInfo with p54284, status_code:{}, text:{}".format(ret.status_code,
                                                                                  ret.text))

        assert(ret.status_code == 200)

        jsonbody = {
            "SubscriptionInfo": [
                {
                    "userId": "fake",
                    "alertId": "Asset_RT_RTTFT_VR8600E_0724366--param_sealvoltage--Voltagetoohigh",
                    "assetId": "Asset_RT_RTTFT_VR8600E_0724366"}
            ]}
        logging.info("converted JSON:{}".format(json.dumps(jsonbody, indent=2)))
        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=False)
        logging.info("test UnsubscriptionInfo with fake, status_code:{}, text:{}".format(ret.status_code,
                                                                                  ret.text))

        assert (ret.status_code == 500)

    def test_UnsubscribeFromAlertByUserIdLineId(self, configurationfile,configurationpath):
        testServer = ThingworxServer.fromConfigurationFile(os.path.join(configurationpath, configurationfile))
        url = testServer.get_thing_service('Alert_Management_Util','UnsubscribeFromAlertByUserIdLineId')

        jsonbody={
            "SubscriptionInfo": [
                {
                    "userId": "p54284",
                    "alertId": "Asset_RT_RTTFT_VR8600E_0724366--param_sealvoltage--Voltagetoohigh--1--p54284",
                    "lineId": "1"}
            ]}
        logging.info("converted JSON:{}".format(json.dumps(jsonbody, indent=2)))
        ret = requests.request('POST', url, headers=testServer.get_headers(),json=jsonbody, verify=False)
        logging.info("test UnsubscriptionInfo with p54284, status_code:{}, text:{}".format(ret.status_code,
                                                                                  ret.text))

        assert(ret.status_code == 200)

        jsonbody = {
            "SubscriptionInfo": [
                {
                    "userId": "fake",
                    "alertId": "Asset_RT_RTTFT_VR8600E_0724366--param_sealvoltage--Voltagetoohigh--1--p54284",
                    "lineId": "1"}
            ]}
        logging.info("converted JSON:{}".format(json.dumps(jsonbody, indent=2)))
        ret = requests.request('POST', url, headers=testServer.get_headers(), json=jsonbody, verify=False)
        logging.info("test UnsubscriptionInfo with fake, status_code:{}, text:{}".format(ret.status_code,
                                                                                  ret.text))

        assert (ret.status_code == 500)