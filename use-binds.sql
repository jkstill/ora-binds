
prompt 
prompt bindset-1.sql
prompt

set feed off
@@bindset-1.sql
set feed on

set echo on
select object_name
from dba_objects
where owner = :B00
	and object_type = :B01
/
set echo off

prompt 
prompt bindset-2.sql
prompt

set feed off
@@bindset-2.sql
set feed on

set echo on
select object_name
from dba_objects
where owner = :B00
	and object_type = :B01
/
set echo off


