from django.shortcuts import render, redirect
from django.views.generic import TemplateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib import messages
from django.http import JsonResponse
from django.views.decorators.http import require_POST
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_protect

from profiles.models import Membership
from .models import CDK


class CDKClaimView(LoginRequiredMixin, TemplateView):
    template_name = 'cdks/claim.html'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        user = self.request.user
        
        # Check if user is in an organization
        is_in_org = Membership.objects.filter(
            user=user, 
            group__in=Membership.ALL_GROUP
        ).exists()
        
        # Check if user already has a CDK
        user_cdk = CDK.objects.filter(user=user).first()
        
        context.update({
            'is_in_org': is_in_org,
            'user_cdk': user_cdk,
        })
        
        return context


@method_decorator(csrf_protect, name='dispatch')
class CDKClaimAPIView(LoginRequiredMixin, TemplateView):
    
    def post(self, request, *args, **kwargs):
        user = request.user
        
        # Check if user is in an organization
        is_in_org = Membership.objects.filter(
            user=user, 
            group__in=Membership.ALL_GROUP
        ).exists()
        
        if not is_in_org:
            return JsonResponse({
                'success': False,
                'message': '您需要加入一个组织才能领取 CDK'
            }, status=403)
        
        # Check if user already has a CDK
        if CDK.objects.filter(user=user).exists():
            return JsonResponse({
                'success': False,
                'message': '您已经领取过 CDK'
            }, status=400)
        
        # Get an available CDK
        available_cdk = CDK.objects.filter(claimed=False).first()
        
        if not available_cdk:
            return JsonResponse({
                'success': False,
                'message': 'CDK 已全部领取完毕'
            }, status=404)
        
        # Claim the CDK
        available_cdk.claim(user)
        
        return JsonResponse({
            'success': True,
            'message': 'CDK 领取成功',
            'cdk': available_cdk.code
        })
