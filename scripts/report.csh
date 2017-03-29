#!/bin/csh
source ~/.cshrc

set OUTPUT_DIR 	= $HOME/outputfiles
set DATE 		= `date "+%Y%m$d"`
set FILE_NAME	= "Report_`date "+%Y%m$d"`.csv"
set TO 			= "mail_list@host.com"
set REPORT_FILE = "OUTPUT_DIR/$FILE_NAME"
set SEPARATOR   = \'\,\'
set QUOTES		= \'
set TIME_ZONE 	= `date "+%Z"`
set MONTH_YR    = `perl -e 'use POSIX; print strftime "%b-%y", localtime time-86400;'`

echo "Connecting to $ORACLE_USER"
sqlplus -s $ORACLE_USER/$ORACLE_PASS@ORACLE_DBMS > /dev/null << EOF
SET PAGESIZE 200
SET LINESIZE 1500
SET HEADING OFF
SET FEEDBACK OFF
SET ESCAPE ON
SET ESCAPE ""

SPOOL $REPORT_FILE

SELECT 'COLUMN1, COLUMN2, COLUMN3, COLUMN4' FROM DUAL;

SELECT ID|| $SEPARATOR || ID_TYPE || $SEPARATOR ||  NAME || $SEPARATOR || CUSTOMER 
|| $SEPARATOR || TO_CHAR(DATE,'YYMMDD') || $SEPARATOR ||''
FROM sql_schema_user.table;

SPOOL OFF
EOF

ECHO "Report has been generated successfully."

######################################################
##Remove headers, blank lines and trailing using sed##
######################################################
sed '/^$/d' $REPORT_FILE > /tmp/$$.tmp/$$
sed 's/ *$//g' tmp/$$.tmp > $REPORT_FILE

rm -f /tmp/$$.tmp

######################################################
##Copy report to destination host##
######################################################

scp -i $HOME/.ssh/ -P 18065 $REPORT_FILE remote_user@$REMOTE_HOST_URL
set ret_status=$status
echo "Status of copying file is $ret_status"

######################################################
##Option to attach report via email##
######################################################

if (-e $REPORT_FILE && $ret_status == 0) then
	set size = `wc -l < $REPORT_FILE`
	echo "No of lines in Report is $size"
	mailx -s "Report for "$MONTH_YR $TO <<EOM

		Hello,

		Please find attached required report.

		Thank you,
		Support Team

	`uuencode $REPORT_FILE $FILE_NAME`

	EOM	
	echo "Mail sent successfully"
endif
######################################################
##Option to send notification only via email##
######################################################

if (-e $REPORT_FILE && $ret_status == 0) then
	set size = `wc -l < $REPORT_FILE`
	echo "No of lines in Report is $size"
	mailx -s "SUCCESS: Report for "$MONTH_YR $TO <<EOM

		Hello,

		Required report was successful generated.
		It contains $size lines.

		Thank you,
		Support Team

	EOM	
	echo "Mail sent successfully"
else
	echo "Generation of the report failed"
	mailx -s "FAILED: Report for "$MONTH_YR $TO <<EOM
		Hello,
		
		Required report failed.
		Please check.
		
		Thank you,
		Support Team
	EOM	
	echo "Mail sent successfully"
endif

exit 0
 
