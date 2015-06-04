 #!/usr/bin/perl

use strict;
use warnings;
use Spreadsheet::Read;use Spreadsheet::Read;
use Diapos::Main;
use Data::Dumper;



##########################################################################################
# CONST
##########################################################################################

my $DELTA_ALPHA = ord("A");


##########################################################################################
# VARS
##########################################################################################

my $DiposDbFullName = "/Users/LochNessIT/GIT_REPO/PHOTOS_PRJ/APP/DiaposApp/Data/Diapos.db";


my $spreadsheet = "/Users/LochNessIT/GIT_REPO/PHOTOS_PRJ/Classification_AC.xls";
my $book;
my %XLS_NEGATIFS;
# my %NEGATIFS;





#$dbh = DBI->connect($data_source, $username, $password);

##########################################################################################
# SUBS
##########################################################################################


sub build_rec {
	my $refbook = shift;
	
	my $rec_negatif;
	my $rec_page;
	my $rec_indice;
 	my $rec_year;
 	my $rec_alpha;
 	my $rec_no;
 	my $rec_id;
 	my $rec_event;
 	
	foreach my $sheet (1 .. $refbook->[0]->{sheets}) {
 		foreach my $row (3 .. $refbook->[$sheet]->{maxrow}) {
 		
 			$rec_page 				= $refbook->[$sheet]->{cell}[1][$row];
 			$rec_indice				= $refbook->[$sheet]->{cell}[2][$row];
 			$rec_year				= $refbook->[$sheet]->{cell}[3][$row];
 			$rec_alpha				= $refbook->[$sheet]->{cell}[4][$row];
 			$rec_event				= $refbook->[$sheet]->{cell}[9][$row];
 			
 			for my $col (5 .. 8) {

				# CASE EMPTY NO CELL
  				if ( length($refbook->[$sheet]->{cell}[$col][$row]) > 0 ) {
  					
  					$rec_no 		= $refbook->[$sheet]->{cell}[$col][$row];
 					$rec_id 		= $rec_year."-".$rec_alpha."-".$rec_no;
 					
 					if ( $XLS_NEGATIFS{$rec_id} ) {
 					# REC EXISTS
						print "ERROR : Négatif ($rec_id) en doublons !";
					}
					else {
					# ADD REC
					
						$XLS_NEGATIFS{$rec_id}++;
					
						$rec_negatif 					= {};
						$rec_negatif->{posneg_id} 		= $rec_id;
 						$rec_negatif->{posneg_no}		= $rec_no;
						$rec_negatif->{pos_page}		= $rec_page;
 						$rec_negatif->{pos_ind}  		= $rec_indice;
 						$rec_negatif->{posneg_year}		= $rec_year;
 						$rec_negatif->{posneg_alpha} 	= $rec_alpha;
 						$rec_negatif->{posneg_col} 		= $col;
 						$rec_negatif->{posneg_event}	= $rec_event;
												
#						printf "%-16s %-3s %-3s %-3s %-3s %-3s %-24s \n",
#						$rec_negatif->{posneg_id},
#						$rec_negatif->{posneg_page},
#						$rec_negatif->{posneg_indice},
# 						$rec_negatif->{posneg_year},
# 						$rec_negatif->{posneg_alpha},
# 						$rec_negatif->{posneg_no},
# 						$rec_negatif->{posneg_event};
						
# !!! ON WORK 			bless 			
												
						$XLS_NEGATIFS{ $rec_negatif->{posneg_id} } = $rec_negatif;						
					}
				} 			
			} 
		}	
	}	
}



#sub connect_2_db {
#	my $dbh = shift;
#	if (defined($dbh)) {
#		print "Connected to $db_name.\n";
#		print Dumper($dbh);
#	}
#	else {
#		print "Connection to $db_name failed. Error is $DBI::errstr \n";
#		die;
#	} 	
#}	

# MAIN 

print "start populate program  ...\n";

$book = ReadData ($spreadsheet, attr => "0", dtfmt => "yyyy-mm-dd");

build_rec($book);

my $schema = Diapos::Main->connect('dbi:SQLite:dbname=db/diapos.db');

#print Dumper($schema);

if (defined($schema)) { 
	print "connected to $schema"; 
	foreach my $neg (keys %XLS_NEGATIFS) {
		push my @recs, [$XLS_NEGATIFS{$neg}->{posneg_id}, $XLS_NEGATIFS{$neg}->{posneg_year}, $XLS_NEGATIFS{$neg}->{posneg_alpha}, $XLS_NEGATIFS{$neg}->{posneg_no}, $XLS_NEGATIFS{$neg}->{posneg_col}, $XLS_NEGATIFS{$neg}->{posneg_event}, $XLS_NEGATIFS{$neg}->{pos_page}, $XLS_NEGATIFS{$neg}->{pos_ind}];
		$schema->populate('posneg', [ [qw/posneg_id posneg_year posneg_alpha posneg_no posneg_col posneg_event pos_page pos_ind/], @recs ]);  			
	}
} 
else {
	die;
}


#print Dumper(%XLS_NEGATIFS);
