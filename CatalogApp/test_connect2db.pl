#!/usr/bin/perl

use strict;
use warnings;

use Catalog::Main;

	my $schema = Catalog::Main->connect('dbi:SQLite:db/catalog.db');
	
	if (defined($schema)) { 
		print "connected to catalog database \n"; 
	}
