"""pocweb URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/1.8/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  url(r'^$', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  url(r'^$', Home.as_view(), name='home')
Including another URLconf
    1. Add an import:  from blog import urls as blog_urls
    2. Add a URL to urlpatterns:  url(r'^blog/', include(blog_urls))
"""

#from django.conf.urls.defaults import patterns, url, include
from django.conf.urls import *
import tasks.views as views

urlpatterns = patterns('',
    url(r'^$', views.getTasks),
    url(r'^tasks$', views.getTasks),
    url(r'^newtask$', views.createTask),
    url(r'^saveTask$', views.saveTask),
    url(r'^updateTask$', views.updateTask),
    url(r'^deleteTask$', views.deleteTask),

)
