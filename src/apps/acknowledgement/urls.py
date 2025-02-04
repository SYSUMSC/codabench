from django.urls import path
from . import views

app_name = "acknowledgement"


urlpatterns = [
    path('', views.AcknowledgementView.as_view(), name='index'),
]
