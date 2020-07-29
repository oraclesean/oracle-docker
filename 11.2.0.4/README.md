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

