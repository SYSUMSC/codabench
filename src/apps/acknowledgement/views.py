from django.views.generic import TemplateView


class AcknowledgementView(TemplateView):
    template_name = 'acknowledgement/index.html'
