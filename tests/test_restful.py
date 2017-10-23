# -*- coding: utf-8 -*-

import pytest
import requests

from kpitest import helper

def test_baseurl():
    baseurl = helper.get_baseurl()
    assert(isinstance(baseurl,str)==True)