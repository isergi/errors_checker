# /bin/sh log_checker.sh /var/log/apache2/access.log PavlovSerg@mail.ru test@test.com,test2@test.com

ACCESS_LOG_PATH=$1

EMAILS_LIST=$2

CRITICAL_EMAILS_LIST=$3

MAX_404_ERRORS_PER_30_MINUTES=1
MAX_500_ERRORS_PER_30_MINUTES=1

IFS=', ' read -r -a emails <<< "$EMAILS_LIST"

IFS=', ' read -r -a critical_emails <<< "$CRITICAL_EMAILS_LIST"

if [ ! -e $ACCESS_LOG_PATH ]; then
  	echo "Log file not found $ACCESS_LOG_PATH";
	exit;
fi


checked_minutes=$(date +"%M");

if [[ "$checked_minutes" -gt 29 ]]; then
        checked_date=$(date +"\[%d/%b/%Y:%H:[345]");
else
	checked_date=$(date +"\[%d/%b/%Y:%H:[012]");
fi

errors_404_count="$(grep ' 404 ' $ACCESS_LOG_PATH | grep $checked_date | wc -l)"
if [[ "$errors_404_count" -gt $MAX_404_ERRORS_PER_30_MINUTES ]]; then
	for email_for_notification in "${emails[@]}"
	do
    		echo "Too many requests by type 404 in the last 30 minutes ($errors_404_count)! Please check the access log file [$ACCESS_LOG_PATH]!" | mail -s ALERT_404_ERROR $email_for_notification
	done
fi

errors_500_count="$(grep ' 500 ' $ACCESS_LOG_PATH | grep $checked_date | wc -l)"

if [[ "$errors_500_count" -gt $MAX_500_ERRORS_PER_30_MINUTES ]]; then
        for email_for_notification in "${emails[@]}"
        do
                echo "ALARM! We have errors of type 500 in the last 30 minutes ($errors_500_count)!!! Please check the access log file [$ACCESS_LOG_PATH]!" | mail -s ALERT_500_ERROR $email_for_notification
        done
	for email_for_notification in "${critical_emails[@]}"
        do
                echo "ALARM! We have errors of type 500 in the last 30 minutes ($errors_500_count)!!! Please call someone from the TECH emergency!" | mail -s ALERT_500_ERROR $email_for_notification
        done
fi
