#!/bin/ksh

## Print timestamp in log lines
LOGDATE = "date +%m-%d-%Y::%T"
##################################
####Copy Data to database#########
##################################
do_copyData()

{
echo "`$LOGDATE` Copying records from downstream tables..."
$ORACLE_HOME/bin/sqlplus -s $ORACLE_USER/$ORACLE_PASS@$ORACLE_DBMS << EOF >> $HOME/logs/copyOracleTables.log
whenever OSERROR exit 9
whenever SQLERROR exit SQL.SQLCODE
SET HEADING OFF;
SET VERIFY OFF;
SET RECSEP OFF;

COPY FROM $DES_ORACLE_USER/$DES_ORACLE_PASS@DES_ORACLE_DBMS TO $ORACLE_USER/$ORACLE_PASS@$ORACLE_DBMS
INSERT local_schema_user.table
USING SELECT * remote_table;
COMMIT;
EXIT;

EOF

ret_status=$?

ECHO "`LOGDATE` Return status after inserting into Database: $ret_status"
check_returnstatus $ret_status "while inserting into Database"

}

##################################
####Check return status###########
##################################
check_returnstatus()
{
	ret_status=$1
	if [[ $ret_status -ne 0 ]] then
			echo "`$LOGDATE` Retrun status is $ret_status"
			echo "`$LOGDATE` ERROR: $2"
			exit $1
	fi
}

##################################
############# Main ###############
##################################
do_copyData