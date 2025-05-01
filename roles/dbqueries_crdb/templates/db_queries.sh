#!/bin/bash

DBHOST={{ DBHOST }}
DBUSER={{ DBUSER }}
DBPORT={{ DBPORT }}
PASSWORD={{ PASSWORD }}
TXNDB={{ ADMINDB }}
ADMINDB={{ TXNDB }}
DATE={{ DATE }}
TODAYDATE=`date +%d_%m_%Y`

### Count of Master Rows ###

function COUNTMASTERROWS
{
# Transactional

OUTPUT1=$(sqlplus -S -L $DBUSER/$PASSWORD@$DBHOST:$DBPORT/MOBIPRDTZ <<EOF
SELECT COUNT(*) FROM TBLTransactionHistory WHERE TransactionType='CR';
exit;
EOF
)
TMRCR=$(echo $OUTPUT1 | awk '{print $3}')

OUTPUT2=$(sqlplus -S -L $DBUSER/$PASSWORD@$DBHOST:$DBPORT/MOBIPRDTZ <<EOF
SELECT COUNT(*) FROM TBLTransactionHistory WHERE TransactionType='DR';
exit;
EOF
)
TMRDR=$(echo $OUTPUT2 | awk '{print $3}')

echo "Count of Transactional master rows is CR=$TMRCR + DR=$TMRDR" >> {{ DIRECTORY }}/{{ PROJECT }}_Audit_report_db_{{ lookup('pipe', 'date +%d%m%Y') }}.txt

# Non-Transactional

OUTPUT3=$(sqlplus -S -L $DBUSER/$PASSWORD@$DBHOST:$DBPORT/MOBIPRDTZ <<EOF
SELECT COUNT(*) FROM TBLTransactionHistory WHERE TransactionType='DR';
exit;
EOF
)
NTMR=$(echo $OUTPUT3 | awk '{print $3}')

echo "Count of Non-Transactional master rows is $NTMR" >> {{ DIRECTORY }}/{{ PROJECT }}_Audit_report_db_{{ lookup('pipe', 'date +%d%m%Y') }}.txt
}

#########################################

### Oldest row in DB ###

function OLDESTROW
{
# Transactional

OUTPUT4=$(sqlplus -S -L $DBUSER/$PASSWORD@$DBHOST:$DBPORT/MOBIPRDTZ <<EOF
SELECT TransactionTime FROM TBLTransactionHistory WHERE TransactionType='CR' ORDER BY TransactionTime ASC FETCH FIRST 1 ROW ONLY;
exit;
EOF
)
TORCR=$(echo $OUTPUT4 | awk '{$1=""; $2=""; print substr($0,3)}')

OUTPUT5=$(sqlplus -S -L $DBUSER/$PASSWORD@$DBHOST:$DBPORT/MOBIPRDTZ <<EOF
SELECT TransactionTime FROM TBLTransactionHistory WHERE TransactionType='DR' ORDER BY TransactionTime ASC FETCH FIRST 1 ROW ONLY;
exit;
EOF
)
TORDR=$(echo $OUTPUT5 | awk '{$1=""; $2=""; print substr($0,3)}')

echo "Oldest row in DB for Transactional is CR=$TORCR and DR=$TORDR" >> {{ DIRECTORY }}/{{ PROJECT }}_Audit_report_db_{{ lookup('pipe', 'date +%d%m%Y') }}.txt

# Non-Transactional

OUTPUT6=$(sqlplus -S -L $DBUSER/$PASSWORD@$DBHOST:$DBPORT/MOBIPRDTZ <<EOF
SELECT TransactionTime FROM TBLNonTransactionHST ORDER BY TransactionTime ASC FETCH FIRST 1 ROW ONLY;
exit;
EOF
)
NTOR=$(echo $OUTPUT6 | awk '{$1=""; $2=""; print substr($0,3)}')

echo "Oldest row in DB for Non-Transactional is $NTOR" >> {{ DIRECTORY }}/{{ PROJECT }}_Audit_report_db_{{ lookup('pipe', 'date +%d%m%Y') }}.txt
}

#########################################

### Count of FSM APIs"

function FSMAPI
{

OUTPUT7=$(sqlplus -S -L CRDBELITE_ADMIN/$PASSWORD@$DBHOST:$DBPORT/MOBIPRDTZ <<EOF
select COUNT(*) from TBLMAdapterApi;
exit;
EOF
)
FSMAPI=$(echo $OUTPUT7 | awk '{print $3}')

echo "Count of FSM APIs is $FSMAPI" >> {{ DIRECTORY }}/{{ PROJECT }}_Audit_report_db_{{ lookup('pipe', 'date +%d%m%Y') }}.txt
}

#########################################

### Users ###

function USERS
{

OUTPUT8=$(sqlplus -S -L $DBUSER/$PASSWORD@$DBHOST:$DBPORT/MOBIPRDTZ <<EOF
SELECT UserAccountCategoryTypeId , COUNT(*) FROM TBLUserAccount GROUP BY UserAccountCategoryTypeId;
exit;
EOF
)
SUSER=$(echo $OUTPUT8 | awk '{print $8}')
EUSER=$(echo $OUTPUT8 | awk '{print $6}')

echo "Count of System users is $SUSER" >> {{ DIRECTORY }}/{{ PROJECT }}_Audit_report_db_{{ lookup('pipe', 'date +%d%m%Y') }}.txt
echo "Count of End users is $EUSER" >> {{ DIRECTORY }}/{{ PROJECT }}_Audit_report_db_{{ lookup('pipe', 'date +%d%m%Y') }}.txt
}

#########################################

### Last 24 hours API Requests ###

function APIREQ
{
echo "APIEXTERNALID,COUNT_PER_API_NAME" >> {{ DIRECTORY }}/{{ PROJECT }}_Last_24h_API_{{ lookup('pipe', 'date +%d%m%Y') }}.csv
sqlplus -S -L $DBUSER/$PASSWORD@$DBHOST:$DBPORT/MOBIPRDTZ <<EOF
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SET COLSEP ','
SPOOL /tmp/output.csv
SELECT APIEXTERNALID || ',' || COUNT(*) AS Count_Per_API_Name FROM TBLTRANSACTIONEVENTDETAIL
WHERE  REQUESTTIME > TIMESTAMP '{{ DATE }} 00:00:00' AND REQUESTTIME <= TIMESTAMP '{{ DATE }} 23:59:59' GROUP BY APIEXTERNALID;
SPOOL OFF
exit;
EOF
cat /tmp/output.csv >> {{ DIRECTORY }}/{{ PROJECT }}_Last_24h_API_{{ lookup('pipe', 'date +%d%m%Y') }}.csv
} > /dev/null

#########################################

COUNTMASTERROWS
OLDESTROW
APIREQ
FSMAPI
USERS
