#!/bin/csh
source ~/.cshrc

###############################
#####SETUP Environment#########
###############################

set LOGDATE 			= `date "+%d-%m-%Y:%T"`
set LOG_DIRECTORY 		= $DBCHOME/logs
set DATE 				= `date "+%Y%m%d"`
set TO 					= "support@mail.com"
set LOG_FILE_NAME 		= scriptlog.log
set LOG_ARCH_FILE_NAME  = scriptlog_archive.log
set LOGARCHNAME 		= $LOG_DIRECTORY
set SCRIPTHOME			= $HOME/scripts
##Set folders
set INPUTHOME  			= $HOME/input
set TEMP_DIRECTORY		= $HOME/temp
set PROCESSED_DIRECTORY = $HOME/processed
set CONFIG_DIRECTORY    = $HOME/config
##Set timestamp
set DATE_MMDDYYYY 		= `date "+%m%d%Y"`
set DATE_DDMonYYYY		= `date "+%d%h%Y"`
##Set constants
set INPUT_FILE_PATH     = $HOME/input
set INPUT_FILE_NAME     = Data_$DATE_DDMonYYYY
set ORACLE_DATABASE 	= $1
set DT					=`date +%d%m%y`
set NAME 				= $INPUT_FILE_NAME
set INPUT_FILE_FILE 	= $NAME".csv"
set DISCARD 			="Data.discard"
set FAILED 				="Data.failed"
set FILE 				=${NAME}".csv"
set CTRL				="DATA_EXTRACT.ctl"
set DATA_LOG			="DATA_EXTRACT.log"
set REPORT_DATA_LOG		="$LOG_DIRECTORY/$DATA_LOG" 
set DISCARD_DATA_LOG	="$LOG_DIRECTORY/$DISCARD.log"
set FAILED_DATA_LOG		="$LOG_DIRECTORY/$DATA_LOG"

echo $INPUT_FILE_NAME

###############################
###Archive previous log file###
###############################
	echo "$LOGDATE Finding previous file $LOG_FILE_NAME from $LOG_DIRECTORY for archiving in $LOG_DIRECTORY/old" >& $LOGARCHNAME
	if (-e $LOG_DIRECTORY/$LOG_FILE_NAME) then
		echo "$LOGDATE $LOG_DIRECTORY/$LOG_FILE_NAME found. Archiving.." >>& $LOGARCHNAME
	else
		echo "$LOGDATE $LOG_DIRECTORY/$LOG_FILE_NAME not found for archiving..." >>& $LOGARCHNAME
	endif
	echo "$LOGDATE Archiving completed..." >>& $LOGARCHNAME
	cat $LOGARCHNAME >>& $LOG_DIRECTORY/$LOG_FILE_NAME
	rm -f $LOGARCHNAME
###############################
###Process input file##########
###############################

if (-e $INPUTHOME/$FILE) then
##Move file to temp folder
	echo "$LOGDATE moving $INPUTHOME/$INPUT_FILE_FILE to $TEMP_DIRECTORY/$FILE" >>& $LOG_DIRECTORY/$LOG_FILE_NAME
	mv $INPUTHOME/$INPUT_FILE_FILE $TEMP_DIRECTORY/$FILE
###############################
###Truncate database table#####
###############################
sqlplus -s $ORACLE_USER/$ORACLE_PASS@$ORACLE_DBMS << EOF >>& $LOG_DIRECTORY/$LOG_FILE_NAME
	whenever OSERROR exit 9
	whenever SQLERROR exit SQL.SQLCODE
	SET HEADING OFF;
	SET VERIFY OFF;
	SET RECSEP OFF;
	EXEC ORACLE_SCHEMA_USER.truncate_table_procedure('table_name');
	COMMIT;
	EXIT;
EOF
set ret_status=$status
echo "$LOGDATE Return Status after truncating table: $ret_status" >>& $LOG_DIRECTORY/$LOG_FILE_NAME
#check_returnstatus "$ret_status while truncating table"
if ($ret_status !=0) then
	echo "$LOGDATE return status is $ret_status" >>& $LOG_DIRECTORY/$LOG_FILE_NAME
	echo "LOGDATE error while truncating the table" >>& $LOG_DIRECTORY/$LOG_FILE_NAME

	mailx -s "Error while truncating table" $TO<< EOM

	Hello,

	Error while truncating table.

	Thank you,
	Support Team

EOM
	echo "Mail was sent successfully" >>& $LOG_DIRECTORY/$LOG_FILE_NAME
	exit $ret_status
endif
###############################
###Insert data into table######
###############################
	echo "$LOGDATE SQLLOADER starting insertion into table..." >>& $LOG_DIRECTORY/$LOG_FILE_NAME
	
	sqlldr $ORACLE_USER/$ORACLE_PASS@$ORACLE_DBMS control =${CONFIG_DIRECTORY}/{CTRL} data=${TEMP_DIRECTORY}/${FILE} log=${LOG_DIRECTORY}/${DATA_LOG} bad=${LOG_DIRECTORY}/${FAILED} discard=${LOG_DIRECTORY}/${DISCARD} rows=100000 readsize=200000 bindsize=200000 errors=99999999
	set ret_status=$status
	echo "$LOGDATE Return status after sqlloader: $ret_status" >>& $LOG_DIRECTORY/$LOG_FILE_NAME
if ($ret_status !=0) then
		echo "$LOGDATE Return status is $ret_status" >>& $LOG_DIRECTORY/$LOG_FILE_NAME
		echo "$LOGDATE error while loading data into table" >>& $LOG_DIRECTORY/$LOG_FILE_NAME
		
	mail -x "Error while loading data to table" -a $REPORT_DATA_LOG $REPORT_DATA_LOG $TO<< EOM

	Hello,

	Error while loading data. Please check log file.

	Thank you,
	Support
EOM
	echo "Mail successfully sent" >>& $LOG_DIRECTORY/$LOG_FILE_NAME
	exit $ret_status
endif
echo "$LOGDATE SQLLoader Finished.." >>& $LOG_DIRECTORY/$LOG_FILE_NAME
	if (-e $LOG_DIRECTORY/$DISCARD) then
		echo "$LOGDATE there are discarded records, please check logs" >>& $LOG_DIRECTORY/$LOG_FILE_NAME
mailx -s "There are discarded records, please check logs" -a $DISCARD_DATA_LOG $TO<< EOM

	Hello,
	
	There are discarded records, please check logs.
	
	Thank you,
	Support
EOM
		echo "Mail sent successfully" >>& $LOG_DIRECTORY/$LOG_FILE_NAME
			exit 1
		elseif (-e $LOG_DIRECTORY/$FAILED) then
			echo "$LOGDATE there are records failed while insertion in database, please check logs" >>& $LOG_DIRECTORY/$LOG_DIRECTORY/$LOG_FILE_NAME
			mailx -s "There are records failed while insertion in database, please check logs" -a $FAILED_DATA_LOG $TO<< EOM
			Hello,
	
			There are records failed while insertion in database, please check logs.
	
			Thank you,
			Support
EOM
			echo "Mail was sent successfully" >>& $LOG_DIRECTORY/$LOG_FILE_NAME
			exit 1
		endif
		echo "Check logs $LOG_DIRECTORY/$DATA_LOG" >>& $LOG_DIRECTORY/$LOG_FILE_NAME
		echo "File was processed" >>& $LOG_DIRECTORY/$LOG_FILE_NAME
		else
			mailx -s "Extract file was not received" $TO<< EOM
			Hello,
			
			"Extract file was not received.
			
			Thank you,
			Support
EOM
		echo "Mail was sent successfully" >>& $LOG_DIRECTORY/$LOG_FILE_NAME
		echo "Exiting - input file was not found" >>& $LOG_DIRECTORY/$LOG_FILE_NAME
		exit 0
		endif
###############################
###Archiving processed file####
###############################

		echo "$LOGDATE Archiving files" >>& $LOG_DIRECTORY/$LOG_FILE_NAME
		mv $TEMP_DIRECTORY/$FILE $PROCESSED_DIRECTORY/$NAME
			echo "$LOGDATE Archiving completed..." >>& $LOG_DIRECTORY/$LOG_FILE_NAME
			

		
		



