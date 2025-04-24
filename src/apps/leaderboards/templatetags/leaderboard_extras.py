from django import template

register = template.Library()

@register.filter
def has_graduate_student(members):
    """
    Check if any member in the list has education_level set to 'master' or 'phd'
    """
    if not members:
        return False
    
    for member in members:
        if member.get('education_level') in ['master', 'phd']:
            return True
    
    return False
