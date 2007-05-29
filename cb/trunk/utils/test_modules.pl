#!/usr/bin/perl
#
#  test modules - make sure they work without a site licence etc.
#

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown do_sleep get_timestamp);
use helper qw(get_pubmed_metadata get_oai_metadata get_crossref_metadata get_last_id search_pubmed_doi non_html);
use XML::Simple;
use Digest::MD5 qw(md5_hex);
use Date::Parse;
use Encode qw(encode);

my $encoding = "ascii";

my $FOR_REAL = 1;

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

# find out which modules understand which URLs
my @files = glob("modules/*");
my %understands;
foreach my $file (@files) {
	
	if (-d $file) {next;}
	
	open(FILE, $file);
	my @lines = <FILE>;
	close(FILE);

	foreach my $line (@lines) {
		$line =~ s/\s//g;
		if ($line =~ /UNDERSTANDS:(.*)/ig) {
			if ($understands{$1}) {
				my @array = @{$understands{$1}};
				push(@array, $file);
				$understands{$1} = \@array;
			} else {
				$understands{$1} = [$file];
			}
		}
	}
}
my %exists;

my %domains;
my $sql = $db->prepare("SELECT DISTINCT domain FROM links WHERE !ISNULL(paper_id)");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	$domains{$row->{"domain"}} = 1;
}

my %test_cases;
foreach my $domain (keys(%domains)) {

	my $sql = $db->prepare("SELECT DISTINCT url FROM links WHERE !ISNULL(paper_id) AND domain=? ORDER BY RAND() LIMIT 10");
	$sql->execute($domain);
	
	while (my $row = $sql->fetchrow_hashref()) {
		my $url = $row->{"url"};
		$test_cases{$url} = 1;
	}
}

my %parsed;

foreach my $url (keys(%test_cases)) {	
	# skip any URLs linking to filetypes that we can't handle...
	if (non_html($url)) {next;}
	
	# does it match any of our modules?
	foreach my $pattern (keys(%understands)) {
		if ($url =~ /$pattern/) {
			my @files = @{$understands{$pattern}};

			foreach my $script (@files) {
				print STDERR "\nUsing ".$script." to parse $url\n";
				my @results = `$script "$url"`;
				my %results;
				# read results into the results hash.
				foreach my $result (@results) {
					if ($result =~ /(.*)\t(.*)/ig) {
						$results{$1} = $2;
					}
				}
			
				if (scalar(keys(%results))) {
					if ($parsed{$url}) {
						my %existing = %{$parsed{$url}};
						foreach my $existing (keys(%existing)) {
							$results{$existing} = $existing{$existing};
						}
						$results{"status"} = "success";
					}
					$parsed{$url} = \%results;
				} else {
					# parsed the url, but no results were forthcoming
					if (!$parsed{$url}) {
						my %results;
						$results{"status"} = "failed";
						$parsed{$url} = \%results;
					}
				}
			}
		}
	}

	if ($parsed{$url}) {
		my %details = %{$parsed{$url}};
		process_metadata($url, \%details);
	}
}

foreach my $url (keys(%test_cases)) {
	print $url."\t".$test_cases{$url}."\n";
}	

sub process_metadata {
	my %parsed;
	my $url = $_[0];
	my %details = %{$_[1]};

	# get details using OAI
	if ($details{"OAI"}) {

		if ($exists{"OAI"}{$details{"OAI"}}) {
			#update_links($url, $exists{"OAI"}{$details{"OAI"}});
			print STDERR "Update OAI links\n";
			return;
		}
			
		# the arXiv OAI server is slooooooooow
		#my %results = get_oai_metadata($details{"OAI"}, "http://arXiv.org/oai2");
		my %results = get_oai_metadata($details{"OAI"});
		sleep(2);

		if (%results) {
			insert_results($url, \%results);
			return;
		} else {
			print STDERR "Couldn't get results for ".$details{"OAI"}."\n";
		}
	}

	# if we've got a DOI but not PMID, see if we can find that DOI in PubMed (which has much better metadata than Crossref)
	if ( ($details{"DOI"}) && (!$details{"PMID"}) ) {
		my $pmid = search_pubmed_doi($details{"DOI"});
		if ($pmid) {
			print STDERR "Found DOI ".$details{"DOI"}." in pubmed\n";
			$details{"PMID"} = $pmid;
		}
	}

	# get details from pubmed
	if ($details{"PMID"}) {

		if ($exists{"PMID"}{$details{"PMID"}}) {
			#update_links($url, $exists{"PMID"}{$details{"PMID"}});
			print STDERR "Update PMID links\n";
			return;
		}

		my %results = get_pubmed_metadata($details{"PMID"});
		
		if ($results{"status"} =~ /error/i) {
			print STDERR "Something is wrong with Pubmed.\n";
			return;
		}

		if (%results) {
			print STDERR "Got pubmed results for ".$details{"PMID"}."\n";
			insert_results($url, \%results);
			return;
		} else {
			print STDERR "Couldn't get results for ".$details{"PMID"}."\n";
		}
	}

	# get details from crossref
	if ($details{"DOI"}) {

		if ($exists{"DOI"}{$details{"DOI"}}) {
			#update_links($url, $exists{"DOI"}{$details{"DOI"}});
			print STDERR "Update DOI links\n";
			return;
		}

		my %results = get_crossref_metadata($details{"DOI"});
		sleep(2);
	
		if (%results) {
			print STDERR "Got crossref results for ".$details{"DOI"}."\n";
			insert_results($url, \%results);
			return;
		} else {
			print STDERR "Couldn't get results for ".$details{"DOI"}."\n";
		}
	}
	
	# it's a story! (maybe)
	if ($details{"STORY"}) {
		# two things:
		# 1) mark the link with is_story
		# 2) set the "title" attribute
		
		#my $query = $db->prepare("UPDATE links SET is_story=1, followed=1, title=? WHERE url=?");
		#$query->execute($details{"STORY"}, $url);
		return;
	}
	
	# if we've reached this point then we've not been able to get metadata about this paper from anywhere. D'oh.
	if ($details{"status"} eq "failed") {
		log_error("Couldn't parse $url");
	} else {
		log_error("Can't get metadata for $url");
	}

	print STDERR "Giving up.\n";
	#my $update = $db->prepare("UPDATE links SET followed=1 WHERE url=?");
	#$update->execute($url);

}

sub update_links {
	my $url = $_[0];
	my $paper_id = $_[1];
	my $type = $_[2]; # paper_id

	if (!$type) {$type = "paper_id";}

	if ($paper_id && $url) {
		#my $update = $db->prepare("UPDATE links SET $type=?, followed=? WHERE url=?");
		#$update->execute($paper_id, 1, $url) if $FOR_REAL;
		print STDERR "Updating link to point to $paper_id\n";
	}
}

sub insert_results {
	my $url = $_[0];
	my %results = %{$_[1]};

	print STDERR $results{"title"}." in ".$results{"journal"}."\n";
	if ($results{"journal_iso"}) {$results{"journal"} = $results{"journal_iso"};}
	if (!$results{"pubdate_day"}) {$results{"pubdate_day"} = "01";}
	if (!$results{"pubdate_month"}) {$results{"pubdate_month"} = "Jan";}
	if (!$results{"pubdate_year"}) {$results{"pubdate_year"} = "2001";}

	my $time = $results{"pubdate"};

	if (!$results{"pubdate"}) {
		$time = sprintf("%s %s %s", $results{"pubdate_month"}, $results{"pubdate_day"}, $results{"pubdate_year"});	
	}

	$time = str2time($time);
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
	$results{"pubdate"} = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
	
	if (!$results{"authors"}) {
		$results{"authors"} = "unknown";
	} else {
		$results{"authors"} = join(', ', @{$results{"authors"}});
	}
	#my $update = $db->prepare("INSERT INTO papers (pubmed_id, doi_id, arxiv_id, pii_id, journal, title, abstract, authors, pubdate, added_on) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP())");
	#$update->execute($results{"pubmed_id"}, $results{"doi"}, $results{"arxiv_id"}, $results{"pii"}, encode($encoding, $results{"journal"}), encode($encoding, $results{"title"}), encode($encoding, $results{"abstract"}), encode($encoding, $results{"authors"}), $results{"pubdate"}) if $FOR_REAL;
	print STDERR "Inserting results\n";
	$test_cases{$url} = 2;
	#my $paper_id = get_last_id($db);

	# update paper_id in the links table
	#update_links($url, $paper_id);
	
	# update exists hash
	#if ($results{"doi"}) {$exists{"DOI"}{$results{"doi"}} = $paper_id;}
	#if ($results{"pubmed_id"}) {$exists{"PMID"}{$results{"pubmed_id"}} = $paper_id;}
	#if ($results{"arxiv_id"}) {$exists{"OAI"}{$results{"arxiv_id"}} = $paper_id;}
}
