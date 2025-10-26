from django.urls import path
from .views import VehicleLookupView

urlpatterns = [
    path("lookup/", VehicleLookupView.as_view(), name="vehicle-lookup"),
]
