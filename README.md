# Perl scripts for working with Oracle bind variable values


# Extract from Trace Files

The scripts _extract-binds.pl_ and _gen-bind-sets.pl_ are used to extract bind values from a trace file, and then generate a PL/SQL block that creates the bind values.

Then a suitable SQL script can be used to run with these bind values.

It would be best of the trace has binds only for a single SQL statement.

There is no attempt made to differentiate between SQL statements.

Following is a demo using the script _get-trace.sql_


```sql
SQL> @@gen-trace.sql

JKSTILL@p1 > @gen-trace


VALUE
--------------------------------------------------------------------------------
/u01/app/oracledb/diag/rdbms/js122a/js122a1/trace/js122a1_ora_9039_GEN-BINDS.trc


PL/SQL procedure successfully completed.

```

Retrieve the trace file

```bash
scp oracle@ora122rac01:/u01/app/oracledb/diag/rdbms/js122a/js122a1/trace/js122a1_ora_9039_GEN-BINDS.trc .
```

Generate the bind variable text file:

```bash

$  ./extract-binds.pl js122a1_ora_9039_GEN-BINDS.trc > binds-from-trace.txt

$  ./gen-bind-sets.pl binds-from-trace.txt
B00
B00 'JKSTILL'
B01 'TABLE'
B00 'LOGGER'
B01 'TABLE'

```

This step will have generated SQL files used to execute a SQL script.

```bash
$ cat bindset-1.sql

var B00 varchar2(30)
var B00 varchar2(30)
var B01 varchar2(30)

begin
        :B00 := 'JKSTILL';
        :B01 := 'TABLE';
end;
/

$ cat bindset-2.sql

var B00 varchar2(30)
var B01 varchar2(30)

begin
        :B00 := 'LOGGER';
        :B01 := 'TABLE';
end;
/

```

Now the script _use-binds.sql_ will execute these scripts before running the SQL statment

```sql
 @use-binds

bindset-1.sql

JKSTILL@p1 > select object_name
  2  from dba_objects
  3  where owner = :B00
  4          and object_type = :B01
  5  /

OBJECT_NAME
--------------------------------------------------------------------------------
BIGTABLE
PROC_LIST
STACK_TEST
TEST
FAKE_WORK

5 rows selected.

JKSTILL@p1 > set echo off

bindset-2.sql

JKSTILL@p1 > select object_name
  2  from dba_objects
  3  where owner = :B00
  4          and object_type = :B01
  5  /

OBJECT_NAME
--------------------------------------------------------------------------------
LOGGER_LOGS
LOGGER_PREFS
LOGGER_LOGS_APEX_ITEMS
LOGGER_PREFS_BY_CLIENT_ID

4 rows selected.
```

# Extract from AWR

The script _gen-plans-from-binds.pl_ is currently under development and it contains some hard coded assumptions.

Feel free to issue a pull request. :)

# Scripts

## extract-binds.pl

This script will extract bind values form 

## gen-bind-sets.pl

Parse BIND values from 10046 trace files

## gen-plans-from-binds.pl

For a SQL_ID, gather bind values from AWR and then generate execution plans.
Currently has a lot of hardcoding - needs to be genericized.

## Logging in as sysdba

See the script DBI_sysdba_login.pl for examples of logging in without username and password.

### Example

 $ $ORACLE_HOME/perl/bin/perl DBI_sysdba_login.pl --local-sysdba
 Major/Minor version 12/2


