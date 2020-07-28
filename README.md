# oracle-docker
This repository is a collected home for Oracle/Docker projects. It superscedes any older Docker project directories.
# Contents
## 11.2.0.4
Oracle 11.2.0.4 database on Oracle Linux 7.
## 19.6.0
Oracle 19.6.0 database on Oracle Linux 7.
Installs Oracle 19.3.0 zip and patches with the 19.6 RU (p30557433).
## 19.7.0
Oracle 19.7.0 database on Oracle Linux 7.
Installs Oracle 19.3.0 zip and patches with the 19.7 RU (p30869156).
## 19.7.0-rpm
Oracle 19.7.0 database on Oracle Linux 7 (RPM installation).
Installs Oracle 19.3.0 using the 19c RPM (oracle-database-ee-19c-1.0-1.x86_64.rpm) and patches with the 19.7 RU (p30869156). Database start/stop managed via init.d scripts. Produces a slightly smaller image size.
## 19.8.0-rpm
Installs Oracle 19.3.0 using the 19c RPM (oracle-database-ee-19c-1.0-1.x86_64.rpm) and patches with the 19.7 RU (p31281355). Database start/stop managed via init.d scripts. Produces a slightly smaller image size.
## dataguard
Docker Compose orchestrated two-database configuration with image builds for Oracle 19.3.0.
## gsm
Image build including both Oracle 19.3.0 and Oracle GSM. This is the base image for running containers requiring a database and Global Data Services.
## oel7base
A modified Oracle Enterprise Linux 7 image that is "database-ready" with multiple packages pre-installed:
* oracle-database-preinstall-19c
* less
* openssl
* perl
* perl-Data-Dumper
* perl-Digest-MD5
* strace
* vi
* which
This is a convenient starting image for developing container images, particularly those intended to be used interactively for testing/experimenting/evaluation.
## sharding
Docker Compose orchestrated Sharded database. Creates a catalog database and 2 or more shard databases using Oracle 19.3.0. A configuration file allows users to define database/container names, ports, customize the catalog, set up multiple shard directors, and run the shards with/without Data Guard.
## tfa
Base image build for TFA/AHF 20.2. Does not include a database but this image can be used in a FROM to run TFA-ready database installations.
## upgrade
Dockerfiles for building images with multiple Oracle Home directories merged from source and target images. Containers start normally by creating a database under the source Oracle Home. A second, target home is preinstalled and ready for upgrade testing using DBUA, Autoupgrade, etc.
