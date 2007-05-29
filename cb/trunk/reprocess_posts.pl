#!/usr/bin/perl
#
# keep track of posts in the database
#

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_feed_xml parse_post_xml trim);
use helper qw(get_summary);
use XML::Simple;
use Digest::MD5 qw(md5_hex);
use Encode qw(encode);
use HTML::Entities;
use URI::Escape;

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

# get a list of posts that are already in the database
my %posts;
my %exists;
my $sql = $db->prepare("SELECT url, filename, content_hash FROM posts");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	my $url = $row->{"url"};
	my $filename = $row->{"filename"};
	my $content_hash = $row->{"content_hash"};
	
	$exists{$filename} = 1;
	$posts{$url} = $content_hash;
}

# now read the posts we've got on disk from active feeds
my $sql = $db->prepare("SELECT blog_id, title, feed_url FROM blogs WHERE active=1");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	my $blog_id = $row->{"blog_id"};
	my $feed_url = $row->{"feed_url"};
	my $title = $row->{"title"};
	my $hash = md5_hex($feed_url);

	my $posts_dir = "posts/".$hash;

	print STDERR "Doing $title\n";
        print STDERR " -> hash: $hash\n";

	my @posts = glob($posts_dir."/post_*");
	foreach my $post (@posts) {
		
		if (!$config{"allow_post_edits"}) {
			if ($exists{$post}) {
				print STDERR "-";
				next;
			}
		}

		my %details = parse_post_xml($post);
			
		my $content_hash = md5_hex($details{"description"});
		my $url = fix_permalink($details{"link"});
		my $summary = get_summary($details{"description"});

		if ($posts{$url}) {
			# post exists in the database
			if ($posts{$url} eq $content_hash) {
				# post exists... and it hasn't changed
				print STDERR "." if $DEBUG;

				my $post_id = 0;
				my $get_id = $db->prepare("SELECT last_insert_id() AS post_id");
				$get_id->execute();
				while (my $row = $get_id->fetchrow_hashref()) {
					$post_id = $row->{"post_id"};
				}

				# get_terms($post_id, $post);
	
				# insert tags
				my @tags;
				if (ref($details{"tag"}) eq "ARRAY") {
					@tags = @{$details{"tag"}};
				} else {
					@tags = ($details{"tag"});
				};
				
				# extract some information now
				my @tags = extract_technorati_tags(\%details);
				
				foreach my $tag (@tags) {
					$tag = lc($tag);
					$tag =~ s/,\Z//g;
					$tag =~ s/<(.*?)>//g;
					if (length($tag) <= 1) {next;}
					if (length($tag) >= 255) {next;}				
					if ($tag eq "unknown") {next;}
					my $id_tag_hash = md5_hex($post_id.$tag);
					my $update = $db->prepare("INSERT IGNORE INTO tags (id_tag_hash, post_id, tag, tagged_by, blog_id) VALUES (?, ?, ?, ?, ?)");
					$update->execute($id_tag_hash, $post_id, $tag, "blog", $blog_id);
				}
			}
		}
	}
}

log("script complete");

sub get_terms {
	my $post_id = $_[0];
	my $filename = $_[1];
	
	my %post = parse_post_xml($filename);
	print STDERR $post_id." ".$post{"title"};
	
	my $url = "http://api.search.yahoo.com/ContentAnalysisService/V1/termExtraction";
	my $appid = "postgenomic";
	my $tree = HTML::TreeBuilder->new_from_content($post{"description"});
	my $content = uri_escape(encode("UTF-8", $tree->as_trimmed_text()));
	my $output = "xml";
	
	my $result = `curl -s -d "appid=$appid&output=$output&context=$content" $url`;

	if (!$result) {
		print STDERR "x\n";
		return 0;
	}
	
	if ($result =~ /<Error(.*?)<\/Error>/mig) {
		print STDERR "e\n";
		return 0;
	}

	my @terms;
	if ($result) {
		while ($result =~ /<result>(.*?)<\/result>/mig) {
			push(@terms, $1);
		}
	}
	
	foreach my $term (@terms) {
		my $id_term_hash = md5_hex($post_id.$term);
		my $insert = $db->prepare("INSERT IGNORE INTO terms (id_term_hash, post_id, term) VALUES (?, ?, ?)");
		$insert->execute($id_term_hash, $post_id, $term);
		print STDERR "-$term-";
		print STDERR "."; 
	}	
	print STDERR "\n";
	return 1;
}

sub fix_permalink {
	my $url = $_[0];
	if ($url =~ /feeds\.feedburner\.com/) {
		# follow the link, see where we get redirected to
		my $header = `curl -s -I $url`;

		if ($header =~ /Location: ([^\s]*)/i) {
			my $real_url = $1;
			if ($real_url =~ /http:\/\/(scienceblogs.*)/) {
				$real_url = "http://www.$1";
			}
			print STDERR "$url redirected to [$real_url]\n";
			return $real_url;
		} else {
			if ($header =~ /HTTP\/1\.1 404/i) {
				log_error("Got 404 for $url\n");
			} else {
				log_error("Couldn't get redirection for $url. Stopping in case it's a server denial thing:\n$header\n", 1);
			}
		}		
	} else {
		return $url;
	}
}

sub extract_technorati_tags {
	my %post = %{$_[0]};
	
	my $title = $post{"title"};
	my $content = $post{"description"};
	my @tags;
	if (ref($post{"tag"}) eq "ARRAY") {
		@tags = @{$post{"tag"}};	  
	} else {
		@tags = ($post{"tag"});
	};

	my %tags;
	foreach my $tag (@tags) {
		$tags{lc($tag)} = 1;
	}

	$content = decode_entities($content);
	
	while ($content =~ /<a (?:.*?)rel=['"]tag['"](?:.*?)>(.*?)<\/a>/igm) {
		my $tag = $1;
		$tag =~ s/<(.*?)>//g;
		if ( (length($tag) > 1) && (length($tag) <= 255) ) {
			$tag = lc($tag);
			$tag = trim($tag);
			if (!$tags{$tag}) {$tags{$tag} = 1;}
		}
	}

	return keys(%tags);
}
