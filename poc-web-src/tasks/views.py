from django.shortcuts import render
from django.template import RequestContext, loader
from django.db import transaction
from django.http import HttpResponse
from django.http import HttpResponseRedirect
import models as db
import datetime

def getTasks(request):
    template = loader.get_template('task_list.html')
    taskList = db.Task.objects.all()
    context = RequestContext(request, { 'task_list' : taskList })
    return HttpResponse(template.render(context))

def createTask(request):
    template = loader.get_template('new_task.html')
    context = RequestContext(request, { 'id': "0" })
    return HttpResponse(template.render(context))

def saveTask(request):
    title = request.POST['task']
    id  = request.POST['id']
    if id=="0":
        id = str(datetime.datetime.now())
        id = id[11:]
        task = db.Task(taskid=id,tasktitle=title)
        task.save()
    else:
        task=db.Task.objects.get(taskid=id)
        task.tasktitle=title
        task.save()
 
    template = loader.get_template('task_list.html')
    taskList = db.Task.objects.all()
    context = RequestContext(request, { 'task_list' : taskList })
    return HttpResponse(template.render(context))

def updateTask(request):
    id = request.GET['id']
    template = loader.get_template('new_task.html')
    task=db.Task.objects.get(taskid=id)
    context = RequestContext(request, { 'id': task.taskid, 'title':task.tasktitle })
    return HttpResponse(template.render(context))

def deleteTask(request):
    id  = request.GET['id']
    task=db.Task.objects.get(taskid=id)
    task.delete()
    return getTasks(request)