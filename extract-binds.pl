#!/usr/bin/env perl


use strict;
use warnings;
use Data::Dumper;

my $newBinds=0; # set when BINDS found
my $nextBind=0; # set when Bind#nn found
my $readBinds=0;
my $valPrinted=0;

while(<>) {

	if ( $readBinds ) {
		#$newBinds=0;

		if ( $nextBind ) {
			if ( /^\s*value=/ ) {
				print;
				$valPrinted=1;
				$nextBind=0;
			} else {
				#($nextBind) =~ /^\s*Bind#/;
				if (/^\s*Bind#/) {
					print "\n" unless $valPrinted;
					$valPrinted=0;
					$nextBind = 1;
					#print "NextBind 2: $nextBind\n";
					#print "line: "; print;
					$_ =~ s/^\s+//g;
					chomp; print; next;
				}
			}
		} else {
			if (/^\s*Bind#/) {
				print "\n" unless $valPrinted;
				$valPrinted=0;
				$nextBind = 1;
				#print "NextBind 1: $nextBind\n";
				#print "line: "; print;
				$_ =~ s/^\s+//g;
				chomp; print; next;
			}
		}

		if ( /^BINDS/ ) {
			$readBinds = 1;
			print "newbind\n";
			next;
		}
		
	} else {
		if ( /^BINDS/ ) {
			$readBinds = 1;
			#print "BIND \n";
			#print "line: "; print;
			next;
		}
	}

}
print "newbind\n";


