#!/bin/bash

# The script is called with the configuration file as the only argument
# e.g. ./rsync-mirror.sh config.cfg 
source $1
# BACKUP_DIR
# LOG_DIR
# LOG_FILE
# LOG_PATH
# LOCK_FILE
# EMAIL_SUBJECT
# EMAIL_FROM
# EMAIL_TO
# RSYNC_BIN
# TEE_BIN
# MAIL_BIN
# HOSTS

if [ -e $LOCK_FILE ]
then
	echo "Sync already running... exiting" 2>&1 | $TEE_BIN -a $LOG_PATH
	exit 0
fi

# Only allow one sync to run at a time
touch $LOCK_FILE 2>&1 | $TEE_BIN -a $LOG_PATH

echo "Start:" $(date) 2>&1 | $TEE_BIN -a $LOG_PATH

# Loop through hosts from configuration file and rsync each directory
for LINE in $HOSTS
do
	SOURCE_HOST="$(echo $LINE | cut -d: -f1)"
	SOURCE_DIR="$(echo $LINE | cut -d: -f2)"
	TARGET_DIR="$BACKUP_DIR$(echo $LINE | cut -d: -f3)"
	
	echo "Syncing $SOURCE_HOST:$SOURCE_DIR..." 2>&1 | $TEE_BIN -a $LOG_PATH

	if ! test -d $TARGET_DIR
	then
		mkdir -p $TARGET_DIR
	fi	

	$RSYNC_BIN -av --delete $SOURCE_HOST:$SOURCE_DIR $TARGET_DIR 2>&1 | $TEE_BIN -a $LOG_PATH
done

echo "End:" $(date) 2>&1 | $TEE_BIN -a $LOG_PATH

rm -f $LOCK_FILE 2>&1 | $TEE_BIN -a $LOG_PATH

echo "" 2>&1 | $TEE_BIN -a $LOG_PATH

# Email the results to $EMAIL_TO
echo -ne "$(cat $LOG_PATH)" | $MAIL_BIN -a "From: "$EMAIL_FROM -s "$EMAIL_SUBJECT" $EMAIL_TO 2>&1 | $TEE_BIN -a $LOG_PATH
