#!/usr/bin/env perl

use lib '~/pythian/perl5/lib';

use warnings;
use strict;
use FileHandle;
use DBI;
use Getopt::Long;
use Data::Dumper;

my %optctl = ();

my($db, $username, $password, $connectionMode, $localSysdba);
my($adjustCols);
$adjustCols=0;
my $sysdba=0;

Getopt::Long::GetOptions(
	\%optctl,
	"database=s" => \$db,
	"username=s" => \$username,
	"password=s" => \$password,
	"sysdba!",
	"local-sysdba!",
	"sysoper!",
	"z","h","help");

$localSysdba=$optctl{'local-sysdba'};

if (! $localSysdba) {

	$connectionMode = 0;
	if ( $optctl{sysoper} ) { $connectionMode = 4 }
	if ( $optctl{sysdba} ) { $connectionMode = 2 }

	usage(1) unless ($db and $username and $password);
}


#print qq{
#
#USERNAME: $username
#DATABASE: $db
#PASSWORD: $password
    #MODE: $connectionMode
 #RPT LVL: @rptLevels
#};
#exit;


$|=1; # flush output immediately

sub getOraVersion($$$);

my $dbh ;

if ($localSysdba) {
	$dbh = DBI->connect(
		'dbi:Oracle:',undef,undef,
		{
			RaiseError => 1,
			AutoCommit => 0,
			ora_session_mode => 2
		}
	);
} else {
	$dbh = DBI->connect(
		'dbi:Oracle:' . $db,
		$username, $password,
		{
			RaiseError => 1,
			AutoCommit => 0,
			ora_session_mode => $connectionMode
		}
	);
}

die "Connect to  $db failed \n" unless $dbh;
$dbh->{RowCacheSize} = 100;

# get the major and minor version of the instance
my ($majorOraVersion, $minorOraVersion);
getOraVersion (
		\$dbh,
		\$majorOraVersion,
		\$minorOraVersion,
);

print "Major/Minor version $majorOraVersion/$minorOraVersion\n";
my $dbVersion="${majorOraVersion}.${minorOraVersion}" * 1; # convert to number

$dbh->disconnect;

sub usage {
	my $exitVal = shift;
	$exitVal = 0 unless defined $exitVal;
	use File::Basename;
	my $basename = basename($0);
	print qq/

usage: $basename

  -database      target instance
  -username      target instance account name
  -password      target instance account password
  -sysdba        logon as sysdba
  -sysoper       logon as sysoper
  -local-sysdba  logon to local instance as sysdba. ORACLE_SID must be set
                 the following options will be ignored:
                   -database
                   -username
                   -password

  example:

  $basename -database dv07 -username scott -password tiger -sysdba  

  $basename -local-sysdba 

/;
   exit $exitVal;
};

sub getOraVersion($$$) {
	my ($dbh,$major,$minor) = @_;

	my $sql=q{select
	substr(version,1,instr(version,'.')-1) major_version
	, substr (
		substr(version,instr(version,'.')+1), -- following the first '.'
		1, -- start at the first character
		instr(substr(version,instr(version,'.')+1),'.')-1 -- everything before the first '.'
	) minor_version
from v$instance};

	my $sth = $$dbh->prepare($sql,{ora_check_sql => 0});
	$sth->execute;
	($$major,$$minor) = $sth->fetchrow_array;

}


