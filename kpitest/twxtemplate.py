# -*- coding: utf-8 -*-

from .twxproperty import TWX_Property


class TWX_Template():
    def __init__(self,name, **kwargs):
        self.name = name
        self.allProperties = kwargs.get('allProperties',{}) #{name, TWX_Property}
        self.simulateList = kwargs.get('simulateList',[])  #[name] = simulate but not follow
        self.followedList = kwargs.get('followedList',[])  #[name] = simulate and follow
        self.remoteTemplateName=kwargs.get('remoteTemplateName',name)

    def set_remote_template_name(self,templatename):
        self.remoteTemplateName=templatename


    def set_all_properties(self,all_properties):
        self.allProperties=all_properties


    def set_simulate_list(self,simulate_list):
        self.simulateList = simulate_list


    def set_followed_list(self,followed_list):
        self.followedList = followed_list

    def __repr__(self):
        return self.__str__()

    def __str__(self):
        return '{} has {} properties, \n will simulate:{}, followed:{}'.format(
            self.name,
            len(self.allProperties),
            self.simulateList,
            self.followedList
        )