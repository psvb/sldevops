from django.test import TestCase
from django.test.client import Client
from django.utils import unittest

class SimpleTest(unittest.TestCase):
    def setUp(self):
        self.client = Client()

    def test_details(self):
        taskname='from-test-case'
        response = self.client.get('/')
        self.assertEqual(response.status_code, 200)
        response = self.client.get('/newtask')
        #print "-----------------------------------------------------"
        #print response.content
        #print "-----------------------------------------------------"
        self.assertEqual(response.status_code, 200)
        response = self.client.post('/saveTask', {'id': '0', 'task': taskname})
        self.assertEqual(response.status_code, 200)
        response = self.client.get('/')
        #print response.content
        self.assertEqual(response.status_code, 200)
        self.assertTrue(taskname in response.content)
        #print "-----------------------------------------------------"
