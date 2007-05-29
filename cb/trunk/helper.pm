#!/usr/bin/perl
#
# helper.pm
#
# package that provides some helpful functions for building modules that parse out metadata from URLs
# this module also includes functions to retrieve metadata from various repositories, given a unique ID

package helper;

use lib (".");
use strict;
use DBI;
use config qw(%config urlencode log log_error do_sleep urldecode $DEBUG parse_post_xml url_breakdown trim);
use XML::Simple;

# as HTTP::OAI::Harvester is a pain in the ass to find for Windows users we'll make it optional.
if (($config{"collect_papers"}) || ($config{"collect_comments"})) {
	my $module = "HTTP::OAI::Harvester";
	eval("use $module");
	die("Couldn't load $module : $!n") if ($@);
}

use HTML::TreeBuilder;
use Digest::MD5 qw(md5_hex);
use SOAP::Lite;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
use Exporter;
use vars qw(@EXPORT_OK @EXPORT @ISA);
@ISA = qw(Exporter);
@EXPORT = qw(google_search get_summary parse_ris get_pubmed_metadata search_pubmed get_crossref_metadata get_oai_metadata get_last_id search_pubmed_doi $doi_pattern download_url clean_identifier non_html);
@EXPORT_OK = qw();

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

# DOI format: http://www.doi.org/handbook_2000/appendix_1.html
our $doi_pattern = "((.+)\.(.+)\/(.+))";

our $google_search;

sub non_html {
	my $url = $_[0];
	
	if ($url =~ /\.pdf/i) {return 1;}
	if ($url =~ /\.mp3/i) {return 1;}
	if ($url =~ /\.mp4/i) {return 1;}
	if ($url =~ /\.m4a/i) {return 1;}
	if ($url =~ /\.jpg/i) {return 1;}
	if ($url =~ /\.jpeg/i) {return 1;}
	if ($url =~ /\.gif/i) {return 1;}	
	if ($url =~ /\.png/i) {return 1;}
	
	return 0;
}

sub google_search {
	my $query = $_[0];
	
	my @results;
	
	if ($query =~ /"(http(.*))"/) {$query = $1;}
	
	if (!$google_search) {$google_search = SOAP::Lite->service("file:".$config{"google_wsdl"});}
	
	my $results = $google_search->doGoogleSearch($config{"google_api_key"}, $query, 0, 10, "false", "",  "false", "", "", "");

	# No results?
	if (!@{$results->{resultElements}}) {
		return @results;
	}

	# Loop through the results
	foreach my $result (@{$results->{resultElements}}) {
		my %return;
		
		$return{"title"} =  $result->{title} || "no title";
		$return{"snippet"} = $result->{snippet} || 'no snippet';
		
		push(@results, \%return);
	}
	
	return @results;
}

sub clean_identifier {
	# clean up a DOI, PMID or OAI id (PIIs could be anything, so don't use this for that).
	my $id = $_[0];
	
	$id =~ s/[\s\'\"\\\`]//g;
	
	if ($id =~ /doi:(.*)/i) {
		$id = $1;
	}
	
	return $id;
}

sub get_summary {
	my $text = $_[0];
	my $len = $_[1];

	if (!$len) {$len = 256;}

	$text =~ s/\&lt\;/</g;
	$text =~ s/\&gt\;/>/g;
	
	my $tree = HTML::TreeBuilder->new_from_content($text);

	$text = $tree->as_trimmed_text();
	
	if (length($text) <= $len) {
		return $text;
	}

	while (substr($text, $len, 1) =~ /\S/) {
		$len++;
	}

	return substr($text, 0, $len);
}

sub parse_ris {
	my $ris = $_[0];

	my %return;
	
	my @lines = split(/[\n\r]/, $ris);

	foreach my $line (@lines) {
		if ($line =~ /(\w\w)(?:\s*)\-(?:\s*)(.*)/i) {
			$return{$1} = $2;
		}
	}

	return %return;
}

sub download_url {
	my $url = $_[0];
	my $override_temp = $_[1];
	my $bypass_proxy = $_[2];
	my $compare_timestamps_with = $_[3];
	
	$url =~ s/&#038;/&/g;
	
	my $filename = md5_hex($url);

	if ((-e "temp/$filename") && (!$override_temp)) {
		open(FILE, "temp/$filename");
		my @lines = <FILE>;
		close(FILE);
		return "@lines";
	}

	my $proxy = "";
	if ($config{"proxy_url"}) {
		$proxy = sprintf("-U %s:%s -x %s", $config{"proxy_username"}, $config{"proxy_password"}, $config{"proxy_url"});
	}
	if ($bypass_proxy) {$proxy = "";}
	
	my $timestamps = "";
	if ($compare_timestamps_with) {
		$timestamps = "-z $compare_timestamps_with";
	}
	
	my $agent = $config{"user_agent"};
	
	# hack to stop Connotea from throttling us
	if ($url =~ /connotea/i) {
		$agent .= " WWW::Connotea";
	}
	
	my $silent = "-s";
	if ($config{"curl_verbose"}) {$silent = "";}
	
	my $results = `curl $proxy -L -g $silent -m 30 $timestamps -A "$agent" "$url"`;
	
	# write file to cache, unless override_temp is on.
	if (!$override_temp) {
		open(FILE, ">temp/$filename");
		print FILE $results;
		close(FILE);
	}

	return $results;
}


sub search_pubmed {
	my $text = urlencode("\"".$_[0]."\"");
	my $search_url = sprintf("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&tool=%s&email=%s&term=%s", $config{"name"}, $config{"email"}, $text);

	my $agent = $config{"user_agent"};
	my $results = `curl -s -L -m 30 -A "$agent" '$search_url'`;
	
	print STDERR $search_url."\n";

	$results =~ s/[\n\r]//g;
	$results =~ s/>(\s+)</></g;

	my @results;
	if ($results =~ /<ErrorList>/i) {
		# no go
		return undef;
	} else {	
		while ($results =~ /<Id>(.*?)<\/Id>/mig) {
			push(@results, $1);
		}
	}

	return @results;
}

sub search_pubmed_doi {
	my $doi = $_[0];
	my $search_url = sprintf("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&tool=%s&email=%s&term=%s", $config{"name"}, $config{"email"}, $doi);

	my $agent = $config{"user_agent"};
	my $results = `curl -s -L -m 30 -A "$agent" '$search_url'`;

	$results =~ s/[\n\r]//g;
	$results =~ s/>(\s+)</></g;

	if ($results =~ /<ErrorList>/i) {
		# no go
		return undef;
	} else {	
		if ($results =~ /<Id>(.*?)<\/Id>/ig) {
			return $1;
		} else {
			return undef;
		}
	}
}

sub get_pubmed_metadata {
	my $pubmed_id = $_[0];
	my %results;
	
	my $entrez_url = sprintf("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&tool=%s&email=%s&retmode=xml&id=%s", $config{"name"}, $config{"email"}, $pubmed_id);

	my $agent = $config{"user_agent"};
	my $results = `curl -s -L -m 30 -A "$agent" '$entrez_url'`;

	if ($results =~ /Error>(.*?)<\/Error/i) {
		log_error("Pubmed metadata request for $pubmed_id returned an error (\"$1\").");
		$results{"status"} = "Error $1";
		return %results;
	}


	# we could use Simple::XML here but it's actually just as easy to pull data out with regexps
	$results =~ s/[\n\r]//g;
	$results =~ s/>(\s+)</></g;

	$results{"pubmed_id"} = $pubmed_id;

	if ($results =~ /<Journal>(?:.*?)<Year>(.*?)<\/Year>(?:.*?)<\/Journal>/i) {$results{"pubdate_year"} = $1;}
	if ($results =~ /<Journal>(?:.*?)<Month>(.*?)<\/Month>(?:.*?)<\/Journal>/i) {$results{"pubdate_month"} = $1;}
	if ($results =~ /<Journal>(?:.*?)<Day>(.*?)<\/Day>(?:.*?)<\/Journal>/i) {$results{"pubdate_day"} = $1;}
	if ($results =~ /<Journal>(?:.*?)<Title>(.*?)<\/Title>(?:.*?)<\/Journal>/i) {$results{"journal"} = $1;}
	if ($results =~ /<Journal>(?:.*?)<ISOAbbreviation>(.*?)<\/ISOAbbreviation>(?:.*?)<\/Journal>/i) {$results{"journal_iso"} = $1;}
	if ($results =~ /<ArticleTitle>(.*?)<\/ArticleTitle>/i) {$results{"title"} = $1;}
	if ($results =~ /<AbstractText>(.*?)<\/AbstractText>/i) {$results{"abstract"} = $1;}
	if ($results =~ /<PublicationType>(.*?)<\/PublicationType>/i) {$results{"type"} = $1;}

	if ($results =~ /<ArticleId IdType="doi">(.*?)<\/ArticleId>/i) {$results{"doi"} = $1;}
	if ($results =~ /<ArticleId IdType="pii">(.*?)<\/ArticleId>/i) {$results{"pii"} = $1;}

	my @authors;
	while ($results =~ /<Author(?:.*?)>(.*?)<\/Author>/mig) {
		my $author_xml = $1;
		my $author = "";
		
		if ($author_xml =~ /<ForeName>(.*?)<\/ForeName>/) {$author .= $1." ";}
		if ($author_xml =~ /<LastName>(.*?)<\/LastName>/) {$author .= $1;}

		push(@authors, $author);
	}
	if (@authors) {$results{"authors"} = \@authors;}

	my @mesh;
	while ($results =~ /<DescriptorName(?:.*?)>(.*?)<\/DescriptorName>/mig) {
		push(@mesh, $1);
	}
	if (@mesh) {$results{"mesh"} = \@mesh;}

	return %results;
}

sub get_crossref_metadata {
	my $doi = $_[0];
	my %results;

	my $crossref_url = sprintf("http://www.crossref.org/openurl?url_ver=Z39.88-2004&rft_id=info:doi/%s&noredirect=true", $doi);

	my $agent = $config{"user_agent"};
	my $results = `curl -s -L -m 30 -A "$agent" "$crossref_url"`;

	$results =~ s/[\n\r]//g;

	if ($results =~ /status="resolved"/) {

		$results{"doi"} = $doi;

		if ($results =~ /<article_title>(.*?)<\/article_title>/i) {$results{"title"} = $1;}
		if ($results =~ /<journal_title>(.*?)<\/journal_title>/i) {$results{"journal"} = $1;}
		if ($results =~ /<year>(.*?)<\/year>/i) {$results{"pubdate_year"} = $1;}
		
		my @authors;
		while ($results =~ /<author>(.*?)<\/author>/gmi) {
			push(@authors, $1);
		}
		
		if (@authors) {$results{"authors"} = \@authors;}
		
	}
	
	return %results;
}

sub get_oai_metadata {
	my $oai = $_[0];
	print STDERR "Checking $oai via OAI\n";
	my $repo = $_[1];
	if (!$repo) {$repo = "http://citebase.eprints.org/cgi-bin/oai2";}
	my %results;
	
	print STDERR "OAI Repo is $repo\n";

	my $h = new HTTP::OAI::Harvester(baseURL=>$repo);
	my $response = $h->repository($h->Identify);

	my $response = $h->GetRecord(
		identifier	=>	$oai, # Required
		metadataPrefix	=>	'oai_dc' # Required
	);

	if ($response->is_error) {
		my $error =  $response->error_as_HTML;
		print STDERR "Error in get_oai_metadata while fetching $oai: $error\n";
		return %results;
	}

	while (my $rec = $response->next) {
		if (!$rec) {print STDERR "No record returned\n"; return %results;}
		my $metadata = $rec->metadata;
		if ($metadata) {
			my $dom = $metadata->dom;
			my $string = $dom->toString;
			
			$string =~ s/[\n\r]//g;
			$string =~ s/(\s)(\s)/\1/g;

			$results{"journal"} = "arXiv";
			$results{"arxiv_id"} = $oai;
			
			# there can be more than one dc:description in the metadata
			while ($string =~ /<dc:description>(.*?)<\/dc:description>/mig) {
				$results{"abstract"} .= $1;
			}

			if ($string =~ /<dc:title>(.*?)<\/dc:title>/i) {$results{"title"} = $1;}
			if ($string =~ /<dc:date>(.*?)<\/dc:date>/i) {$results{"pubdate"} = $1;}
			
			my @authors;
			while ($string =~ /<dc:creator>(.*?)<\/dc:creator>/ig) {
				push(@authors, $1);
			}

			if (@authors) {$results{"authors"} = \@authors;}
		}
	}

	return %results;
}

sub get_last_id {
	my $db = $_[0];
	my $id = 0;

	my $sql = $db->prepare("SELECT last_insert_id() AS id");
	$sql->execute();
	while (my $row = $sql->fetchrow_hashref()) {
		$id = $row->{"id"};
	}
	return $id;
}

return 1;
