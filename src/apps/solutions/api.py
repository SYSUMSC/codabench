import os
from decimal import Decimal

from django.contrib.auth.decorators import login_required
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST
from django.shortcuts import get_object_or_404
from django.core.files.base import ContentFile
from django.views.decorators.csrf import csrf_exempt
from django.http import HttpResponse
from django.urls import reverse
import datetime

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from profiles.models import Organization, Membership
from utils.data import make_url_sassy, pretty_bytes
from utils.storage import PublicStorage
from .models import SolutionPDF


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_solution_pdf(request):
    """Create a new solution PDF entry and return a signed URL for upload"""
    # 题解允许上传时间
    start_date = datetime.datetime(2025, 4, 1, 0, 0, 0)
    end_date = datetime.datetime(2025, 5, 15, 23, 59, 59)

    if not (start_date <= datetime.datetime.now() <= end_date):
        return Response(
            {"error": "Solution PDF submissions are only allowed between April 1, 2025 and May 15, 2025"},
            status=status.HTTP_403_FORBIDDEN
        )

    # Validate organization
    org_id = request.data.get('organization')
    if not org_id:
        return Response(
            {"error": "Organization ID is required"},
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        organization = Organization.objects.get(id=org_id)
    except Organization.DoesNotExist:
        return Response(
            {"error": "Organization not found"},
            status=status.HTTP_404_NOT_FOUND
        )

    # Check if user is a member of the organization
    try:
        membership = organization.membership_set.get(user=request.user)
        if membership.group not in Membership.PARTICIPANT_GROUP:
            return Response(
                {"error": "You do not have permission to submit for this organization"},
                status=status.HTTP_403_FORBIDDEN
            )
    except Membership.DoesNotExist:
        return Response(
            {"error": "You are not a member of this organization"},
            status=status.HTTP_403_FORBIDDEN
        )

    # Check if organization already has a solution PDF
    existing_solution = SolutionPDF.objects.filter(organization=organization).first()
    if existing_solution and existing_solution.upload_completed_successfully:
        return Response(
            {"error": "This organization already has a solution PDF uploaded. Please delete the existing one first."},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Create the solution PDF entry
    name = request.data.get('name', f"{organization.name} Solution")
    solution_pdf = SolutionPDF(
        name=name,
        description=request.data.get('description', ''),
        created_by=request.user,
        organization=organization,
    )

    # Use organization name as the file name
    file_name = f"solution_pdfs/{organization.name}_{name}.pdf"
    solution_pdf.pdf_file.name = file_name
    solution_pdf.save()

    # Return the URL for upload
    context = {
        "key": solution_pdf.key,
        "sassy_url": reverse('solutions:api_upload', args=[solution_pdf.key]),
    }

    return Response(context, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def solution_pdf_upload_complete(request, key):
    """Mark a solution PDF upload as complete"""
    try:
        solution_pdf = SolutionPDF.objects.get(key=key)
    except SolutionPDF.DoesNotExist:
        return Response(
            {"error": "Solution PDF not found"},
            status=status.HTTP_404_NOT_FOUND
        )

    # Check if user is the creator or a member of the organization
    if solution_pdf.created_by != request.user:
        try:
            membership = solution_pdf.organization.membership_set.get(user=request.user)
            if membership.group not in Membership.PARTICIPANT_GROUP:
                return Response(
                    {"error": "You do not have permission to update this solution PDF"},
                    status=status.HTTP_403_FORBIDDEN
                )
        except Membership.DoesNotExist:
            return Response(
                {"error": "You do not have permission to update this solution PDF"},
                status=status.HTTP_403_FORBIDDEN
            )

    # Update the solution PDF
    solution_pdf.upload_completed_successfully = True

    # Update file size
    try:
        # save file size as KiB
        solution_pdf.file_size = solution_pdf.pdf_file.size / 1024
    except (TypeError, AttributeError):
        # file returns a None size, can't divide None / 1024
        solution_pdf.file_size = Decimal(0)

    solution_pdf.save()

    return Response({"status": "success"}, status=status.HTTP_200_OK)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_solution_pdf(request, key):
    """Delete a solution PDF"""
    try:
        solution_pdf = SolutionPDF.objects.get(key=key)
    except SolutionPDF.DoesNotExist:
        return Response(
            {"error": "Solution PDF not found"},
            status=status.HTTP_404_NOT_FOUND
        )

    # Check if user is the creator or a member of the organization
    if solution_pdf.created_by != request.user:
        try:
            membership = solution_pdf.organization.membership_set.get(user=request.user)
            if membership.group not in Membership.ALL_GROUP:
                return Response(
                    {"error": "You do not have permission to delete this solution PDF"},
                    status=status.HTTP_403_FORBIDDEN
                )
        except Membership.DoesNotExist:
            return Response(
                {"error": "You do not have permission to delete this solution PDF"},
                status=status.HTTP_403_FORBIDDEN
            )

    # Delete the solution PDF
    solution_pdf.delete()

    return Response(status=status.HTTP_204_NO_CONTENT)


@csrf_exempt
def upload_solution_pdf(request, key):
    """Handle file upload for solution PDF"""
    if request.method != 'POST':
        return HttpResponse(status=405)

    try:
        solution_pdf = SolutionPDF.objects.get(key=key)
    except SolutionPDF.DoesNotExist:
        return HttpResponse(status=404)

    # Check if user is authenticated
    if not request.user.is_authenticated:
        return HttpResponse(status=401)

    # Check if user is the creator or a member of the organization
    if solution_pdf.created_by != request.user:
        try:
            membership = solution_pdf.organization.membership_set.get(user=request.user)
            if membership.group not in Membership.PARTICIPANT_GROUP:
                return HttpResponse(status=403)
        except Membership.DoesNotExist:
            return HttpResponse(status=403)

    # Get the uploaded file
    if 'file' not in request.FILES:
        return HttpResponse('No file uploaded', status=400)

    uploaded_file = request.FILES['file']

    # Check if file is a PDF
    if not uploaded_file.name.lower().endswith('.pdf'):
        return HttpResponse('File must be a PDF', status=400)

    # Save the file
    solution_pdf.pdf_file.save(solution_pdf.pdf_file.name, uploaded_file, save=True)

    return HttpResponse(status=200)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_solution_pdf_download_url(request, key):
    """Get a signed URL for downloading a solution PDF"""
    try:
        solution_pdf = SolutionPDF.objects.get(key=key)
    except SolutionPDF.DoesNotExist:
        return Response(
            {"error": "Solution PDF not found"},
            status=status.HTTP_404_NOT_FOUND
        )

    # Check if user is a member of the organization
    try:
        membership = solution_pdf.organization.membership_set.get(user=request.user)
    except Membership.DoesNotExist:
        return Response(
            {"error": "You do not have permission to download this solution PDF"},
            status=status.HTTP_403_FORBIDDEN
        )

    # Return the URL for download
    if hasattr(PublicStorage, 'bucket'):
        download_url = make_url_sassy(solution_pdf.pdf_file.name)
    else:
        download_url = PublicStorage.url(solution_pdf.pdf_file.name)

    return Response({"download_url": download_url}, status=status.HTTP_200_OK)
