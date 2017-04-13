#!/usr/bin/env perl

use warnings;
use FileHandle;
use DBI qw(:sql_types);
use strict;
use Data::Dumper;

use Getopt::Long;

my %optctl = ();

Getopt::Long::GetOptions(
	\%optctl,
	"sysdba!",
	"sysoper!",
	"z","h","help");

my($db, $connectionMode) = qw(ATLAS1 2);

my $sqlID = 'fghvv2awpvxf2';

my $dbh = DBI->connect(
	'dbi:Oracle:', undef,undef,
	{
		RaiseError => 1,
		AutoCommit => 0,
		ora_session_mode => $connectionMode
	}
	);

die "Connect to  $db failed \n" unless $dbh;

$dbh->{RowCacheSize} = 100;

my $sql=q{with snaps as (
	select 
		min(snap_id) min_snap_id
		, max(snap_id) max_snap_id
	from dba_hist_snapshot
	where begin_interval_time >= to_timestamp('2017-01-01','yyyy-mm-dd')
	and end_interval_time <=  systimestamp
),
awr_bind_data as (
	select
   	hs.begin_interval_time
	, b.instance_number
   	, b.position
   	, b.name
   	--, b.value_string
	, anydata.GETTYPENAME(b.value_anydata) data_type
   	, case anydata.GETTYPENAME(b.value_anydata)
		when 'SYS.VARCHAR' then  anydata.accessvarchar(b.value_anydata)
		when 'SYS.VARCHAR2' then anydata.accessvarchar2(b.value_anydata)
		when 'SYS.CHAR' then anydata.accesschar(b.value_anydata)
		when 'SYS.DATE' then to_char(anydata.accessdate(b.value_anydata),'yyyy-mm-dd hh24:mi:ss')
		when 'SYS.TIMESTAMP' then to_char(anydata.accesstimestamp(b.value_anydata),'yyyy-mm-dd hh24:mi:ss')
		when 'SYS.NUMBER' then to_char(anydata.accessnumber(b.value_anydata))
   	end bind_string
	from DBA_HIST_SQLBIND b
	join dba_hist_snapshot hs on hs.snap_id = b.snap_id
		and hs.instance_number = b.instance_number
		and hs.dbid = b.dbid
		and hs.snap_id between (select min_snap_id from snaps)
			and (select max_snap_id from snaps)
		and b.sql_id = ? 
), 
v_bind_data as (
	select
   	to_timestamp(b.last_captured) begin_interval_time
	, b.inst_id instance_number
   	, b.position
   	, b.name
   	--, b.value_string
	, anydata.GETTYPENAME(b.value_anydata) data_type
   	, case anydata.GETTYPENAME(b.value_anydata)
		when 'SYS.VARCHAR' then  anydata.accessvarchar(b.value_anydata)
		when 'SYS.VARCHAR2' then anydata.accessvarchar2(b.value_anydata)
		when 'SYS.CHAR' then anydata.accesschar(b.value_anydata)
		when 'SYS.DATE' then to_char(anydata.accessdate(b.value_anydata),'yyyy-mm-dd hh24:mi:ss')
		when 'SYS.TIMESTAMP' then to_char(anydata.accesstimestamp(b.value_anydata),'yyyy-mm-dd hh24:mi:ss')
		when 'SYS.NUMBER' then to_char(anydata.accessnumber(b.value_anydata))
   	end bind_string
	from gv$sql_bind_capture b
	where b.sql_id = ?
),
all_binds as (
	select
		begin_interval_time
		, instance_number
		, position
		, name
		--, data_type
		, substr(data_type,instr(data_type,'.')+1) || '' data_type
		, bind_string
	from awr_bind_data
	union
	select
		begin_interval_time
		, instance_number
		, position
		, name
		--, data_type
		, substr(data_type,instr(data_type,'.')+1) || '' data_type
		, bind_string
	from v_bind_data
)
select 
	begin_interval_time
	, instance_number
	, max(data_type) data_type
	, position
	, max(name) name
	, max(bind_string) bind_string
from all_binds
group by begin_interval_time, instance_number, position
order by begin_interval_time,  instance_number, position};

my $sth = $dbh->prepare($sql,{ora_check_sql => 0});

my $bindVals = ();

$sth->execute($sqlID,$sqlID);

while( my $ary = $sth->fetchrow_arrayref ) {
	#print "\t\t$ary->[0]\n";
	# time, instance, position
	push @{$bindVals->{$ary->[0]}{$ary->[1]}{$ary->[3]}}, ($ary->[2], $ary->[4], $ary->[5]);
}

my $testSql = q{SELECT NIGHTLY_AMT AMOUNT, 'N' ONE_TIME FROM P_RATE RATE, P_RATE_PER_NIGHT NIGHT WHERE RATE.RATE_CODE = :B3 AND RATE.PM_UNIT_TYPE_ID = :B2 AND RATE.RATE_CODE = NIGHT.RATE_CODE AND RATE.RATE_NUM = NIGHT.RATE_NUM AND RATE.ONE_TIME_RATE_FLAG = 'N' AND RATE.RATE_ACTIVE = 'Y' AND :B1 BETWEEN RATE_EFF_DATE AND RATE_END_DATE AND DAY_CODE = TO_CHAR(:B1 ,'DY') AND NUMBER_OF_OCCUPANTS = ( SELECT MAX(NUMBER_OF_OCCUPANTS) FROM P_RATE_PER_NIGHT WHERE RATE_CODE = RATE.RATE_CODE AND RATE_NUM = RATE.RATE_NUM ) UNION ALL SELECT ONE_TIME_AMT, 'Y' ONE_TIME FROM P_RATE WHERE RATE_CODE = :B3 AND PM_UNIT_TYPE_ID = :B2 AND ONE_TIME_RATE_FLAG = 'Y' AND :B1 BETWEEN RATE_EFF_DATE AND RATE_END_DATE};


$dbh->do('alter session set current_schema = PREMIER');

#print Dumper($bindVals);

$sth = $dbh->prepare($testSql,{ora_check_sql => 0});

# loop through bind var sets , execute the SQL and retrieve 1 row
# then get the plan and kill the cursor 

my $planSql = q{select * from table(dbms_xplan.display_cursor( null,null,'ALL ALLSTATS LAST'))};

foreach my $timestamp ( sort keys %{$bindVals}) {
	print '#' x 120, "\n";
	print "### timestamp: $timestamp\n";
	print '#' x 120, "\n";

	my $instHash = $bindVals->{$timestamp};

	foreach my $instance ( sort keys %{$instHash}) {
		print "\tinstance: $instance\n";
		
		my $bindHash = $instHash->{$instance};
		#print Dumper($bindHash);

		foreach my $position ( sort keys %{$bindHash} ) {
			print qq{\tpos: $position
\t\tdatatype: $bindHash->{$position}[0]
\t\tname: $bindHash->{$position}[1]
\t\tvalue: $bindHash->{$position}[2]

};
		}

		# we could do this dynamically - save it for later
		# for now we know the types for this specific query
		$sth->bind_param(':B1',$bindHash->{2}[1]);
		$sth->bind_param(':B2',$bindHash->{1}[1], { TYPE => SQL_INTEGER });
		$sth->bind_param(':B3',$bindHash->{0}[1]);
		$sth->execute();

		#$sth->execute(
			#$bindHash->{0}[2],
			#$bindHash->{1}[2],
			#$bindHash->{2}[2],
			#$bindHash->{3}[2],
			#$bindHash->{4}[2],
			#$bindHash->{5}[2],
			#$bindHash->{6}[2],
		#);
		
		# no need to fetch any rows
		#my $dummy = $sth->fetchrow_arrayref;

		my $planSth = $dbh->prepare($planSql,{ora_check_sql => 0});
		$planSth->execute;
		while( my $ary = $planSth->fetchrow_arrayref ) {
			print "$ary->[0]\n";
		}
		$sth->finish;
	}
}

$dbh->disconnect;



