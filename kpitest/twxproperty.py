# -*- coding: utf-8 -*-


class TWX_Property():
    @classmethod
    def getAttributeList(cls):
        title=["propertyName","TemplateName","sourceName","friendlyName",
               "granularity","DataType","Chance","MinValue","MaxValue",
               "Follow","Select","Incremental","Simulate"]
        return title

    def __init__(self,name,**kwargs):
        if not name or name.strip()=='':
            raise ValueError('Property Name can not be empty.')

        self.name = name
        self.TemplateName=kwargs.get("TemplateName","")
        self.granularity=[]
        granularitystr = kwargs.get('granularity','').strip()
        if len(granularitystr)>0:
            self.granularity=granularitystr.split('|')

        dataType=kwargs.get('DataType','int')
        self.intType = False
        self.floatType = False

        if dataType == "int":
            self.intType=True

        if dataType == "float":
            self.floatType = True

        self.chance=float(kwargs.get('Chance',100)) * 0.01
        self.minValue=kwargs.get('MinValue',0)
        self.maxValue=kwargs.get('MaxValue',0)
        if self.minValue == 0 and self.maxValue == 1:
            self.binaryType = True
        else:
            self.binaryType = False

        self.selectType=False
        self.selectValues=[]
        selectstr = (kwargs.get('Select','')).strip()
        if len(selectstr)>0:
            self.selectValues=[int(value) for value in selectstr.split(',')]

        if len(self.selectValues) > 0:
            self.selectType = True

        self.follow = kwargs.get('Follow', None)
        self.incrementalType = kwargs.get('Incremental','no').lower() == 'yes'
        self.simulate = kwargs.get('Simulate','no').lower() == 'yes'

    def __repr__(self):
        return "TWX_Property()"

    def __str__(self):
        str=""
        for key,value in self.__dict__.items():
            str += '{}-->{}\n'.format(key,value)

        return str