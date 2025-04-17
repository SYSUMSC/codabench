from django.db import models
from django.utils.timezone import now
from profiles.models import User


class CDK(models.Model):
    """
    Cloud Development Kit (CDK) model for GPU access
    """
    code = models.CharField(max_length=100, unique=True)
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='cdks')
    claimed = models.BooleanField(default=False)
    claimed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.code} - {'Claimed' if self.claimed else 'Available'}"
    
    def claim(self, user):
        """
        Claim this CDK for a user
        """
        if self.claimed:
            return False
        
        self.user = user
        self.claimed = True
        self.claimed_at = now()
        self.save()
        return True
