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

finddepth(\&ls_files, $input);

# read_db
	my $files_rs = $schema->resultset('file');
	while( my $file = $files_rs->next ) {
  		$DB_MD5S{$file->file_md5}++;
  		if ( !($DB_TYPES{$file->file_type}) ) { $DB_TYPES{$file->file_type}++;
  		};
  	}
  	my $locs_rs = $schema->resultset('location'); 
  	while( my $loc = $locs_rs->next ) {
  		$DB_LOCS{$loc->loc_name}++;
	}
	# for debug / test
	print Dumper(%DB_MD5S);
	print Dumper(%DB_LOCS);  

# populate_db
	my @loc_recs;
	my @file_recs;
	foreach my $md5 (keys %SIGNATURES) {
		if ($DB_MD5S{$md5}) {
			foreach my $loc (0 .. $#{ $REC_FILES{$md5}{locations} }-1) {
				if ( $DB_LOCS{$REC_FILES{$md5}->{locations}[$loc]->{full}} ) {
					$DB_REFUSED{$md5}++;
				# Already in db
				}
				else {
			# known md5 but not location so Add to loc
					push @loc_recs, [$REC_FILES{$md5}->{locations}[$loc]->{full},$REC_FILES{$md5}->{id},$REC_FILES{$md5}->{locations}[$loc]->{name},$REC_FILES{$md5}->{locations}[$loc]->{vol},$REC_FILES{$md5}->{locations}[$loc]->{dir},$REC_FILES{$md5}->{locations}[$loc]->{ext}];
					$DB_LOCS{$REC_FILES{$md5}->{locations}[$loc]->{full}}++;
				}
			}
		}			
		else {	
			# new file and new md5	
			push @file_recs, [$REC_FILES{$md5}->{id}, $REC_FILES{$md5}->{space}, $REC_FILES{$md5}->{mime_type}, $REC_FILES{$md5}->{nb_occ}, $REC_FILES{$md5}->{mtime}];
			$DB_MD5S{$REC_FILES{$md5}->{id}}++;	
			for my $loc ( 0 .. $#{ $REC_FILES{$md5}{locations} } ) {
				push @loc_recs, [$REC_FILES{$md5}->{locations}[$loc]->{full},$REC_FILES{$md5}->{id},$REC_FILES{$md5}->{locations}[$loc]->{name},$REC_FILES{$md5}->{locations}[$loc]->{vol},$REC_FILES{$md5}->{locations}[$loc]->{dir},$REC_FILES{$md5}->{locations}[$loc]->{ext}];	
				$DB_LOCS{$REC_FILES{$md5}->{locations}[$loc]->{full}}++;
			}		
		}
	}
	if ($#file_recs != 0 ) {
		my $results_file = $schema->populate('file', [ [qw/file_md5 file_size file_type file_nbocc file_time/], @file_recs ]);
	}
	if ($#loc_recs != 0 ) {  
		my $results_loc = $schema->populate('location', [ [qw/ loc_full file_md5 loc_name loc_vol loc_path loc_ext/], @loc_recs ]); 	
	}
	print Dumper(%DB_REFUSED);	
	
	
get_md5_by_type("");
# get_md5_by_type("image/jpeg");
# read_db;


##########################################################################################
# SUBS
##########################################################################################

sub get_md5_by_undef_type {
    my $rs = $schema->resultset('file')->search('file_type' => "");
    my $nb_undef = $rs->count;
    while (my $file = $rs->next) {
        print $file->file_md5 . "\n";
    }
    print $nb_undef," files has undef type.\n";
}

sub get_md5_by_type {
	my $type = shift;
    my $rs = $schema->resultset('file')->search('file_type' => $type);
    while (my $file = $rs->next) {
        print $file->file_md5 . "\n";
    }
}


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

    	}	
    	else {  

 			my ($volume,$directories,$file) = File::Spec->splitpath($File::Find::name);
    		my ($filename,$dir,$ext) = fileparse($File::Find::name, qr/\.[^.]*/);
			my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($File::Find::name);
	   		   		
	   		my $md5 = compute_md5_file($File::Find::name);
	   		# MD5 already exists
	   		if ( $SIGNATURES{$md5} ) {
	   			push @{ $REC_FILES{$md5}{locations} }, { ('full',$File::Find::name,'name',$filename,'vol',$volume,'dir',$dir,'ext',$ext) } ;
	   		}	
	   		else {
	   		# new md5
	   			
	   			$SIGNATURES{$md5}++;
	   			my $rec_file = {};
	   			my $exifTool_object 			= new Image::ExifTool;
    			my $info 						= $exifTool_object->ImageInfo($File::Find::name);
	   				
	   			$rec_file->{id}					= $md5; 
	   			$rec_file->{nb_occ}				= 1;
	   			$rec_file->{space}				= $exifTool_object->GetValue('FileSize', 'ValueConv');	
				$rec_file->{mime_type}			= $exifTool_object->GetValue('MIMEType', 'ValueConv');		
				$rec_file->{mtime} 				= $mtime;
	 			$rec_file->{locations} = [ { ('full',$File::Find::name,'name',$filename, 'vol',$volume,'dir',$dir,'ext',$ext) } ];
				$REC_FILES{ $rec_file->{id} } = $rec_file;
			}		
		}		
	}
}

#print Dumper(%REC_FILES); #OK

#print Dumper(%SIGNATURES); #OK

#print Dumper(%REC_FILES);
