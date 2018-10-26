
alter session set tracefile_identifier = 'GEN-BINDS';

col value format a100
select value from v$diag_info where name = 'Default Trace File';

alter session set events '10046 trace name context forever, level 12';



declare

	cursor c1 ( owner_in varchar2, object_type_in varchar2)
	is
	select object_name
	from dba_objects
	where owner = owner_in
		and object_type = object_type_in;

begin

	for crec in c1('JKSTILL','TABLE')
	loop	
		null;
	end loop;

	for crec in c1('LOGGER','TABLE')
	loop	
		null;
	end loop;

end;
/

alter session set events '10046 trace name context off';


