import pytest
import os


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
