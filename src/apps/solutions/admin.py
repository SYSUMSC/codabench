from django.contrib import admin
from .models import SolutionPDF

@admin.register(SolutionPDF)
class SolutionPDFAdmin(admin.ModelAdmin):
    list_display = ('name', 'organization', 'created_by', 'created_when', 'upload_completed_successfully')
    list_filter = ('upload_completed_successfully', 'created_when')
    search_fields = ('name', 'organization__name', 'created_by__username')
    readonly_fields = ('key', 'file_size')
