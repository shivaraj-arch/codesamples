#!/usr/bin/env python3

"""This is a script for listening through multiple non blocking threaded sockets and inserting data through pooled pymysql-sqlalchemy connections without spinlock conflict""" 

__author__ = "Shivaraj"
__license__ = "GPL"
__version__ = "1.0"
__maintainer__ = "Shivaraj"
__email__ = "shivrajsys@gmail.com"



from _thread import *
import threading
import socket
import time
import datetime
import pymysql
import sqlalchemy.pool as pool
import logging

tlock = threading.Lock()
logging.basicConfig(filename='log', level=logging.DEBUG)

def getconn():
	return pymysql.connect('localhost','user','password','database')

mypool = pool.QueuePool(getconn, max_overflow=5, pool_size=20)	


def insert_into_mysql(data):
	#print(type(data))
	try:
		IST_delta = datetime.timedelta(hours=5, minutes=30)
		devdate = datetime.datetime.combine(d_,t_)
		crdt = (devdate+IST_delta).isoformat(' ')
		mysql_format_query="""INSERT INTO `date` (`IST`) VALUES ( """ + crdt  + """ );"""
		conn = mypool.connect()
		cursor = conn.cursor()
		cursor.execute(mysql_format_query)
		conn.commit()
		conn.close()
	except Exception as e:
		logging.error("Exception at insert_into_mysql occurred", exc_info=True)
		conn.close()
		pass

def threaded(c):
	while True:
		try:
			data = c.recv(2048)
			time.sleep(0.05)
			if not data:
				if tlock.locked():
					tlock.release()
				break
			else:
				insert_into_mysql(data) #sample operation
		except Exception as e:
			logging.error("Exception at threaded occurred", exc_info=True)
			pass

	c.close()

if __name__=="__main__":
	s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
	s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1) #multiple non blocking reusable socket
	s.bind(('localhost',port))
	s.listen(20)
	try:
		while True:
			c,client=s.accept()
			tlock.acquire(False) # lock = non-blocking
			start_new_thread(threaded , (c,))
	except Exception as e:
		logging.error("Exception at main occurred", exc_info=True)
		pass
	s.close()
