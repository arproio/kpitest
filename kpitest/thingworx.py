import requests
import json
import os

class ThingworxServer():
    '''class to handle a general thingworx server and generate regular URL'''
    def __init__(self, configuration):
        self.configuration = configuration
    
    @classmethod
    def fromConfigurationFile(cls, configurationfile):
        ''' {
            'server':'gateway.desheng.io',
            'port':443,
            'appKey':'84ce8ad3-e081-4d01-9af0-f6fef4156362',
            'protocol':'https'
        }'''
        default_config={
            'server':None,
            'port':None,
            'appKey':None,
            'protocol':'https'
        }
        with open(configurationfile,'r') as data_file:
            configuration = json.load(data_file)
            new_configuration = {}
            for configitem in ['server','port','appKey','protocol']:
                itemvalue=configuration.get(configitem,default_config[configitem])
                if not itemvalue:
                    raise ValueError('{} is not provided in configuration file!'.format(configitem))
                new_configuration[configitem]=itemvalue
            return cls(new_configuration)

        raise ValueError('Failed to initialize server from:{}'.format(configurationfile))

    @classmethod
    def fromConfiguration(cls,server,port,appKey,protocol):
        configuration = {}
        configuration['server']=server
        configuration['port'] = port
        configuration['appKey'] = appKey
        configuration['protocol'] = protocol

        return cls(configuration)

    def get_headers(self):
        return {
            'appKey':self.configuration['appKey'],
            'Content-Type':'application/json',
            'Accept':'application/json',
            'cache-control':'no-cache'
            }
    
    def get_thing_service(self, thingName,serviceName):
        return '{}://{}:{}/Thingworx/Things/{}/services/{}'.format(
                self.configuration['protocol'],
                self.configuration['server'],
                self.configuration['port'],
                thingName,
                serviceName
            )
    

    def get_delete_thing_url(self):
        return '{}://{}:{}/Thingworx/Resources/EntityServices/Services/DeleteThing'.format(
            self.configuration['protocol'],
            self.configuration['server'],
            self.configuration['port']
        )

    def get_things_url(self):
        return '{}://{}:{}/Thingworx/Things'.format(
            self.configuration['protocol'],
            self.configuration['server'],
            self.configuration['port']
        )

    def get_things(self):
        url = self.get_things_url()

        headers = self.get_headers()

        ret = requests.request("GET", url, headers=headers, verify=False)
        return ret

    def get_import_url(self):
        return '{}://{}:{}/Thingworx/Importer'.format(
            self.configuration['protocol'],
            self.configuration['server'],
            self.configuration['port']
        )

    def get_import_headers(self):
        return {
            'appKey':self.configuration['appKey'],
            'Accept':'application/json',
            'x-xsrf-token': "TWX-XSRF-TOKEN-VALUE",
            'cache-control':'no-cache'
            }

    def import_file(self,inputfilename):
        url = self.get_import_url()

        querystring = {"purpose": "import", "usedefaultdataprovider": "false", "WithSubsystems": "false"}
        # make sure don't include "content-type" in header. it will be set by request directly.
        headers = self.get_import_headers()

        filename, fileextension = os.path.split(os.path.basename(inputfilename))
        fileextension = fileextension.split(".")[1].lower()
        if fileextension not in ['xml','twx']:
            raise ValueError("unsupported file type:{}".format(fileextension))


        with open(inputfilename, 'rb') as f:
            multiple_files = {
                'file': (f.name, f, 'application/xml' if fileextension=='xml' else 'application/octet-stream')
            }
            # both methods work
            ret = requests.request("POST", url=url, headers=headers, params=querystring, files=multiple_files)
            # ret = requests.post(url, files=multiple_files,params=querystring,headers=headers)

            return ret

        raise ValueError('{} may not exist or have error!'.format(inputfilename))

if __name__ == '__main__':
    dir_path = os.path.dirname(os.path.realpath(__file__))
    print("dir path:{}".format(dir_path))

    testServer = ThingworxServer.fromConfigurationFile(os.path.join(dir_path,
                                                                    "../config/gateway.json"))

    ret = testServer.get_things()
    if ret.status_code == 200 and ret.text:
        data = json.loads(ret.text)
        print("JSON:{}".format(data['rows'][0]))

    #print(ret.text)