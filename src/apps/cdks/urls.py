from django.urls import path
from . import views

app_name = "cdks"

urlpatterns = [
    path('claim/', views.CDKClaimView.as_view(), name="claim"),
    path('api/claim/', views.CDKClaimAPIView.as_view(), name="api_claim"),
]
