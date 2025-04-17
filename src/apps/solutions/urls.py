from django.urls import path

from . import views
from . import api

app_name = 'solutions'

urlpatterns = [
    # Web views
    path('upload/', views.SolutionUploadView.as_view(), name='upload'),
    path('list/', views.SolutionListView.as_view(), name='list'),

    # API endpoints
    path('api/create/', api.create_solution_pdf, name='api_create'),
    path('api/complete/<uuid:key>/', api.solution_pdf_upload_complete, name='api_complete'),
    path('api/delete/<uuid:key>/', api.delete_solution_pdf, name='api_delete'),
    path('api/download/<uuid:key>/', api.get_solution_pdf_download_url, name='api_download'),
    path('api/upload/<uuid:key>/', api.upload_solution_pdf, name='api_upload'),
]
