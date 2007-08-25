#!/usr/bin/perl
#
# scripts that get run a couple of times a day
#

use lib (".");
use config qw(%config);

use strict;

system("perl get_feeds.pl"); # download feeds
system("python parse_feed.py"); # extract posts from feeds, put into flatfiles
# blogs <= 75 : dreamhost kills long processes, so split up
system("perl update_posts.pl"); # put new posts into the database
# blogs > 75
system("perl update_posts_2.pl");
system("perl update_feeds.pl"); # update feed names, descriptions etc.
system("perl get_links.pl"); # get all URLs from posts
system("perl get_inchis.pl"); # get all InChIs from posts
system("perl parse_wp_links.pl");
system("perl get_cids.pl"); # get CIDs from PubChem for the InChI's
system("perl get_cid_images.pl"); # get images for the CIDs
system("perl get_cid_cml.pl");
system("perl clean_links.pl"); # clean up URLs

if ($config{"collect_links"}) {
	system("perl name_links.pl"); # get titles for links
}

#system("perl get_amazon.pl"); # get book metadata from Amazon
if ($config{"collect_papers"}) {
	system("perl parse_links.pl"); # follow links to see if they lead to papers
}

# ACS journals don't have titles in CrossRef, so do manually
system("perl handle_acs.pl");
system("perl handle_pubmed.pl");
system("perl handle_biomed.pl");

#system("perl get_connotea_cache.pl"); # get cache of recent items from Connotea
#system("perl get_connotea_tags.pl"); # match tags and comments to items in our database
system("perl generate_summaries.pl"); # generate summary tables to speed up front-end
system("perl get_bursts.pl"); # get wordbursts
system("perl geolocate_terms.pl"); # geolocate terms associated with conference posts
system("perl generate_xml.pl"); # generate flatfiles for papers in the database
system("perl wipe_cache.pl"); # wipe cache of interface

if ($config{"do_search"}) {
	system("python index.py"); # add new items to Lucene index
}

# dump current version of the database
my $dump_cmd = sprintf("mysqldump -h %s -u %s --password=%s %s > %s", $config{"db_host"}, $config{"db_user"}, $config{"db_password"}, $config{"db_name"}, $config{"path_to_interface"}."current.dump");

system($dump_cmd);
