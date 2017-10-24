# -*- coding: utf-8 -*-
import requests
import json
from datetime import datetime

def get_application_key():
    return '84ce8ad3-e081-4d01-9af0-f6fef4156362'

def get_server_name():
    return 'gateway.desheng.io'

def get_server_port():
    return 443

def get_application_name():
    return 'Thingworx'

def get_protocol():
    return 'https'

def get_baseurl():
    return '{}://{}:{}/{}'.format(
        get_protocol(),
        get_server_name(),
        get_server_port(),
        get_application_name()
    )

def delete_thing():
    url = "https://gateway.desheng.io/Thingworx/Resources/EntityServices/Services/DeleteThing"
    #print('url:{}'.format(url))
    headers={
        'appKey':'84ce8ad3-e081-4d01-9af0-f6fef4156362',
        'Content-Type':'application/json',
        'Accept':'application/json'
    }
    body = {
        'name':'myPythonThing'
    }

    ret = requests.request('POST',url, json=body,headers=headers)
    print('Delete-Status code:{}'.format(ret.status_code))

    if ret.text:
        print('body text:{}'.format(ret.text))
    else:
        print('Headers:{}'.format(ret.headers))

def delete_thing_direct():
    url = "https://gateway.desheng.io/Thingworx/Things/myPythonThing"
    #print('url:{}'.format(url))
    headers={
        'appKey':'84ce8ad3-e081-4d01-9af0-f6fef4156362',
        'Content-Type':'application/json',
        'Accept':'application/json'
    }
    
    ret = requests.request('DELETE',url, headers=headers)
    print('Delete-Status code:{}'.format(ret.status_code))

    if ret.text:
        print('body text:{}'.format(ret.text))
    else:
        print('Headers:{}'.format(ret.headers))


def get_things():
    url = '{}/{}'.format(get_baseurl(),'Things')
    print('url:{}'.format(url))
    headers={
        'appKey':'84ce8ad3-e081-4d01-9af0-f6fef4156362',
        'Content-Type':'application/json',
        'Accept':'application/json'
    }

    ret = requests.request("GET",url,headers = headers)
    print('Status Code:{}'.format(ret.status_code))
    data = json.loads(ret.text)

    print('body size:{}'.format(len(data['rows'])))
    print('data shape:{}'.format(data['dataShape']))

def create_thing():
    url = "https://gateway.desheng.io/Thingworx/Resources/EntityServices/Services/CreateThing"
    #print('url:{}'.format(url))
    headers={
        'appKey':'84ce8ad3-e081-4d01-9af0-f6fef4156362',
        'Content-Type':'application/json',
        'Accept':'application/json'
    }
    body = {
        'name':'myPythonThing',
        'description':'This is a test from my python code',
        'thingTemplateName':'GenericThing'
    }
    body_addshape = {
        'name':'myPythonThing',
        'thingShapeName':'Sealedair.AdditionalThingShape'
    }
    #payload = '{\n\"name\":\"pythonthing\",\n\"description\":\"this is a test from postman\",\n\"thingTemplateName\":\"GenericThing\"\n}'

    # create thing with basic info
    ret = requests.request('POST',url, json=body,headers=headers)
    print('Create-Status code:{}'.format(ret.status_code))

    #assign ThingShape
    if ret.status_code==200:
        url = "https://gateway.desheng.io/Thingworx/Resources/EntityServices/Services/AddShapeToThing"
        ret = requests.request("POST", url, json=body_addshape,headers=headers)
        print('AddShapeToThing-Status code:{}'.format(ret.status_code))


    #Enable Thing
    if ret.status_code==200:
        url = "https://gateway.desheng.io/Thingworx/Things/myPythonThing/Services/EnableThing"
        ret = requests.request("POST", url, headers=headers)
        print('EnableThing-Status code:{}'.format(ret.status_code))

    #Restart Thing
    if ret.status_code==200:
        url = "https://gateway.desheng.io/Thingworx/Things/myPythonThing/Services/RestartThing"
        ret = requests.request("POST", url, headers=headers)
        print('RestartThing-Status code:{}'.format(ret.status_code))

    
    #assign Value Stream
    if ret.status_code==200:
        url = "https://gateway.desheng.io/Thingworx/Things/myPythonThing/Services/SetValueStream"
        body_valuestream = {
            'name':'SteamSensorValueStream'
        }

        ret = requests.request("POST", url, json=body_valuestream, headers=headers)
        print('AddValueStream-Status code:{}'.format(ret.status_code))

    #assign project
    if ret.status_code==200:
        url = "https://gateway.desheng.io/Thingworx/Things/myPythonThing/Services/SetProjectName"
        body_valuestream = {
            'projectName':'PTC.SealedAirProject'
        }

        ret = requests.request("POST", url, json=body_valuestream, headers=headers)
        print('AddProject-Status code:{}'.format(ret.status_code))

        
    if ret.status_code==200 and ret.text:
        data = json.loads(ret.text)
        print("exported JSON:"+data)
    else:
        print('Headers:{}'.format(ret.headers))
        print('body text:{}'.format(ret.text))

def get_utcdate(datestr='20171021143901'):
    url = "https://gateway.desheng.io/Thingworx/Things/PostgreSQLConnection/Services/getUTCDate"

    payload = "{\n\t\"datestr\":\"20171021142701\"\n}"
    body = {
        'datestr': datestr
    }
    headers = {
        'appkey': "84ce8ad3-e081-4d01-9af0-f6fef4156362",
        'content-type': "application/json",
        'accept': "application/json"
        }

    #response = requests.request("POST", url, data=payload, headers=headers)
    ret = requests.request("POST", url, json=body, headers=headers)

    print("Status Code:{}".format(ret.status_code))
    if ret.text:
        data = json.loads(ret.text)
        print("row value:{}".format(data['rows'][0]))
        if data['dataShape']['fieldDefinitions']['result']['baseType']=='DATETIME':
            newdate=datetime.fromtimestamp(data['rows'][0]['result']/1e3).strftime('%Y-%m-%d %H:%M:%S.%f')
            print("new date:{}".format(newdate))
    else:
        print("Headers:{}".format(ret.headers))

def import_file_xml():
    url = "https://gateway.desheng.io/Thingworx/Importer"

    querystring = {"purpose":"import","usedefaultdataprovider":"false","WithSubsystems":"false"}
    # make sure don't include "content-type" in header. it will be set by request directly.
    headers = {
        'appkey': "84ce8ad3-e081-4d01-9af0-f6fef4156362",
        'accept': "application/json",
        'x-xsrf-token': "TWX-XSRF-TOKEN-VALUE",
        'cache-control': "no-cache"
        }

    with open('/Users/desheng/Downloads/Things_myPythonThing.xml', 'rb') as f:
        multiple_files={
            'file':('Things_myPythonThing.xml',f,'application/xml')
        }
        #both methods work
        ret = requests.request("POST",url=url, headers=headers, params=querystring, files=multiple_files)
        #ret = requests.post(url, files=multiple_files,params=querystring,headers=headers)

        print("Import Status Code:{}".format(ret.status_code))
        print(ret.text)

def import_file_twx():
    url = "https://gateway.desheng.io/Thingworx/Importer"

    querystring = {"purpose":"import","usedefaultdataprovider":"false","WithSubsystems":"false"}

    headers = {
        'appkey': "84ce8ad3-e081-4d01-9af0-f6fef4156362",
        'accept': "application/json",
        'x-xsrf-token': "TWX-XSRF-TOKEN-VALUE",
        'cache-control': "no-cache"
        }

    with open('/Users/desheng/Downloads/Things_myPythonThing.twx', 'rb') as f:
        multiple_files={
            'file':('Things_myPythonThing.twx',f,'application/octet-stream')
        }
        ret = requests.request("POST",url=url, headers=headers, params=querystring, files=multiple_files)
        #ret = requests.post(url, files=multiple_files,params=querystring,headers=headers)

        print("Import Status Code:{}".format(ret.status_code))
        print(ret.text)


if __name__=='__main__':
    #get_things()
    #create_thing()
    #delete_thing()
    #delete_thing_direct()
    #get_utcdate('20170902143901')
    #import_file_xml()
    import_file_twx()