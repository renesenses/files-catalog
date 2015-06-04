#!/usr/bin/perl

use strict;
use warnings;
use Diapos::Main;
use Data::Dumper;

my $schema = Diapos::Main->connect('dbi:SQLite:db/diapos.db');
	



sub count_negatifs {
	my $negatifs_rs= $schema->resultset('posneg');
	if ($negatifs_rs != 0 ) {
		print $negatifs_rs->count,"\n";
	}
	else {
		print "Empty resultset \n";
	}
}

count_negatifs;

#print Dumper($negatifs_rs);

