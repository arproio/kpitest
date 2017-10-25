import pytest
import os
import logging
import decorator
import sys
import json

from kpitest.thingworx import ThingworxServer

def pytest_addoption(parser):
    parser.addoption("--config", action="store", default="gateway.json", help="configuration file of server setting")

    dir_path = os.path.dirname(os.path.realpath(__file__))  #get current dir
    default_configuration_file_path=os.path.join(dir_path,"../config")
    parser.addoption("--config_path", action = "store", default=default_configuration_file_path,
                     help="configuration file folder")

    default_loadfiles_folder=os.path.join(dir_path,"./loadfiles")
    parser.addoption("--loadfiles_path", action = "store", default=default_loadfiles_folder,
                     help="loadfiles folder")

    parser.addoption("--loadfiles", action="store_true", default=False,
                    help="whether load files or not.")

    parser.addoption("--sslvalidation", action="store_true", default=False,
                     help="whether validate SSL from server side")

def log_input(jsondata):
    try:
        logging.info("JSON Input:{}".format(json.dumps(jsondata, indent=2)))
    except json.decoder.JSONDecodeError:
        logging.info("Non-JSON Input:{}".format(jsondata))

    return

def log_ret(ret):
    try:
        statuscode=ret.status_code
        try:
            jsondata=json.loads(ret.text)
            logging.info("Return Status Code:{}, JSON Results:{}".format(statuscode,json.dumps(jsondata, indent=2)))
            return
        except json.decoder.JSONDecodeError:
            logging.info("Return Status Code:{}, Return Text:{}".format(statuscode, ret.text))
    except:
        logging.info("Return Unknown Ret:{}".format(ret))

def log_testcase(func):
    def func_wrapper(func, *args, **kwargs):
        logging.info("")
        logging.info("       =======================           ")
        logging.info("Start :{}".format(func.__name__))
        return func(*args, **kwargs)

    return decorator.decorator(func_wrapper,func)

@pytest.fixture
def testServer(request):
    configurationpath = request.config.getoption("--config_path")
    configurationfile = request.config.getoption("--config")
    testServer=ThingworxServer.fromConfigurationFile(os.path.join(configurationpath,configurationfile))
    testServer.validateSSL=request.config.getoption("--sslvalidation")

    return testServer

@pytest.fixture
def configurationfile(request):
    return request.config.getoption("--config")

@pytest.fixture
def configurationpath(request):
    return request.config.getoption("--config_path")

@pytest.fixture
def loadfilespath(request):
    return request.config.getoption("--loadfiles_path")

@pytest.fixture
def loadfiles(request):
    return request.config.getoption("--loadfiles")

def pytest_runtest_makereport(item, call):
    if "incremental" in item.keywords:
        if call.excinfo is not None:
            parent = item.parent
            parent._previousfailed = item

def pytest_runtest_setup(item):
    if "incremental" in item.keywords:
        previousfailed = getattr(item.parent, "_previousfailed", None)
        if previousfailed is not None:
            pytest.xfail("previous test failed (%s)" %previousfailed.name)
