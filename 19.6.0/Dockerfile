FROM oraclelinux:7-slim as base
MAINTAINER Sean Scott <sean.scott@viscosityna.com>
ARG ORACLE_HOME=/opt/oracle/product/19c/dbhome_1
ARG INSTALL_DIR=/opt/install
ARG CHECK_SPACE_FILE="checkSpace.sh"

ENV ORACLE_BASE=/opt/oracle \
    ORACLE_HOME=$ORACLE_HOME \
    RUN_FILE="runOracle.sh" \
    START_FILE="startDB.sh" \
    CREATE_DB_FILE="createDB.sh" \
    CHECK_DB_FILE="checkDBStatus.sh" \
    USER_SCRIPTS_FILE="runUserScripts.sh"

# Use second ENV so that variable get substituted
ENV PATH=$ORACLE_HOME/bin:$ORACLE_HOME/OPatch/:/usr/sbin:$PATH \
    LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/lib \
    CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib

# Copy files needed during both installation and runtime
# -------------
COPY $CHECK_SPACE_FILE $INSTALL_DIR/
COPY $RUN_FILE $START_FILE $CREATE_DB_FILE $CHECK_DB_FILE $USER_SCRIPTS_FILE $ORACLE_BASE/

RUN yum -y update; yum clean all && \
    yum install -y oracle-database-preinstall-19c openssl vi less which strace; yum clean all && \
    rm -rf /var/cache/yum && \
    sync && \
    mkdir -p $ORACLE_BASE/{scripts/{setup,startup},oradata} && \
    mkdir -p $ORACLE_HOME && \
    echo oracle:oracle | chpasswd && \
    chown -R oracle:dba $ORACLE_BASE && \
    chmod ug+x $ORACLE_BASE/*.sh && \
    chmod ug+x $INSTALL_DIR/*.sh && \
    ln -s $ORACLE_BASE/scripts /docker-entrypoint-initdb.d && \
    $INSTALL_DIR/$CHECK_SPACE_FILE && \
    rm -rf $INSTALL_DIR

#############################################
# Start new stage for installing the database
#############################################
FROM base AS builder
ARG DB_EDITION
ARG INSTALL_DIR=/opt/install
ARG INSTALL_FILE_DB="LINUX.X64_193000_db_home.zip"
ARG INSTALL_FILE_RU="p30557433_190000_Linux-x86-64.zip"
ARG OPATCH_FILE="p6880880_190000_Linux-x86-64.zip"
ARG CONFIG_RSP_DB="dbca.rsp.tmpl"
ARG INSTALL_RSP_DB="db_inst.rsp"
ARG INSTALL_DB_BINARIES_FILE="installDBBinaries.sh"

# Copy DB install file
COPY --chown=oracle:dba $INSTALL_FILE_DB $INSTALL_FILE_RU $OPATCH_FILE $INSTALL_RSP_DB $CONFIG_RSP_DB $INSTALL_DB_BINARIES_FILE $INSTALL_DIR/

# Install DB software binaries
USER oracle
RUN chmod ug+x $INSTALL_DIR/*.sh && \
    sync && \
    $INSTALL_DIR/$INSTALL_DB_BINARIES_FILE $DB_EDITION

#############################################
# Start new layer for database runtime
#############################################
FROM base
USER oracle
COPY --chown=oracle:dba --from=builder $ORACLE_BASE $ORACLE_BASE

USER root
RUN $ORACLE_BASE/oraInventory/orainstRoot.sh && \
    $ORACLE_HOME/root.sh

USER oracle
WORKDIR /home/oracle

VOLUME ["$ORACLE_BASE/oradata"]
EXPOSE 1521 5500
HEALTHCHECK --interval=1m --start-period=5m \
   CMD "$ORACLE_BASE/$CHECK_DB_FILE" >/dev/null || exit 1

# Define default command to start Oracle Database. 
CMD exec $ORACLE_BASE/$RUN_FILE
