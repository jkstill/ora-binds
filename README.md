Perl scripts for working with Oracle bind variable values

# gen-bind-sets.pl

Parse BIND values from 10046 trace files

# gen-plans-from-binds.pl

For a SQL_ID, gather bind values from AWR and then generate execution plans.
Currently has a lot of hardcoding - needs to be genericized.

# Logging in as sysdba

See the script DBI_sysdba_login.pl for examples of logging in without username and password.

## Example

 $ $ORACLE_HOME/perl/bin/perl DBI_sysdba_login.pl --local-sysdba
 Major/Minor version 12/2


