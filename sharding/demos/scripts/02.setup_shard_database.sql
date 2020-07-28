   alter database force logging;
   alter database archivelog;
   alter database flashback on;

   alter user gsmrootuser identified by oracle account unlock;
   grant sysdg, sysbackup to gsmrootuser;

   alter user gsmuser account unlock;
   alter user gsmuser identified by oracle;
   grant sysdg, sysbackup to gsmuser;

  create or replace directory DATA_PUMP_DIR as '$ORACLE_BASE/oradata';

   alter session set container=$ORACLE_PDB;

   grant read, write on directory data_pump_dir to gsmadmin_internal;
   alter user gsmuser account unlock;

/* Grant to GSMUSER in the PDB */
   grant sysdg, sysbackup to gsmuser;
