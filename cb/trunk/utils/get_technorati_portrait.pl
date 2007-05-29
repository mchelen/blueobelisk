#!/usr/bin/perl
#
# fix Feedburner permalinks
#

use lib (".");
use strict;
use DBI;
use config qw(%config log log_error urldecode $DEBUG parse_post_xml url_breakdown);
use helper qw(download_url);
use Digest::MD5 qw(md5_hex);
use HTML::TreeBuilder;
use Encode qw(encode);

my $connection_string = sprintf("dbi:mysql:%s:%s", $config{"db_name"}, $config{"db_host"});
my $db = DBI->connect($connection_string, $config{"db_user"}, $config{"db_password"}) or log_error("Couldn't connect to the database.\n");

my %blogs;

my $sql = $db->prepare("SELECT blog_id, url FROM blogs");
$sql->execute();
while (my $row = $sql->fetchrow_hashref()) {
	my $blog_id = $row->{"blog_id"};
	my $url = $row->{"url"};
	
	$blogs{$blog_id} = $url;
}

foreach my $blog_id (keys(%blogs)) {
	my $blog = $blogs{$blog_id};
	
	print STDERR "Doing blog $blog_id at $blog\n";
	
	my $page = download_url("http://www.technorati.com/blogs/".$blog);

	if ($page =~ /class="photo" src="(http:\/\/static.technorati.com\/progimages\/photo.jpg\?uid=(\d+))"/i) {
		print STDERR "Got photo of user id $2, url is $1\n";
		
		my $minipath = "images/portraits/$blog_id.jpg";
		my $path = $config{"path_to_interface"}.$minipath;
		system("curl $1 > $path");
		
		my $update = $db->prepare("UPDATE blogs SET image=? WHERE blog_id=?");
		$update->execute($minipath, $blog_id);
	}
}


