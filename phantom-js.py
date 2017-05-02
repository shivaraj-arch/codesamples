#!/usr/bin/env python

"""This is a script for retrieving a dropdown by crawling a webpage and print them using selenium"""

__license__ = "MIT"


import selenium
import time
from time import sleep
import sys
from selenium import webdriver
import pdb, re , time
from selenium.webdriver.support.ui import Select

cap = {u'acceptSslCerts': True,
        u'applicationCacheEnabled': True,
        u'browserConnectionEnabled': True,
        u'browserName': u'phantomjs',
        u'cssSelectorsEnabled': True,
        u'databaseEnabled': False,
        u'driverName': u'ghostdriver',
        u'driverVersion': u'1.1.0',
        u'handlesAlerts': True,
        u'javascriptEnabled': True,
        u'locationContextEnabled': False,
        u'nativeEvents': True,
        u'platform': u'linux-unknown-64bit',
        u'proxy': {u'proxyType': u'direct'},
        u'rotatable': False,
        u'takesScreenshot': True,
        u'version': u'1.9.8',
        u'webStorageEnabled': False}


driver = webdriver.PhantomJS('/usr/local/bin/phantomjs', desired_capabilities=cap)
driver.get('http://cept.gov.in/indiapostinformation/PLBPSD/placesearch.aspx')
statelist = ['KARNATAKA']

for i in statelist:
	selectState = Select(driver.find_element_by_id('ddlState'))
	if i!="Select State":
	    try:
		selectState.select_by_visible_text(i)
		districtlist = driver.execute_script(open("./plvd.js").read())
		for i in districtlist:
			print i
							
	    except Exception as e:
		print e
		print i
		driver.back()
		sleep(6)
		continue

driver.quit()
