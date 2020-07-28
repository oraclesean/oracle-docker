#!/bin/bash

set -e

# Check whether ORACLE_SID is passed on
export ORACLE_SID=${1:-ORCLCDB}

# Check whether ORACLE_PDB_COUNT is passed on
export ORACLE_PDB_COUNT=${2:-1}

# Check whether ORACLE_PDB is passed on
export ORACLE_PDB=${3:-${ORACLE_SID}PDB}

# Auto generate ORACLE PWD if not passed on
export ORACLE_PWD=${4:-"`openssl rand -base64 8`1"}
echo "ORACLE PASSWORD FOR SYS, SYSTEM AND PDBADMIN: $ORACLE_PWD";

# Replace place holders in response file
sed -i -e "s|###ORACLE_SID###|$ORACLE_SID|g" $ORACLE_BASE/dbca.rsp
sed -i -e "s|###ORACLE_PDB_COUNT###|$ORACLE_PDB_COUNT|g" $ORACLE_BASE/dbca.rsp
sed -i -e "s|###ORACLE_PDB###|$ORACLE_PDB|g" $ORACLE_BASE/dbca.rsp
sed -i -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" $ORACLE_BASE/dbca.rsp
sed -i -e "s|###ORACLE_EM_CONFIG###|$ORACLE_EM_CONFIG|g" $ORACLE_BASE/dbca.rsp
sed -i -e "s|###ORACLE_CHARACTERSET###|$ORACLE_CHARACTERSET|g" $ORACLE_BASE/dbca.rsp
sed -i -e "s|###ORACLE_NLS_CHARACTERSET###|$ORACLE_NLS_CHARACTERSET|g" $ORACLE_BASE/dbca.rsp

# If there is greater than 8 CPUs default back to dbca memory calculations
# dbca will automatically pick 40% of available memory for Oracle DB
# The minimum of 2G is for small environments to guarantee that Oracle has enough memory to function
# However, bigger environment can and should use more of the available memory
# This is due to Github Issue #307
if [ `nproc` -gt 8 ]; then
   sed -i -e "s|totalMemory=2048||g" $ORACLE_BASE/dbca.rsp
fi;

cat << EOF >> $HOME/.bashrc

alias $(echo $ORACLE_SID | tr [A-Z] [a-z])="export ORACLE_SID=$ORACLE_SID; export ORACLE_HOME=$ORACLE_HOME; export LD_LIBRARY_PATH=$ORACLE_HOME/l
ib; export PATH=$ORACLE_HOME/bin:$ORACLE_HOME/OPatch/:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
EOF

# Create network related config files (sqlnet.ora, tnsnames.ora, listener.ora)
mkdir -p $ORACLE_HOME/network/admin
echo "NAME.DIRECTORY_PATH= (TNSNAMES, EZCONNECT, HOSTNAME)" > $ORACLE_HOME/network/admin/sqlnet.ora

# Listener.ora
echo "LISTENER = 
(DESCRIPTION_LIST = 
  (DESCRIPTION = 
    (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1)) 
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521)) 
  ) 
) 

DEDICATED_THROUGH_BROKER_LISTENER=ON
DIAG_ADR_ENABLED = off
" > $ORACLE_HOME/network/admin/listener.ora

# Start LISTENER and run DBCA
lsnrctl start &&
env | sort &&
ls -l $ORACLE_BASE &&
ls $ORACLE_HOME &&
dbca -silent -redoLogFileSize 250 -createDatabase -responseFile $ORACLE_BASE/dbca.rsp ||
 cat /opt/oracle/cfgtoollogs/dbca/$ORACLE_SID/$ORACLE_SID.log ||
 cat /opt/oracle/cfgtoollogs/dbca/$ORACLE_SID.log

# Run datapatch
$ORACLE_HOME/OPatch/datapatch -verbose

echo "$ORACLE_SID=localhost:1521/$ORACLE_SID" > $ORACLE_HOME/network/admin/tnsnames.ora
 for pdb in {1..$ORACLE_PDB_COUNT}
  do echo "${ORACLE_PDB}${pdb} = 
(DESCRIPTION = 
  (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
  (CONNECT_DATA =
    (SERVER = DEDICATED)
    (SERVICE_NAME = ${ORACLE_PDB}${pdb})
  )
)
" >> $ORACLE_HOME/network/admin/tnsnames.ora
done

# Remove second control file, fix local_listener, make PDB auto open, enable EM global port
sqlplus / as sysdba << EOF
   ALTER SYSTEM SET control_files='$ORACLE_BASE/oradata/$ORACLE_SID/control01.ctl' scope=spfile;
   ALTER SYSTEM SET local_listener='';
   noaudit all;
   noaudit all on default;
   ALTER PLUGGABLE DATABASE ALL OPEN;
   ALTER PLUGGABLE DATABASE ALL SAVE STATE;
   EXEC DBMS_XDB_CONFIG.SETGLOBALPORTENABLED (TRUE);
   exit;
EOF

# Remove temporary response file
rm $ORACLE_BASE/dbca.rsp
. oraenv <<< $ORACLE_SID

# Moved the moveFiles/symLinkFiles functionality from runOracle.sh to here to preserve the files and create the links properly.

  if [ ! -d $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID ]; then
     mkdir -p $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
fi;

mv $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
mv $ORACLE_HOME/dbs/orapw$ORACLE_SID $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
mv $ORACLE_HOME/network/admin/sqlnet.ora $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
mv $ORACLE_HOME/network/admin/listener.ora $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
mv $ORACLE_HOME/network/admin/tnsnames.ora $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/

# oracle user does not have permissions in /etc, hence cp and not mv
cp /etc/oratab $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/

  if [ ! -L $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora ]
then   if [ -f $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora ]
     then mv $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
     fi;
     ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/spfile$ORACLE_SID.ora $ORACLE_HOME/dbs/spfile$ORACLE_SID.ora
fi;

  if [ ! -L $ORACLE_HOME/dbs/orapw$ORACLE_SID ]
then   if [ -f $ORACLE_HOME/dbs/orapw$ORACLE_SID ]
     then mv $ORACLE_HOME/dbs/orapw$ORACLE_SID $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
     fi;
     ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/orapw$ORACLE_SID $ORACLE_HOME/dbs/orapw$ORACLE_SID
fi;

  if [ ! -L $ORACLE_HOME/network/admin/sqlnet.ora ]
then   if [ -f $ORACLE_HOME/network/admin/sqlnet.ora ]
     then mv $ORACLE_HOME/network/admin/sqlnet.ora $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
     fi;
     ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/sqlnet.ora $ORACLE_HOME/network/admin/sqlnet.ora
fi;

  if [ ! -L $ORACLE_HOME/network/admin/listener.ora ]
then   if [ -f $ORACLE_HOME/network/admin/listener.ora ]
     then mv $ORACLE_HOME/network/admin/listener.ora $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
     fi;
     ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/listener.ora $ORACLE_HOME/network/admin/listener.ora
fi;

  if [ ! -L $ORACLE_HOME/network/admin/tnsnames.ora ]
then   if [ -f $ORACLE_HOME/network/admin/tnsnames.ora ]
     then mv $ORACLE_HOME/network/admin/tnsnames.ora $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/
     fi;
     ln -s $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/tnsnames.ora $ORACLE_HOME/network/admin/tnsnames.ora
fi;

# oracle user does not have permissions in /etc, hence cp and not ln
  if [ -f $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/oratab ]
then cp $ORACLE_BASE/oradata/dbconfig/$ORACLE_SID/oratab /etc/oratab
fi;

# End of moveFiles/symLinkFiles component

# Add SQLPlus settings to glogin
echo "
set pages 9999 lines 250" >> $ORACLE_HOME/sqlplus/admin/glogin.sql
