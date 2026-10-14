"""A pending client (link sign-up or 'Send to Approvals') lands in Approvals automatically."""
from django.db.models.signals import post_save
from django.dispatch import receiver

from .models import ApprovalRequest, ClientProfile


@receiver(post_save, sender=ClientProfile)
def pending_client_to_approvals(sender, instance, created, raw=False, **kwargs):
    if raw or not created or instance.status != ClientProfile.Status.PENDING:
        return
    link = instance.invite_link
    ApprovalRequest.objects.get_or_create(
        client=instance,
        kind=ApprovalRequest.Kind.SIGNUP,
        status=ApprovalRequest.Status.WAITING,
        defaults={
            "invite_link": link,
            "invited_by": link.trainer if link else instance.trainer,
            "plan": instance.plan or (link.plan if link else ""),
            "device": instance.signup_device,
        },
    )
