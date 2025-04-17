import uuid
from django.db import models
from django.utils.timezone import now
from django.conf import settings

from profiles.models import Organization
from utils.data import PathWrapper
from utils.storage import PublicStorage


class SolutionPDF(models.Model):
    """Model for storing solution PDF uploads"""
    name = models.CharField(max_length=255)
    description = models.TextField(null=True, blank=True)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='solution_pdfs')
    created_when = models.DateTimeField(default=now)
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='solution_pdfs')
    pdf_file = models.FileField(
        upload_to='solution_pdfs',
        storage=PublicStorage,
        null=True,
        blank=True
    )
    file_size = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)  # in KiB
    key = models.UUIDField(default=uuid.uuid4, blank=True, unique=True)
    upload_completed_successfully = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.name} - {self.organization.name}"
