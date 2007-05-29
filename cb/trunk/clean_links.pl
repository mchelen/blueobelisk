#!/usr/bin/perl
#
# clean up links (consolidate them; so www.blogger.com and blogger.com, for example, are considered the same)
#

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown);
use XML::Simple;
use Digest::MD5 qw(md5_hex);

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

# a global cleanup first...
my $update = $db->prepare("UPDATE links SET directory=? WHERE ISNULL(directory)");
$update->execute("/");

my %urls = get_links();

foreach my $domain (keys(%urls)) {
	#print STDERR "$domain\n";
	if ($urls{"www.".$domain}) {
		# there's a www. version of this domain - use it, instead
		print STDERR "Replacing $domain with www.$domain\n";
		my $update = $db->prepare("UPDATE links SET domain=? WHERE domain=?");
		$update->execute("www.".$domain, $domain);
	}
}

%urls = get_links();

foreach my $domain (keys(%urls)) {
	my %dirs = %{$urls{$domain}};
	foreach my $dir (keys(%dirs)) {
		# if there's a trailing slash, add that.
		if ($dirs{$dir."/"}) {
			print STDERR "Adding trailing slash to [$domain][$dir]\n";
			my $update = $db->prepare("UPDATE links SET directory=? WHERE domain=? AND directory=?");
			$update->execute($dir."/", $domain, $dir);
		}
	}
}

%urls = get_links();

foreach my $domain (keys(%urls)) {
	my %dirs = %{$urls{$domain}};
	foreach my $dir (keys(%dirs)) {
		my %files = %{$dirs{$dir}};
		foreach my $file (keys(%files)) {
			# if there's an index.* and a trailing slash, go with the index.*
			#print STDERR "[$domain][$dir][$file]\n";
			if ($file =~ /\Aindex\.([^?]+)\Z/) {
				if ($1 =~ /xml|rdf/) {next;} 
				if ($urls{$domain}{$dir}{""}) {
					print STDERR "index file at [$domain][$dir][$file]\n";

					my $update = $db->prepare("UPDATE links SET file=? WHERE domain=? AND directory=?");
					$update->execute("index.".$1, $domain, $dir);
				}
			}
		}
	}
}

rebuild_links();

log("script complete");

sub rebuild_links {
	my $sql = $db->prepare("SELECT * FROM links");
	$sql->execute();

	my %hashes;
	my %hash_change;

	while (my $row = $sql->fetchrow_hashref()) {
		my $domain = $row->{"domain"};
		my $directory = $row->{"directory"};
		my $file = $row->{"file"};
		my $hash = $row->{"id_url_hash"};
		my $post_id = $row->{"post_id"};

		my $url = "http://".$domain.$directory.$file;
		
		# recalculate hash - 
		my $new_hash = md5_hex($post_id.$url);
		my $new_url_hash = md5_hex($url);

		if ($new_hash eq $hash) {next;}
		
		# there might already be an entry in the database with the new hash... if so, delete it.
		my $delete = $db->prepare("DELETE FROM links WHERE id_url_hash=?");
		$delete->execute($new_hash);

		# now update the database
		my $update = $db->prepare("UPDATE links SET url=?, id_url_hash=?, url_hash=? WHERE id_url_hash=?");
		$update->execute($url, $new_hash, $new_url_hash, $hash);
	}
}

sub get_links {
	my $sql = $db->prepare("SELECT * FROM links");
	$sql->execute();

	my %urls;

	while (my $row = $sql->fetchrow_hashref()) {
		my $domain = $row->{"domain"};
		my $directory = $row->{"directory"};
		my $file = $row->{"file"};
		$urls{$domain}{$directory}{$file}++;
	}

	return %urls;
}
