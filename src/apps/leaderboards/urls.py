from django.urls import path
from .views import leaderboard_list

app_name = 'leaderboards'

urlpatterns = [
    path('', leaderboard_list, name='leaderboard_list'),
]
