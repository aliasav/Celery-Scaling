from kombu import Exchange, Queue
import celery
import djcelery

# required by celery
BROKER_URL = 'amqp://codadmin:cod01032014@10.130.148.201:5672'
CELERY_ACCEPT_CONTENT = ['pickle', 'json', 'msgpack', 'yaml']

# defining exchanges
periodic_tasks = Exchange('periodic_tasks', type='direct', routing_key='periodic_tasks')
sms_reminders = Exchange('sms_reminders', type='direct')
whatsapp_reminders = Exchange('whatsapp_reminders', type='direct')
email_reminders = Exchange('email_reminders', type='direct')
phonecall_reminders = Exchange('phonecall_reminders', type='direct')
generic = Exchange('generic', type='direct')
billing = Exchange('billing', type='direct')

CELERY_QUEUES = (
    Queue('periodic_tasks', periodic_tasks, routing_key='periodic_tasks'),
    Queue('sms_reminders', Exchange('sms_reminders'), routing_key='sms_reminders'),
    Queue('whatsapp_reminders', Exchange('whatsapp_reminders'), routing_key='whatsapp_reminders'),
    Queue('email_reminders', Exchange('email_reminders'), routing_key='email_reminders'),
    Queue('phonecall_reminders', Exchange('phonecall_reminders'), routing_key='phonecall_reminders'),
    Queue('billing', Exchange('billing'), routing_key='billing'),
    Queue('generic', Exchange('generic'), routing_key='generic'),
    )

CELERY_ROUTES = {
    # periodic tasks
    'reminders.tasks.clean_voice_messages': {'queue': 'periodic_tasks', 'routing_key': 'periodic_tasks'},
    'reminders.tasks.send_reminders': {'queue': 'periodic_tasks', 'exchange':'periodic_tasks', 'routing_key': 'periodic_tasks' },
    # sms reminders tasks
    'reminders.tasks.send_sms_to_recepient': {'queue': 'sms_reminders', 'routing_key': 'sms_reminders'},
    # whatsapp reminders tasks
    'reminders.tasks.send_whatsapp_message_to_recepient': {'queue': 'whatsapp_reminders', 'routing_key': 'whatsapp_reminders'},
    # email reminders tasks
    'reminders.tasks.send_mail': {'queue': 'email_reminders', 'routing_key': 'email_reminders'},
    # phonecall reminders tasks
    'reminders.tasks.make_phone_call_to_recepient': {'queue': 'phonecall_reminders', 'routing_key': 'phonecall_reminders'},
    # billing tasks
    'billing.tasks.add_credits' : {'queue':'billing', 'routing_key':'billing'},
    'billing.tasks.deactivate_expired_customer_purchases_and_realted_recipient_reminders' : {'queue':'billing', 'routing_key':'billing'},
    # generic tasks
    'campaign.tasks.deactivate_expired_campaigns': {'queue':'generic', 'routing_key':'generic'},
    'customers.tasks.send_miss_call_verification_message': {'queue':'generic', 'routing_key':'generic'},
    'customers.tasks.send_sms_set_reminder_for_me': {'queue':'generic', 'routing_key':'generic'},
    'customers.tasks.sendmail_task': {'queue':'generic', 'routing_key':'generic'},
    }

CELERY_CREATE_MISSING_QUEUES = True

CELERY_IGNORE_RESULT = True

CELERY_DISABLE_RATE_LIMITS = True

CELERY_ACKS_LATE = True

CELERY_TASK_RESULT_EXPIRES = 1

#CELERYD_MAX_TASKS_PER_CHILD = 300

CELERYD_PREFETCH_MULTIPLIER = 5

