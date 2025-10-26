from django.urls import path
from .views import ProjectListCreate, ProjectDetail

urlpatterns = [
    path("projects/", ProjectListCreate.as_view(), name="project-list-create"),
    path("projects/<int:pk>/", ProjectDetail.as_view(), name="project-detail"),
]