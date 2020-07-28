FROM oraclelinux:7-slim as base
MAINTAINER Sean Scott <sean.scott@viscosityna.com>

# Set ARGs, keep the environment clean
ARG ORACLE_BASE=/opt/oracle
ARG ORACLE_HOME=/opt/oracle/product/11.2.0/dbhome_1
ARG INSTALL_DIR=/opt/install
ARG ORACLE_SID=ORCL

ENV ORACLE_BASE=$ORACLE_BASE \
    ORACLE_HOME=$ORACLE_HOME \
    ORACLE_SID=$ORACLE_SID \
    ORACLE_VERSION=11g \
    ORACLE_DOCKER_INSTALL=true \
    SQLPATH=/home/oracle \
    CHECK_DB_STATUS=checkDBStatus.sh \
    CREATE_DB_FILE=createDB.sh \
    RUN_FILE=runOracle.sh \
    START_FILE="startDB.sh" \
    USER_SCRIPTS_FILE="runUserScripts.sh"

ENV PATH=$ORACLE_HOME/bin:$ORACLE_HOME/OPatch/:/usr/sbin:$PATH \
    CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib \
    LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/lib \
    TNS_ADMIN=$ORACLE_HOME/network/admin

COPY $CHECK_DB_STATUS $CREATE_DB_FILE $RUN_FILE $START_FILE $USER_SCRIPTS_FILE $ORACLE_BASE/

# Build base image with 19c preinstall and Things I Like To Have (epel, git, less, rlwrap, strace, vi), all optional.
# file-5.11, openssl, sudo are necessary (file-5.11 = prereq for 19c RPM, sudo for startup via init.d)
RUN yum -y update; yum -y install oracle-database-preinstall-19c oracle-epel-release-el7 file-5.11-36.el7.x86_64 git less openssl strace sudo vi which && \
    # Create directories, own things, permissions
    mkdir -p {$INSTALL_DIR,$ORACLE_HOME,$ORACLE_BASE/{scripts/{setup,startup},oradata/dbconfig/$ORACLE_SID}} && \
    chown -R oracle:oinstall $ORACLE_BASE $INSTALL_DIR && \
    chmod ug+x $ORACLE_BASE/*.sh && \
    sync && \
    # The 11gR2 pre-install adds additional prerequisites; group membership is incorrect, thus the 19c RPM runs first.
    yum -y install rlwrap oracle-rdbms-server-11gR2-preinstall && \
    # Create the entrypoint:
    ln -s $ORACLE_BASE/scripts /docker-entrypoint-initdb.d && \
    # Manage the oracle user:
    echo oracle:oracle | chpasswd && \
    yum clean all

FROM base as builder

ARG INSTALL_FILE_1=p13390677_112040_Linux-x86-64_1of7.zip
ARG INSTALL_FILE_2=p13390677_112040_Linux-x86-64_2of7.zip
ARG OPATCH=p6880880_112000_Linux-x86-64.zip
ARG DBRU=p28364007_112040_Linux-x86-64.zip
ARG DBRU_ID=28364007
ARG INSTALL_DIR=/opt/install
ARG DB_INST=db_inst.rsp
ARG DBCA_RSP=dbca.rsp
ARG DB_EDITION=EE

COPY --chown=oracle:oinstall $INSTALL_FILE_1 $INSTALL_FILE_2 $DBRU $OPATCH $DB_INST $INSTALL_DIR/
COPY --chown=oracle:oinstall $DBCA_RSP $ORACLE_BASE/

USER oracle
RUN unzip -oq -d $INSTALL_DIR $INSTALL_DIR/$INSTALL_FILE_1 && \
    unzip -oq -d $INSTALL_DIR $INSTALL_DIR/$INSTALL_FILE_2 && \
    unzip -oq -d $INSTALL_DIR $INSTALL_DIR/$DBRU && \
    # Update the install response file
    sed -i -e "s|###ORACLE_EDITION###|$DB_EDITION|g" -e "s|###ORACLE_BASE###|$ORACLE_BASE|g" -e "s|###ORACLE_HOME###|$ORACLE_HOME|g" $INSTALL_DIR/$DB_INST && \
    $INSTALL_DIR/database/runInstaller -ignorePrereq -ignoreSysPrereqs -silent -responseFile $INSTALL_DIR/$DB_INST -waitForCompletion

USER root
RUN $ORACLE_BASE/oraInventory/orainstRoot.sh && \
    $ORACLE_HOME/root.sh

USER oracle
    # Update OPatch
RUN unzip -oq -d $ORACLE_HOME $INSTALL_DIR/$OPATCH && \
    # Apply the RU
    $ORACLE_HOME/OPatch/opatch napply -silent $INSTALL_DIR/$DBRU_ID && \
    # The following errors may appear during patch installation; they may be ignored:
    #     ins_emagent.mk:113: warning: overriding recipe for target `nmosudo'
    #     ins_emagent.mk:52: warning: ignoring old recipe for target `nmosudo'
    # See Doc ID 1562458.1 for details.
    rm -fr $INSTALL_DIR/*

FROM base

ENV ORACLE_BASE=$ORACLE_BASE \
    ORACLE_HOME=$ORACLE_HOME \
    ORACLE_SID=$ORACLE_SID \
    ORACLE_VERSION=11g \
    ORACLE_DOCKER_INSTALL=true \
    CHECK_DB_STATUS=checkDBStatus.sh \
    CREATE_DB_FILE=createDB.sh \
    RUN_FILE=runOracle.sh \
    START_FILE="startDB.sh" \
    USER_SCRIPTS_FILE="runUserScripts.sh"

ENV PATH=$ORACLE_HOME/bin:$ORACLE_HOME/OPatch/:/usr/sbin:$PATH \
    CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib \
    LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/lib \
    TNS_ADMIN=$ORACLE_HOME/network/admin

USER oracle
COPY --chown=oracle:oinstall --from=builder $ORACLE_BASE $ORACLE_BASE
COPY --chown=oracle:oinstall --from=builder /etc/oratab /etc/oratab

WORKDIR /home/oracle

VOLUME ["$ORACLE_BASE/oradata"]
EXPOSE 1521 5500
HEALTHCHECK --interval=1m --start-period=5m \
   CMD "$ORACLE_BASE/$CHECK_DB_STATUS" >/dev/null || exit 1

# Define default command to start Oracle Database.
CMD exec $ORACLE_BASE/$RUN_FILE
