#!/usr/bin/perl -w

# REM : 
# complete file compare
# idea of real usefull file content only image size compare to image size + metadata for ie) and OS overhead (keywords, metadata

# WITH sparebundle files content take into account
# Check timemachine status active sparebundle or not
# Check process delete files in sparebundle and size reduce
# Build Volumes list

# ENTRY (ARGV) 1 
# ENTRY TYPE : VOL, DIR, FILENAME (dmg, iso, sparebundle, ...)
# ENTRY NAME : OS FULL_FILENAME

# DEPENDENCIES 
#	"file" unix command

use Image::ExifTool;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use File::Compare;
use File::Basename;
use File::Path;
use File::Spec;
use File::Copy;
use File::Find;

use strict;

# REC_FILES struct
#	{md5} 				: signature and id 
#   {mime_type}			: FROM EXIF MimeType
#	{location}			: ARRAY OF	
#		[
#			{filename} 
#			{dir}
#			{extension} 		: FROM fileparse

#		]
#	{nb_occ}			: 
#	{size} 				: FROM EXIF FileSize
# 
#	{tags} 				: FROM EXIF Keywords NOT USED




# REC_REPORT struct
#	{report_id} 	: FROM localtime
#	{proc} 			: FROM $#dir;
#	{arg}			: ARGUMENT (SALAR or ARRAY )
#	{nb_dirs_read}	: NB
#	{nb_files_read}	: NB
#	{nb_total_occ}	: NB
#	{nb_lost_space} : Size

my $entry = "/Volumes/BACKUP/SAUVEGARDES/IMAGES/MINOLTA/SCANS";

my %REC_FILE;

my %REC_REPORT;

my %SIGNATURES;

my $report_id;

my $dirs_read;
my $files_read;
my $nb_total_occ = 0;
my $nb_total_space = 0;
my $nb_lost_space = 0;


sub compute_md5_file {
    my $filename = shift;
    open (my $fh, '<', $filename) or die "Can't open '$filename': $!";
    binmode ($fh);
    return Digest::MD5->new->addfile($fh)->hexdigest;
}

sub compute_report_id {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
			$mon 	+= 1;
			$year 	+= 1900;
			$mday 	= substr("0".$mday,length("0".$mday)-2, 2);
			$mon 	= substr("0".$mon,length("0".$mon)-2, 2);
			$hour 	= substr("0".$hour,length("0".$hour)-2, 2);
			$min 	= substr("0".$min,length("0".$min)-2, 2);
	
			$report_id = join("_", $year, $mon, $mday, join("-", $hour,$min));
}


# report_id : date only
sub init_proc_report {

	
#	my $proc		= $_[1];
#	my $dir			= $_[2];

	my $rec_report = {};
	
	$rec_report->{id} 					= $report_id;
#	$rec_report->{proc}					= $proc;
#	$rec_report->{args}					= $dir;
	$rec_report->{nb_dirs_read} 		= 0;
	$rec_report->{nb_files_read}		= 0;
	$rec_report->{nb_total_occ}			= 0;
	$rec_report->{nb_total_space}		= 0;
	$rec_report->{nb_lost_space}		= 0;	
	$REC_REPORT{ $rec_report->{id} } 	= $rec_report;
	
}		
		
sub ls_files {
	my $md5;
	print $File::Find::name,"\n";
	if ( !($_ =~ /^\./) ) {
		if ( -l $_ ) {
		}
		elsif ( -d $_ ) { 
			$dirs_read++;
			$REC_REPORT{$report_id}{nb_dirs_read}++;
			
    	}	
    	else {  
    		$files_read++;
    		$REC_REPORT{$report_id}{nb_files_read}++;
    		my ($filename,$dir,$ext) = fileparse($File::Find::name, qr/\.[^.]*/);
			my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($File::Find::name);
	   		   		
	   		my $md5 = compute_md5_file($File::Find::name);
	   		# MD5 already exists
	   		if ( $SIGNATURES{$md5} ) {
	   			
	   			# Update (Add new tags ?, set last mtime 
	   			$REC_REPORT{$report_id}{nb_lost_space} += $REC_FILE{$md5}{space};
	   			$REC_REPORT{$report_id}{nb_total_space} += $REC_FILE{$md5}{space};
	   			$REC_FILE{$md5}{nb_occ}++;
	   			$REC_REPORT{$report_id}{nb_total_occ}++; 
	   			push @{ $REC_FILE{$md5}{locations} }, { ('file',$filename, 'dir',$dir,'ext',$ext) } ;
	   		}	
	   		else {
	   		# new md5
	   			
	   			$SIGNATURES{$md5}++;
	   			my $rec_file = {};
	   			my $exifTool_object 			= new Image::ExifTool;
    			my $info 						= $exifTool_object->ImageInfo($File::Find::name);
	   				
	   			$rec_file->{id}					= $md5; 
#	   			print "ID: ",$rec_file->{id},"\n";
	   			$rec_file->{nb_occ}				= 1;
	   			
#	   			print "NB_OCC: ",$rec_file->{nb_occ}	,"\n";
	   			$rec_file->{space}				= $exifTool_object->GetValue('FileSize', 'ValueConv');	
#	   			print "SIZE: ",$rec_file->{space}	,"\n";
	   				
				
				$rec_file->{mime_type}			= $exifTool_object->GetValue('MIMEType', 'ValueConv');		
#				print "MIME_TYPE: ",$rec_file->{mime_type}		,"\n";
				$rec_file->{mtime} 				= $mtime;
#				print "TIME: ",$rec_file->{mtime}	,"\n";

	 			$rec_file->{locations} = [ { ('file',$filename, 'dir',$dir,'ext',$ext) } ];
	 			
#	 			print "FILENAME: ",$rec_file->{locations}[0]->{file},"\n";
#				print "PATH: ",$rec_file->{locations}[0]->{dir},"\n";
#	 			print "EXT: ",$rec_file->{locations}[0]->{ext},"\n";
	 			
	 			$REC_REPORT{$report_id}{nb_total_space}+= $rec_file->{space};	
	 					
    			$REC_FILE{ $rec_file->{id} } = $rec_file;
			}		
		}		
	}
}

sub print_SIGNATURES {

		foreach my $id (keys %SIGNATURES) {
			print "\t KEYS : ",$SIGNATURES{$id},"\n";
		}
}		

sub print_SIMPLE_REPORT {
	print "[ REPORT FOR : ",$report_id," ] \n";

	print 	"\t NB DIRS: \t", $REC_REPORT{$report_id}{nb_dirs_read},"\n",
			"\t NB FILES: \t", $REC_REPORT{$report_id}{nb_files_read},"\n",
			"\t NB DOUBLONS: \t", $REC_REPORT{$report_id}{nb_total_occ},"\n",
			"\t TOTAL SIZE:\t", $REC_REPORT{$report_id}{nb_total_space},"\n",
			"\t SAVED SPACE:\t", $REC_REPORT{$report_id}{nb_lost_space},"]\n";	
			
}

sub print_REC_FILES {
	foreach my $id (keys %SIGNATURES) {
		print "[ FILE MD5 : ",$id," ] \n",
				"\t ", $REC_FILE{$id}{nb_occ},"\n", 
				"\t ", $REC_FILE{$id}{space},"\n",	
				"\t ", $REC_FILE{$id}{mime_type},"\n",
				"\t ", $REC_FILE{$id}{mtime},"\n";

		for my $loc ( 0 .. $#{ $REC_FILE{$id}{locations} } ) {
#			print "LOC : ",$loc,"\n";
			print "\t [ ","FILE : ",$REC_FILE{$id}{locations}[$loc]->{file},"\t","PATH : ",$REC_FILE{$id}{locations}[$loc]->{dir},"\t","EXT : ",$REC_FILE{$id}{locations}[$loc]->{ext}," ] \n";
		}	
	}		
}

sub print_DOUBLONS {
	foreach my $id (keys %SIGNATURES) {
		if ( $#{ $REC_FILE{$id}{locations} } > 0) {
			print "[ FILE MD5 : ",$id," ] \n",
				"\t ", $REC_FILE{$id}{nb_occ},"\n", 
				"\t ", $REC_FILE{$id}{space},"\n",	
				"\t ", $REC_FILE{$id}{mime_type},"\n",
				"\t ", $REC_FILE{$id}{mtime},"\n";

			for my $loc ( 0 .. $#{ $REC_FILE{$id}{locations} } ) {
#				print "LOC : ",$loc,"\n";
				print "\t [ ","FILE : ",$REC_FILE{$id}{locations}[$loc]->{file},"\t","PATH : ",$REC_FILE{$id}{locations}[$loc]->{dir},"\t","EXT : ",$REC_FILE{$id}{locations}[$loc]->{ext}," ] \n";
			}
		}	
	}		
}

# MAIN

#my $entry = $ARGV[1];
print "RUNNING ON : $entry,\n";
compute_report_id;
init_proc_report;
finddepth(\&ls_files, $entry);
print_DOUBLONS;	
# print_REC_FILES;
print_SIMPLE_REPORT;

