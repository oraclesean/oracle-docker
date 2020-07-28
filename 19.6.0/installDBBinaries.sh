# Check whether ORACLE_BASE is set
if [ "$ORACLE_BASE" == "" ]; then
   echo "ERROR: ORACLE_BASE has not been set!"
   echo "You have to have the ORACLE_BASE environment variable set to a valid value!"
   exit 1;
fi;

# Check whether ORACLE_HOME is set
if [ "$ORACLE_HOME" == "" ]; then
   echo "ERROR: ORACLE_HOME has not been set!"
   echo "You have to have the ORACLE_HOME environment variable set to a valid value!"
   exit 1;
fi;

# Replace place holders
# ---------------------
sed -i -e "s|###ORACLE_EDITION###|$DB_EDITION|g" $INSTALL_DIR/$INSTALL_RSP_DB && \
sed -i -e "s|###ORACLE_BASE###|$ORACLE_BASE|g" $INSTALL_DIR/$INSTALL_RSP_DB && \
sed -i -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" $INSTALL_DIR/$INSTALL_RSP_DB

# Install Oracle binaries
#cd $ORACLE_HOME && \
#mv $INSTALL_DIR/$INSTALL_FILE_DB $ORACLE_HOME/ && \
unzip -oq -d $ORACLE_HOME $INSTALL_DIR/$INSTALL_FILE_DB && \
cp $INSTALL_DIR/$CONFIG_RSP_DB $ORACLE_BASE/dbca.rsp && \
rm $INSTALL_DIR/$INSTALL_FILE_DB && \
$ORACLE_HOME/runInstaller -silent -force -waitforcompletion -responsefile $INSTALL_DIR/$INSTALL_RSP_DB -ignorePrereqFailure && \
cd $HOME

# Install Oracle OPatch
unzip -oq -d $ORACLE_HOME $INSTALL_DIR/$OPATCH_FILE

# Install Oracle RU
PATCH_ID=$(echo $INSTALL_FILE_RU | sed 's/^p//' | cut -d_ -f1) && \
unzip -oq -d $INSTALL_DIR $INSTALL_DIR/$INSTALL_FILE_RU && \
cd $INSTALL_DIR/$PATCH_ID && \
$ORACLE_HOME/OPatch/opatch apply -silent && \
# Remove installation files
rm -rf $INSTALL_DIR/* && \
# Remove not needed components
# APEX
rm -rf $ORACLE_HOME/apex && \
# ORDS
rm -rf $ORACLE_HOME/ords && \
# SQL Developer
rm -rf $ORACLE_HOME/sqldeveloper && \
# UCP connection pool
rm -rf $ORACLE_HOME/ucp && \
# All installer files
rm -rf $ORACLE_HOME/lib/*.zip && \
# OUI backup
rm -rf $ORACLE_HOME/inventory/backup/* && \
# OPatch backups
#rm -rf $ORACLE_HOME/.opatch_storage/* && \
#rm -rf $ORACLE_HOME/.opatchauto_storage/* && \
# Network tools help
rm -rf $ORACLE_HOME/network/tools/help && \
# Remove pilot workflow installer
rm -rf $ORACLE_HOME/install/pilot && \
# Temp location
rm -rf /tmp/*
