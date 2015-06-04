#!/usr/bin/perl

use strict;
use warnings;
use Diapos::Main;
use Data::Dumper;

 use DBIx::Class::ResultClass::HashRefInflator;

my $schema = Diapos::Main->connect('dbi:SQLite:db/diapos.db');
	
my %EVENTS;
my %YEARS;
my %NEGATIFS;

sub build_events {
	my $negatifs_rs= $schema->resultset('posneg');
	while (my $neg = $negatifs_rs->next) {
#        print $neg->posneg_event,"\n";
        if ($EVENTS{$neg->posneg_event} ) {
            
        }
        else {
        	$EVENTS{$neg->posneg_event}++
        }
    }
    print "ALL_EVENTS : ",Dumper(%EVENTS),"\n";
}

sub build_years {
	my $negatifs_rs= $schema->resultset('posneg');
	while (my $neg = $negatifs_rs->next) {
#        print $neg->posneg_year,"\n";
        if ($YEARS{$neg->posneg_year} ) {
            
        }
        else {
        	$YEARS{$neg->posneg_year}++
        }
    }
    print "ALL_EVENTS : ",Dumper(%YEARS),"\n";
}

sub count_negatifs {
	my $negatifs_rs= $schema->resultset('posneg');
	return $negatifs_rs->count,;
}


sub build_negatifs {
	my $rs = $schema->resultset('posneg');
 	$rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
 	while (my $hashref = $rs->next) {
 		print Dumper($hashref);
 		#$NEGATIFS{$hashref->posneg_id}++
	}
	#print Dumper(%NEGATIFS);
 }


# print count_negatifs,"\n";
# build_events;
#build_years;
#print Dumper($negatifs_rs);
build_negatifs;

