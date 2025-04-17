from django.contrib import admin
from .models import CDK


@admin.register(CDK)
class CDKAdmin(admin.ModelAdmin):
    list_display = ('code', 'user', 'claimed', 'claimed_at', 'created_at')
    list_filter = ('claimed',)
    search_fields = ('code', 'user__username')
    readonly_fields = ('claimed_at', 'created_at')
