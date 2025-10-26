from django.db import models

class Project(models.Model):
    name = models.CharField(max_length=120)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)  # set on create
    updated_at = models.DateTimeField(auto_now=True)      # set on save

    def __str__(self):
        return self.name