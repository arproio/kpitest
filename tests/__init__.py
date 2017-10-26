# -*- coding: utf-8 -*-
import logging
import os
import datetime

dir_path = os.path.dirname(os.path.realpath(__file__))
logpath=os.path.join(dir_path,"logs")
if not os.path.exists(logpath):
    os.makedirs(logpath,0o777,True)
filename="test{}.log".format(datetime.datetime.now().strftime('%Y%m%d%H%M%s'))

logging.basicConfig(filename=os.path.join(logpath,filename), level=logging.INFO)

# pytest -s -q --alluredir report -vv --config=gateway.json
# allure generate report/ -o report/html