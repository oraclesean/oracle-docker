# LICENSE UPL 1.0
#
# Copyright (c) 1982-2018 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# Pre-build a OEL7-slim image for use with database installation
# 
# HOW TO BUILD THIS IMAGE
# -----------------------
# Run: 
#      $ docker build -t dbready/oraclelinux:7-slim [--build-arg ORACLE_HOME={ORACLE_HOME}] . 
#
# Passing an argument for ORACLE_HOME is optional
#
# Pull base image
# ---------------
FROM oraclelinux:7-slim as base

# Pass ORACLE_HOME as a build-time argument
# -----------------------------------------
ARG ORACLE_HOME=/opt/oracle/product/19c/dbhome_1

# Maintainer
# ----------
MAINTAINER Sean Scott <oracle.sean@gmail.com>

# Environment variables required for this build
# ---------------------------------------------
ENV ORACLE_BASE=/opt/oracle \
    INSTALL_DIR=/opt/install 

ENV PATH=$ORACLE_HOME/bin:$ORACLE_HOME/OPatch/:/usr/sbin:$PATH \
    LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/lib \
    CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib

RUN yum -y update; yum clean all && \
    mkdir -p $ORACLE_BASE/{scripts/{setup,startup},oradata} && \
    mkdir -p $ORACLE_HOME && \
    ln -s $ORACLE_BASE/scripts /docker-entrypoint-initdb.d

RUN yum install -y oracle-database-preinstall-19c openssl vi less which strace perl perl-Digest-MD5 perl-Data-Dumper; yum clean all && \
    rm -rf /var/cache/yum && \
    echo oracle:oracle | chpasswd && \
    chown -R oracle:dba $ORACLE_BASE

