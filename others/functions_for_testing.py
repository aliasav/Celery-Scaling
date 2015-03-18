# Functions used in testing
# Use exact same functions for testing since analyse scripts are based on them.

# reminders/tasks.py
@cod.task()
def send_sms_to_recepient(reminder, message_part_1, i):
	"""
	Send sms to a recepient
	"""
	sender_id = settings.SENDER_ID_REMINDERS
	receiver_number = str(reminder.recipient.Phone_number)

	m1 = message_part_1
	m2 = reminder.medicine_message
	message = m1 + ":\n" + reminder.message + "\nPlease take:" + m2
	(status, resp) = send_sms(receiver_number, message, sender_id)
	
	if status:
		try:
			response_code = resp['resp']
			if response_code == 'True':
				logger.debug('Message Count: %s' %i)
			else:
				try:
					error = settings.RESPONSE['%s' % response_code]
					logger.debug("Error: %s, SMS not sent to %s" % (error, receiver_number))
				except Exception as e:
					logger.debug("SMS not sent to %s, The error response recieved from api is unknown, Error Code: %s" % (receiver_number, response_code))

		except Exception as e:
			logger.debug("Error: Unknown response from API, SMS not sent to %s" % (receiver_number))
	else:
		logger.debug("Error:%s, SMS not sent to %s" % (resp, receiver_number))

#reminders/utils.py
# Test function
def send_sms(number, message, sender_id):
    """
    call sleuth's api
    """
    payload = {"mode":"sms","token":"8tu30t284t0mc0m0bwl2"}
    r = requests.post('http://128.199.87.42:8000/receiver/api/post/request/', data=payload)
    time.sleep(1.1)
    try:
        if r.ok == True:
            #logger.debug("SMS api invoked successfully")
            return (True, json.loads(r.text))
        else:
            #logger.debug("SMS api invocation failed, HTTP response is %s" % r.status_code)
            return (False, r.status_code)
    except Exception as e:
        #logger.debug("The following exception occured while sending sms to %s\n%s" % (number, e.args))
        return (False, e.args)