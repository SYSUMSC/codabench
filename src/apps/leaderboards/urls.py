from django.urls import path
from .views import overall_leaderboard

app_name = 'leaderboards'

urlpatterns = [
    path('', overall_leaderboard, name='overall_leaderboard'),
]
