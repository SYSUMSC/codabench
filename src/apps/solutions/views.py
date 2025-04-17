import datetime
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.mixins import LoginRequiredMixin
from django.views.generic import TemplateView, ListView
from django.contrib import messages
from django.http import HttpResponseRedirect, Http404
from django.urls import reverse

from profiles.models import Organization, Membership
from .models import SolutionPDF


class SolutionUploadView(LoginRequiredMixin, TemplateView):
    template_name = 'solutions/upload.html'

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)

        # Get user's organizations
        user_orgs = self.request.user.organizations.all()
        context['organizations'] = user_orgs

        # 题解允许上传时间
        start_date = datetime.datetime(2025, 4, 1, 0, 0, 0)
        end_date = datetime.datetime(2025, 5, 15, 23, 59, 59)

        context['submission_start_date'] = start_date
        context['submission_end_date'] = end_date
        context['can_submit'] = start_date <= datetime.datetime.now() <= end_date

        return context


class SolutionListView(LoginRequiredMixin, ListView):
    model = SolutionPDF
    template_name = 'solutions/list.html'
    context_object_name = 'solutions'

    def get_queryset(self):
        # Get solutions from organizations the user is a member of
        user_orgs = self.request.user.organizations.all()
        return SolutionPDF.objects.filter(organization__in=user_orgs).order_by('-created_when')
