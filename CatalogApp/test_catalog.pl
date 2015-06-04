 #!/usr/bin/perl
# WORKS IF UNIQ

use strict;
use warnings;

use Image::ExifTool;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use File::Compare;
use File::Basename;
use File::Path;
use File::Spec;
use File::Copy;
use File::Find;

use Catalog::Main;
use Data::Dumper;

##########################################################################################
# VARS
##########################################################################################

my $input = "/Users/LochNessIT/Documents/DOCUMENTS";

my %SIGNATURES;

my %DB_MD5S;
my %DB_TYPES;
my %DB_LOCS;
my %REC_FILES;
my %DB_REFUSED;


my $schema = Catalog::Main->connect('dbi:SQLite:dbname=db/catalog.db');

if (defined($schema)) { 
	print "connected to ",$schema,"\n"; 
}
else {
	die;
}	

print "start searching  ...\n";

# read_db
	my $files_rs = $schema->resultset('file');
	while( my $file = $files_rs->next ) {
  		if ( $DB_TYPES{$file->file_type} ) {
  		 	$DB_TYPES{$file->file_type}++;
  		} else {
  			;
  	}
  	my $locs_rs = $schema->resultset('location'); 
  	while( my $loc = $locs_rs->next ) {
  		$DB_LOCS{$loc->loc_name}++;
	}
	# for debug / test
#	print Dumper(%DB_MD5S);
#	print Dumper(%DB_LOCS);  
	
	
get_file_by_type("");
# get_md5_by_type("image/jpeg");
# read_db;



##########################################################################################
# SUBS
##########################################################################################

sub get_file_by_type {
	my $type = shift;
    my $rs = $schema->resultset('file')->search({'file_type' => $type});
    my $nb_found = $rs->count;
    while (my $file = $rs->next) {
    	my $rs_loc = $schema->resultset('location')->search({'file_md5' => $file->file_md5});
        while (my $loc = $rs_loc->next) {
        	print  "\t File named : ", $loc->loc_full,"\n";
    	}    	
    }
    print $nb_found," files with $type.\n";
}

sub get_md5_by_undef_type {
    my $rs = $schema->resultset('file')->search({'file_type' => ""});
    my $nb_undef = $rs->count;
    while (my $file = $rs->next) {
        print $file->file_md5 . "\n";
    }
    print $nb_undef," files has undef type.\n";
}

sub get_md5_by_type {
	my $type = shift;
    my $rs = $schema->resultset('file')->search({'file_type' => $type});
    while (my $file = $rs->next) {
        print $file->file_md5 . "\n";
    }
}

#print Dumper(%REC_FILES); #OK

#print Dumper(%SIGNATURES); #OK

#print Dumper(%REC_FILES);

# pr_mime_types {
	foreach my $type ( sort keys %DB_TYPES ) {
		printf "\t %-6s files have %-20s \n", $DB_TYPES{$type}, $type;
	}
# }	
