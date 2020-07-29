# Oracle 11.2.0.4 Database on Docker
## Prepare the Docker directory
Download the Oracle 11.2.0.4 installation binaries from My Oracle Support (MOS)
```
p13390677_112040_Linux-x86-64_1of7.zip
p13390677_112040_Linux-x86-64_2of7.zip
```
Download the Oracle 11.2.0.4.181016 Security Update and latest OPatch for Oracle 11.2 on Linux x86-64:
```
p28364007_112040_Linux-x86-64.zip
p6880880_112000_Linux-x86-64.zip
```

## Create an Image
Navigate to the directory including the Dockerfile and execute the following to build the database image:
```
export DB_EDITION=EE
docker build --force-rm=true --no-cache=true --build-arg DB_EDITION=$DB_EDITION -t database:11.2.0.4-$DB_EDITION .
```
Options for DB_EDITION are EE, SE.

Additional install options are available to customize the ORACLE_HOME and ORACLE_BASE directories by specifying `--build-arg ORACLE_BASE=/dir/path` and/or `--build-arg ORACLE_HOME=/dir/path/product/dir`.

## Running Containers
Pass environment values during `docker run` with the `-e` flag. Options include:
* ORACLE_SID - Database SID (default: ORCL)
* ORACLE_PWD - Password for SYS, SYSTEM, DBSNMP (Randomly generated if not specified)
* ORACLE_CHARACTERSET - Database character set (default: AL32UTF8)
* NLS_CHARACTERSET - NLS character set (default: AL16UTF16)

## Errata
### Warnings for `nmosudo`
The 11.2.0.4.181016 Security Update application will complete with a warning:
```
ins_emagent.mk:113: warning: overriding recipe for target `nmosudo'
ins_emagent.mk:52: warning: ignoring old recipe for target `nmosudo'
```
These may be ignored. See Doc ID 1562458.1 for details.

### DBCA reports "Aurora assertion failure"
If `JAVA_JIT_ENABLED` is set to TRUE, DBCA will fail/hang at 74% with:
```
ORA-29516: Aurora assertion failure: Assertion failure at joez.c:3422
```
Pass `JAVA_JIT_ENABLED=false` to DBCA. In this build the parameter is passed in dbca.rsp:
```
INITPARAMS="JAVA_JIT_ENABLED=false"
```

### Use of 19c and 11g Preinstall RPM
If the group membership for the oracle user is not set properly, database software installation will fail with:
```
[FATAL] [INS-32038] The operating system group specified for central inventory (oraInventory) ownership is invalid.
   CAUSE: User performing installation is not a member of the operating system group specified for central inventory(oraInventory) ownership.
   ACTION: Specify an operating system group that the installing user is a member of. All the members of this operating system group will have write permission to the central inventory directory (oraInventory).
```
This is due to the oracle user not being a primary member of the oinstall group. The 11g preinstallation binary does not set group memberships properly. Preinstall RPM for 12cR2 and later include the correct group memberships to avoid the error. This is visible in `/etc/group` where `oracle` is included on the `oinstall` line:
#### Correct (12cR2 and later preinstall RPM):
```
oinstall:x:54321:oracle
dba:x:54322:oracle
```
#### Incorrect (11g, 12cR1 preinstall RPM):
```
oinstall:x:54321:
dba:x:54322:oracle
```
This image uses the 19c RPM.

There are additional packages needed that the 11g preinstallation binary handles. For the 19c RPM to set groups correctly, run it before the 11g RPM in the Dockerfile or Linux OS configuration.

An alternative is to use dba group, changing the value for `UNIX_GROUP_NAME` in db_inst.rsp from `oinstall` to `dba`:
```
UNIX_GROUP_NAME=dba
```
