#!/usr/bin/env python

"""This is a script for comparing two configuration files of Jenkins jobs and print them""" 

__author__ = "Shivaraj"
__license__ = "GPL"
__version__ = "1.0"
__maintainer__ = "Shivaraj"
__email__ = "shivrajsys@gmail.com"


import sys,getopt
import xml.etree.ElementTree

JENKINS_PATH='<path where configs are located>/' #job name provided as arguments will get appended to this path

def get_nested(i,t):
    l=[]
    xml_var_dict={ 'properties':['name','defaultValue'],
                   'buildWrappers':['credentialsId','variable','usernameVariable'],
                   'exclude':['LOG_LEVEL']
                 }
    for p in i.iter():
        if p.tag in xml_var_dict[t]:
            d={}
            if p.text==None:
                p.text='None'
            if p.text not in xml_var_dict['exclude']:
                d[p.tag]=p.text
                l.append(d)
    return l
        
def get_properties(branch):
    l=[]
    for i in branch.iter():
        if i.tag == "hudson.model.ParametersDefinitionProperty":
            #print i.text
            for j in i.iter():
                if j.tag == "parameterDefinitions":
                    l.append(get_nested(i,'properties'))
                    return l

def get_buildWrappers(branch):
    l=[]
    l.append(get_nested(branch,'buildWrappers'))
    return l

def xml_glob_properties(e):
    for branch in e:
        if branch.tag == "properties":
            return get_properties(branch)[0]
             
def xml_glob_buildWrappers(e):
    for branch in e:
        if branch.tag == "buildWrappers":
            return get_buildWrappers(branch)[0]

def create_glob(e):
    d1={}
    xml_list=xml_glob_properties(e)
    for line in range(0,len(xml_list),2):
        try:
            d1[xml_list[line]['name']]=xml_list[line+1]['defaultValue']
        except:
            pass
    d2={}
    xml_list=xml_glob_buildWrappers(e)
    for line in range(len(xml_list)):
        try:
            if 'variable' in xml_list[line+1].keys():
                d2[xml_list[line+1]['variable']]=xml_list[line]['credentialsId']
            else:
                d2[xml_list[line+1]['usernameVariable']]=xml_list[line]['credentialsId']
        except:
            pass
    return d1,d2


def display(c1,c2,t,w):
        if t!='FIND':
            print '\n\n'+w+'\t'+t+':\n\n'
        if w=='ALL':
            keyset=set(c1.keys()) | set(c2.keys())    
        if w=='DIFF':
            keyset=[]
            tmp=set(c1.keys()) | set(c2.keys())    
            for i in tmp:
                try:
                    if c1[i]!=c2[i]:
                        keyset.append(i)
                except KeyError, e:
                    keyset.append(i)
                    pass
        if t=='FIND':
            keyset=set([w])
        fmt = '{:<3}{:<40}{:<60}{}'
        print(fmt.format('', 'Parameter', 'Config1 Value', 'Config2 Value'))
        for i, v1 in enumerate(keyset,1):
            try:
                print(fmt.format(i, v1, c1[v1], c2[v1]))
            except KeyError, e:
                if v1 in c1.keys():
                    print(fmt.format(i, v1, c1[v1], 'NA'))
                if v1 in c2.keys():
                    print(fmt.format(i, v1, 'NA', c2[v1]))

                pass

def usage():
        print "\t\tPlease enter 4 arguments to run script : \n\t./compare_config.py <JOB1> <JOB2> <PROPERTIES/BUILDWRAPPERS> <ALL/DIFF>\n                OR\n\t./compare_config.py <JOB1> <JOB2> <KEYNAME> <FIND>"

def main(argv):                         
    try:                                
        if len(argv)!=4:
            usage()
            sys.exit(2)
    except :           
        sys.exit(2)                    

    config1=JENKINS_PATH+argv[0]+'/config.xml'
    config2=JENKINS_PATH+argv[1]+'/config.xml'
    e1 = xml.etree.ElementTree.parse(config1).getroot()
    e2 = xml.etree.ElementTree.parse(config2).getroot()
    
    A1,B1=create_glob(e1)
    A2,B2=create_glob(e2)
    if argv[2]=='PROPERTIES' or argv[2]=='FIND':
        display(A1,A2,argv[2],argv[3])
    if argv[2]=='BUILDWRAPPERS' or argv[2]=='FIND':
        display(B1,B2,argv[2],argv[3])
    

if __name__ == "__main__":
        main(sys.argv[1:])
