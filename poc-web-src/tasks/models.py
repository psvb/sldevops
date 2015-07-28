from django.db import models

class Task(models.Model):
    taskid =  models.TextField(db_column='taskid', blank=False)
    tasktitle = models.TextField(db_column='tasktitle', blank=True) 


