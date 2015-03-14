from __future__ import absolute_import
from kombu import Exchange, Queue
from celery import Celery
from django.conf import settings
import os

#CELERY_INCLUDE = ('reminders.tasks' ,'customers.tasks','campaign.tasks','billing.tasks', 'recipient.tasks')
cod = Celery('hod_app',
             broker='amqp://codadmin:cod01032014@10.130.148.201:5672//',
             #backend='amqp://codadmin:cod01032014@128.199.116.114:5672//',
             #include=['reminders.tasks' ,'customers.tasks','campaign.tasks','billing.tasks', 'recipient.tasks'],
             )

# Optional configuration, see the application user guide.
cod.conf.update(
    CELERY_TASK_RESULT_EXPIRES=100, # May cause maemory leak
)

# set the default Django settings module for the 'celery' program.
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hod_app.celeryconfig')

cod.config_from_object('hod_app.celeryconfig', silent=False)

# Using a string here means the worker will not have to
# pickle the object when using Windows.
#cod.config_from_object('django.conf:settings')
cod.autodiscover_tasks(lambda: settings.INSTALLED_APPS)


@cod.task(bind=True)
def debug_task(self):
    print('Request: {0!r}'.format(self.request))

if __name__ == '__main__':
    cod.start()
