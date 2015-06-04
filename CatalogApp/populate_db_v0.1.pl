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
# CONST
##########################################################################################


##########################################################################################
# VARS
##########################################################################################

my $input = "/Users/LochNessIT/Pictures/DROBO";

my %SIGNATURES;

my %REC_FILES;





#$dbh = DBI->connect($data_source, $username, $password);

##########################################################################################
# SUBS
##########################################################################################

sub compute_md5_file {
    my $filename = shift;
    open (my $fh, '<', $filename) or die "Can't open '$filename': $!";
    binmode ($fh);
    return Digest::MD5->new->addfile($fh)->hexdigest;
}

sub ls_files {
	my $md5;
	print $File::Find::name,"\n";
	if ( !($_ =~ /^\./) ) {
		if ( -l $_ ) {
		}
		elsif ( -d $_ ) { 
#			$dirs_read++;
#			$REC_REPORT{$report_id}{nb_dirs_read}++;
			
    	}	
    	else {  
 #   		$files_read++;
 #   		$REC_REPORT{$report_id}{nb_files_read}++;
 			my ($volume,$directories,$file) = File::Spec->splitpath($File::Find::name);
    		my ($filename,$dir,$ext) = fileparse($File::Find::name, qr/\.[^.]*/);
			my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($File::Find::name);
	   		   		
	   		my $md5 = compute_md5_file($File::Find::name);
	   		# MD5 already exists
	   		if ( $SIGNATURES{$md5} ) {
	   			
	   			# Update (Add new tags ?, set last mtime 
#	   			$REC_REPORT{$report_id}{nb_lost_space} += $REC_FILE{$md5}{space};
#	   			$REC_REPORT{$report_id}{nb_total_space} += $REC_FILE{$md5}{space};
#	   			$REC_FILE{$md5}{nb_occ}++;
#	   			$REC_REPORT{$report_id}{nb_total_occ}++; 
	   			push @{ $REC_FILES{$md5}{locations} }, { ('full',$File::Find::name,'name',$filename,'vol',$volume,'dir',$dir,'ext',$ext) } ;
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

	 			$rec_file->{locations} = [ { ('full',$File::Find::name,'name',$filename, 'vol',$volume,'dir',$dir,'ext',$ext) } ];
	 			
#	 			print "FILENAME: ",$rec_file->{locations}[0]->{file},"\n";
#				print "PATH: ",$rec_file->{locations}[0]->{dir},"\n";
#	 			print "EXT: ",$rec_file->{locations}[0]->{ext},"\n";
	 			
#	 			$REC_REPORT{$report_id}{nb_total_space}+= $rec_file->{space};	
#	 					
    			$REC_FILES{ $rec_file->{id} } = $rec_file;
			}		
		}		
	}
}





# MAIN 
# NEED INPUT (VOL, DIR, ...)

print "start populate program  ...\n";

finddepth(\&ls_files, $input);

my $schema = Catalog::Main->connect('dbi:SQLite:dbname=db/catalog.db');

#print Dumper(%REC_FILES); #OK

#print Dumper(%SIGNATURES); #OK

my @file_recs;
my @loc_recs;

if (defined($schema)) { 
	print "connected to ",$schema,"\n"; 

	foreach my $md5 (keys %SIGNATURES) {

		push @file_recs, [$REC_FILES{$md5}->{id}, $REC_FILES{$md5}->{space}, $REC_FILES{$md5}->{mime_type}, $REC_FILES{$md5}->{nb_occ}, $REC_FILES{$md5}->{mtime}];
		
		for my $loc ( 0 .. $#{ $REC_FILES{$md5}{locations} } ) {
			push @loc_recs, [$REC_FILES{$md5}->{locations}[$loc]->{full},$REC_FILES{$md5}->{id},$REC_FILES{$md5}->{locations}[$loc]->{name},$REC_FILES{$md5}->{locations}[$loc]->{vol},$REC_FILES{$md5}->{locations}[$loc]->{dir},$REC_FILES{$md5}->{locations}[$loc]->{ext}];	
		}
	}
#	print Dumper(@file_recs);
	my $results_file = $schema->populate('file', [ [qw/file_md5 file_size file_type file_nbocc file_time/], @file_recs ]);  

	print "Results : %s rec inserted in 'file'\n",$results_file;

#	foreach my $loc (keys ) {
#		my $md5 = $schema->resultset('file')->find({
			


# my @tracks;
#         foreach my $track (keys %tracks) {
#           my $cdname = $schema->resultset('Cd')->find({
#             title => $tracks{$track},
#           });
#           push @tracks, [$cdname->id, $track];
#         }
#
#         $schema->populate('Track',[
#           [qw/cd title/],
#           @tracks,
#         ]);



#	print Dumper(@loc_recs);	
	my $results_loc = $schema->populate('location', [ [qw/ file_md5  loc_full loc_name loc_vol loc_path loc_ext/], @loc_recs ]); 	
	
	print "Results : %s rec inserted in 'location'\n",$results_loc;	

} 
else {
	die;
}


#print Dumper(%REC_FILES);
