from django.shortcuts import get_object_or_404
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticatedOrReadOnly, IsAuthenticated

from .models import Project
from .serializers import ProjectSerializer


class ProjectListCreate(APIView):
    """
    GET /api/projects/  -> list (public)
    POST /api/projects/ -> create (authenticated only)
    """
    permission_classes = [IsAuthenticatedOrReadOnly]

    def get(self, request):
        queryset = Project.objects.all().order_by("-created_at")
        serializer = ProjectSerializer(queryset, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        serializer = ProjectSerializer(data=request.data)
        if serializer.is_valid():
            instance = serializer.save()
            return Response(ProjectSerializer(instance).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ProjectDetail(APIView):
    """
    GET /api/projects/<id>/    -> retrieve (public)
    PUT /api/projects/<id>/    -> full update (authenticated only)
    PATCH /api/projects/<id>/  -> partial update (authenticated only)
    DELETE /api/projects/<id>/ -> delete (authenticated only)
    """
    permission_classes = [IsAuthenticatedOrReadOnly]

    def get_object(self, pk):
        return get_object_or_404(Project, pk=pk)

    def get(self, request, pk: int):
        project = self.get_object(pk)
        serializer = ProjectSerializer(project)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def put(self, request, pk: int):
        project = self.get_object(pk)
        serializer = ProjectSerializer(project, data=request.data)  # full update
        if serializer.is_valid():
            instance = serializer.save()
            return Response(ProjectSerializer(instance).data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def patch(self, request, pk: int):
        project = self.get_object(pk)
        serializer = ProjectSerializer(project, data=request.data, partial=True)  # partial
        if serializer.is_valid():
            instance = serializer.save()
            return Response(ProjectSerializer(instance).data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk: int):
        project = self.get_object(pk)
        project.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)