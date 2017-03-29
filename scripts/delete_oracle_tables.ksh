#!/bin/ksh

################################
###Add time stamp in log files##
################################

LOGDATE="date +%m-%d-%Y::%T"

################################
##Delete records from tables####
################################

do_deleteData()
{
	echo "`$LOGDATE` Deleting records..."
	sqlplus -s $ORACLE_USER/$ORACLE_PASS@ORACLE_DBMS << EOF > deleteTables.log
	whenever OSERROR exit 9
	whenever SQLERROR exit SQL.SQLCODE
	SET HEADING OFF;
	SET VERIFY OFF;
	SET RECSEP OFF;

	exec oracle_schema_user.procedure('table_name');
	
	COMMIT;
	EXIT;
	
	EOF
	
	ret_status=$?
	ECHO "`$LOGDATE` Returned status after deletion is $ret_status"
	check_returnstatus $ret_status "while deleting tables"

}

################################
##Check return status###########
################################
check_returnstatus()
{
	ret_status=$1
	if [[ $ret_status -ne 0 ]] then
		echo "`$LOGDATE` Returned status is $ret_status"
		echo "`$LOGDATE` ERROR: $2"
		exit $1
	fi
}
################################
##Main #########################
################################
do_deleteData