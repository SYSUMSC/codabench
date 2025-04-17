from utils.email import codalab_send_mail, codalab_send_markdown_email


def get_organizer_emails(competition):
    return [user.email for user in competition.all_organizers if not user.is_deleted]

# 发送参赛请求邮件
def send_participation_requested_emails(participant):
    if participant.user.is_deleted:
        return

    context = {
        'participant': participant
    }
    # Notify Organizers - Commented out to reduce email sending
    # codalab_send_mail(
    #     context_data=context,
    #     subject=f'{participant.user.username} applied to your competition',
    #     html_file="emails/participation/organizer/participation_requested.html",
    #     text_file="emails/participation/organizer/participation_requested.txt",
    #     to_email=get_organizer_emails(participant.competition)
    # )

    # Notify User - Commented out to reduce email sending
    # codalab_send_mail(
    #     context_data=context,
    #     subject=f'Application sent to {participant.competition.title}',
    #     html_file='emails/participation/participant/participation_requested.html',
    #     text_file='emails/participation/participant/participation_requested.txt',
    #     to_email=participant.user.email
    # )

# 发送参赛通过邮件
def send_participation_accepted_emails(participant):
    if participant.user.is_deleted:
        return

    context = {
        'participant': participant
    }
    # Commented out to reduce email sending
    # codalab_send_mail(
    #     context_data=context,
    #     subject=f'{participant.user.username} was accepted in to your competition',
    #     html_file="emails/participation/organizer/participation_accepted.html",
    #     text_file="emails/participation/organizer/participation_accepted.txt",
    #     to_email=get_organizer_emails(participant.competition)
    # )
    # Notify User - Commented out to reduce email sending
    # codalab_send_mail(
    #     context_data=context,
    #     subject=f'Participation status update for {participant.competition.title}',
    #     html_file='emails/participation/participant/participation_accepted.html',
    #     text_file='emails/participation/participant/participation_accepted.txt',
    #     to_email=participant.user.email
    # )

# 发送参赛拒绝邮件
def send_participation_denied_emails(participant):
    if participant.user.is_deleted:
        return

    context = {
        'participant': participant
    }
    # Notify Organizers - Commented out to reduce email sending
    # codalab_send_mail(
    #     context_data=context,
    #     subject=f'{participant.user.username} was denied from your competition',
    #     html_file="emails/participation/organizer/participation_denied.html",
    #     text_file="emails/participation/organizer/participation_denied.txt",
    #     to_email=get_organizer_emails(participant.competition)
    # )
    # Notify User - Commented out to reduce email sending
    # codalab_send_mail(
    #     context_data=context,
    #     subject=f'Participation status update for {participant.competition.title}',
    #     html_file='emails/participation/participant/participation_denied.html',
    #     text_file='emails/participation/participant/participation_denied.txt',
    #     to_email=participant.user.email
    # )

# 发送直接参赛邮件
def send_direct_participant_email(participant, content):
    if participant.user.is_deleted:
        return

    # Commented out to reduce email sending
    # codalab_send_markdown_email(
    #     subject=f'A message from the admins of {participant.competition.title}',
    #     markdown_content=content,
    #     recipient_list=[participant.user.email],
    # )
