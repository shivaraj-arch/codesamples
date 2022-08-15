#Tornado to process data using multiple ioloop instances  to extract links

from tornado import ioloop
import functools,pickle
import time
from tornado import httpclient
import tornado
from multiprocessing import Process,Pool
import re,pdb,os
import urllib2,urllib
import urlparse
from redis import Redis
import sys,glob
r = Redis()
urls_to_fetch = []
#linkregex = re.compile('<a\s*href=[\'|"](.*?)[\'"].*?>')
linkregex = re.compile(r'<a\s*href=[\'"](http:.*?)[\'"].*?>')
conns=0
res=[]
def fetch(url):
    ioloop_inst = ioloop.IOLoop.instance()
    #global ioloop_inst#,http_client
    #http_client =   httpclient.AsyncHTTPClient(max_clients=1000)
    #http_client.fetch(url,callback=handle_request)
    try:
        #print url,time.localtime()[4]
        #httpclient.AsyncHTTPClient(max_clients=10).fetch(url,callback=handle_request)
        ioloop_inst.add_timeout(time.time() + 0.01,functools.partial(handle_request,httpclient.AsyncHTTPClient(max_clients=1000).fetch(url,callback=handle_request),iol=ioloop_inst))
        ioloop_inst.start()
    except  Exception as e:
        print "error:",e
def defunct_handle_request(response,iol=None):
      global conns
      #print conns
      conns += 1
      '''print conns#pdb.set_trace()
      if conns % 10 == 0:
		print conns'''
      #print response
      if response is not None and response.buffer is not None and response.error is None:
        print "********************", response.effective_url
        try:
			r.rpush('links',linkregex.findall(response.buffer.read()))
        except Exception as e:
			pass
      if iol is not None:
        iol.stop()
def handle_request(response,iol=None):
    global res
    if response is not None and response.buffer is not None and response.error is None:
        res.append(linkregex.findall(response.buffer.read()))
    if iol is not None:
        iol.stop()

class extractLinks(object):
    fetch = staticmethod(fetch)
    handle_request = staticmethod(handle_request)
    numlinks =60000
    result =[]
    global res
    
    def async_map(self,fn, iterable, callback ):
     #pdb.set_trace()
     global ioloop_inst

     def loop(self):
        try:
            arg = next(iterator)
        except StopIteration:
            callback(result)
        else:
            fn(arg, save_result)

     def save_result(self,value):
        result.append(value)
        ioloop_inst.add_callback(loop)

     iterator = iter(iterable)
     result = []
     ioloop_inst.add_callback(loop)
    def printresults(self,i):
        print len(res),time.localtime()[2],time.localtime()[3],time.localtime()[4]
        #print "completed",len(res),time.#,result.get(timeout=10)

    def run(self): 
        global ioloop_inst,result
        pool_tornado = Pool(processes=20)
        for  filename in glob.glob('1/*.txt'):
            #pdb.set_trace()
            print  filename
            f = open(filename,'r')
            r.rpush('url:fetch', f.readlines())
            f.close()
            urls = eval(r.blpop('url:fetch')[1])    
            print len(urls)
            result = pool_tornado.map_async(self.fetch,[url.strip('\n') for url in urls],callback=self.printresults)
            #print result.get(timeout=10)
            #async_map(fetch,[url.strip('\n') for url in urls],done)
            #results = [pool_tornado.apply_async(fetch,(url.strip('\n'),),callback=handle_request) for url in urls]
            #results = [pool_tornado.apply_async(fetch,(url.strip('\n'),),callback=lambda arg:ioloop_inst.add_callback(functools.partial(handle_request,arg))) for url in urls]
            #for url in urls:
            #pool_tornado.apply_async(fetch,url.strip('\n'),callback=handle_request) 
            #ioloop_inst.start()
            #results = [result.get() for result in results]
            #print results
        print "at tornado close"	
        #print pool_tornado.map(fetch,range(len(urls)))
        pool_tornado.close()
        pool_tornado.join()



if __name__ == '__main__':
    a = extractLinks()
    pickle.dumps(fetch)
    pickle.dumps(handle_request)
    a.run()
