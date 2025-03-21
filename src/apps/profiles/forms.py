from django import forms
from django.contrib.auth.forms import UserCreationForm
from .models import User


class SignUpForm(UserCreationForm):

    email = forms.EmailField(
        max_length=254, help_text="Required. Inform a valid email address."
    )

    phone_number = forms.CharField(
        max_length=20, required=True, help_text="请输入您的电话号码"
    )

    student_id = forms.CharField(
        max_length=20, required=True, help_text="请输入您的学号"
    )

    graduation_year = forms.IntegerField(
        required=True, help_text="请输入您的毕业年份（如2023）"
    )

    education_level = forms.ChoiceField(
        choices=[
            ('bachelor', '本科'),
            ('master', '硕士'),
            ('phd', '博士'),
            ('other', '其他')
        ],
        required=True,
        help_text="请选择您的学历"
    )

    def clean_username(self):
        data = self.cleaned_data["username"]
        if not data.islower():
            raise forms.ValidationError("Usernames should be in lowercase")
        if not data.isalnum():
            raise forms.ValidationError(
                "Usernames should not contain special characters."
            )
        if (len(data) > 15) or (len(data) < 5):
            raise forms.ValidationError(
                "Username must have at least 5 characters and at most 15 characters"
            )
        return data

    class Meta:

        model = User
        fields = ("username", "email", "phone_number", "student_id", "graduation_year", "education_level", "password1", "password2")


class LoginForm(forms.Form):

    username = forms.CharField(max_length=150)
    password = forms.CharField(max_length=150, widget=forms.PasswordInput)


class ActivationForm(forms.Form):
    email = forms.EmailField(max_length=254, required=True)
