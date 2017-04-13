#!/usr/bin/env perl
#
# gen-bind-sets.pl
# Jared Still still@pythian.com jkstill@gmail.com

my $bindSet=1;

my @data=(<>);
chomp @data;

my @bindNames=();
my %bindValues=();

foreach my $line ( @data ) {

	if ( $line =~ /newbind/ ) {

		my $outFile = "bindset-${bindSet}.sql";

		open BIND,'>', $outFile || die "failed to create $outFile- $!\n";
		foreach my $b (@bindNames) {
			print BIND "var $b ";
			if ( $bindValues{$b} =~ /'/ ) {
				print BIND "varchar2(30)\n";
			} else {
				print BIND "number\n";
			}
		}

		print BIND "\nbegin\n";

		foreach my $b (@bindNames) {
			print BIND "\t:$b := $bindValues{$b};\n";
		}
		
		print BIND "end;\n";
		print BIND "/\n";

		#$i=-1;
		@bindNames=();
		%bindValues=();
		$bindSet++;
		next;
	}
	my ($braw, @vraw) = split(/\s+/,$line);

	#print "SPLIT: ", (split(/#/,$braw))[1], "\n";

	my $bindVar = sprintf("B%02d",(split(/#/,$braw))[1]);
	my ($dummy,$value) =  split(/\=/,join(' ',@vraw));
	# replace leading and trailing double quote with single quote
	$value =~ s/^(")(.*)(")$/'$2'/o;

	print "$bindVar $value\n";

	push @bindNames,$bindVar;
	$bindValues{$bindVar} = $value;

}


