#!/usr/bin/perl
#
package config;

use strict;
use Config::Natural;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
use Exporter;
use vars qw(@EXPORT_OK @EXPORT @ISA);
use XML::Simple;
@ISA = qw(Exporter);
@EXPORT = qw(%config quick_parse_post_xml log_error log urldecode $DEBUG trim do_sleep parse_post_xml parse_feed_xml get_timestamp url_breakdown urlencode translate_date);
@EXPORT_OK = qw();
use Encode qw(encode);

my $DEFAULT_LOG_DIR = "logs/";
my $DEFAULT_CONF_DIR = "conf/";
our $DEBUG = 1;

# look for config files...
my @config_files = glob($DEFAULT_CONF_DIR."*.conf");
my $conf_file = "default.conf";
foreach my $file (@config_files) {
	if ($file =~ /([\w\d\.\-]+)\.conf/i) {$file = $1.".conf";}
	if ($file ne $conf_file) {
		$conf_file = $file;
	}
}

our %config;
my $config = new Config::Natural $DEFAULT_CONF_DIR.$conf_file or log_error("Couldn't load pipeline configuration file", 1);
my @params = $config->param;
foreach my $param (@params) {
	$config{$param} = $config->param($param);
}

sub parse_feed_xml {
  
  my $file = $_[0];
  my $ref = XMLin($file);

  my %feed;

  my @fields = ("title", "link", "feed_id", "description");

  foreach my $field (@fields) {
    my $value = $ref->{$field};

    if (!$ref->{$field}) {$value = "unknown";}
    if ($value =~ /\AHASH\(/) {$value = "unknown";}
    $feed{$field} = encode("ascii", $value);
    $feed{$field."_raw"} = $value;
  }
  
  return %feed;
}

sub quick_parse_post_xml {
	my $file = $_[0];

        if (!(-e $file)	) {
            print STDERR "Post XML does not exist: $file\n";
            return;
        }
	open(FILE, $file);
	my @lines = <FILE>;
	close(FILE);
	
	my $lines = "@lines";
	
	my %return;
	
	if ($lines =~ /<description>(.*?)<\/description>/is) {
		$return{"description"} = $1;
	}
	
	return %return;
}

sub parse_post_xml {
  my $file = $_[0];

  if (!(-e $file) ) {
    print STDERR "Post XML does not exist: $file\n";
    return;
  }

  my %post;

  my @fields = ("tag", "title", "link", "feed_id", "date", "description");

  # the line below barfs and dies if there are any funny characters in the input...
  # my $ref = XMLin($file);
  my $ref = eval { XMLin($file) };
  if($@) {
    print STDERR "ERROR: XML invalid in $file\n";
    print STDERR "$@";
  }

  foreach my $field (@fields) {
	my @value = ();
	my $value = "";
	if (ref($ref->{$field}) eq "ARRAY") {
		@value = @{$ref->{$field}};
	} else {
    		$value = $ref->{$field};
    	}
    if (!$ref->{$field}) {$value = "unknown";}
    if ($value =~ /\AHASH\(/) {$value = "unknown";}
    if (@value) {
	$post{$field} = \@value;
    	$post{$field."_raw"} = \@value;
    } else {
    	$post{$field} = encode("ascii", $value);
    	$post{$field."_raw"} = $value;
    }
  }

  if ($post{"date"}) {
	# translate date into MySQL format (yyyy-mm-dd hh:mm:ss)
	$post{"date"} = translate_date($post{"date"});
  }
  
  return %post;
}

sub translate_date {
	my $created = $_[0];
	my %months = (
		"JAN", "01",
		"FEB", "02",
		"MAR", "03",
		"APR", "04",
		"MAY", "05",
		"JUN", "06",
		"JUL", "07",
		"AUG", "08",
		"SEP", "09",
		"OCT", "10",
		"NOV", "11",
		"DEC", "12",
		"JANUARY", "01",
		"FEBRUARY", "02",
		"MARCH", "03",
		"APRIL", "04",
		"MAY", "05",
		"JUNE", "06",
		"JULY", "07",
		"AUGUST", "08",
		"SEPTEMBER", "09",
		"OCTOBER", "10",
		"NOVEMBER", "11",
		"DECEMBER", "12"
	);

	my $mysql_date;
	
	if ($created =~ /(\d{2}) (\w+?) (\d{4})/) {
			# format for some comments
    		my $day = $1;
    		my $month = $months{uc($2)};
    		my $year = $3;			
			$mysql_date = "$year-$month-$day 00:00:00";
	}
	
	if ($created =~ /(\d{2}) (\w{3}) (\d{4})/) {
			# format for some comments
    		my $day = $1;
    		my $month = $months{uc($2)};
    		my $year = $3;			
			$mysql_date = "$year-$month-$day 00:00:00";
	}

 	if ($created =~ /\d{4}-\d{2}-\d{2} \d{2}\:\d{2}\:\d{2}/) {
    		# already MySQL compatible
    		$mysql_date = $created;
  	}
  
  	if ($created =~ /\w{3}\, (\d{2}) (\w{3}) (\d{4}) (\d{2}\:\d{2}\:\d{2})/) {
    		# Atom feed stylee.
    		my $day = $1;
    		my $month = $months{uc($2)};
    		my $year = $3;
    		my $time = $4;
    		$mysql_date = "$year-$month-$day $time";
  	}

  	if ($created =~ /\w{3}\, (\d{1}) (\w{3}) (\d{4}) (\d{2}\:\d{2}\:\d{2})/) {
    		# Atom feed stylee.
    		my $day = $1;
    		my $month = $months{uc($2)};
    		my $year = $3;
    		my $time = $4;
    		$mysql_date = "$year-$month-$day $time";
  	}

  	if ($created =~ /(\d{4}-\d{2}-\d{2})T(\d{2}\:\d{2}\:\d{2})(?:[\.0]*)([+-Z])/) {
    		# RSS feed stylee.
    		my $date = $1;
    		my $time = $2;
    		$mysql_date = "$date $time";
  	}

  	if (!$mysql_date) {
    		# unknown format - replace with a timestamp from yesterday (so that the posts don't go to the top of the sorted list).
		$mysql_date = get_timestamp(1);
	}

	return $mysql_date;
}

# function that breaks down URLs into components.
sub url_breakdown {
  my $url = $_[0];
  my ($path, $domain, $directory, $file);

  if ($url =~ /http:\/\/(.*)/) {
    $path = $1;
    my @elements = split(/\//, $path);
    $domain = $elements[0];

    if (substr($path, -1, 1) eq "\/") {
      # there isn't a file, because the last character of the path is a forward slash.
    } else {
      $file = $elements[scalar(@elements) - 1];
      if ($domain eq $file) {
        # there is no directory or file.
        $file = undef;
      }
    }

    if (scalar(@elements) >= 2) {
      # there is no directory
      if ($file) {
        $directory = substr($path, length($domain), length($file) * -1);
      } else {
        $directory = substr($path, length($domain));
      }
    }
  } else {
    # $url doesn't match the standard http:\/\/ pattern (shouldn't every happen, we check for it in get_urls_from_posts.pl)
    return (undef, undef, undef, undef);
  }

  return ($path, $domain, $directory, $file);
}

sub do_sleep {
  my $secs = $_[0];
  for (my $i=0; $i < $secs; $i++) {
    sleep(1);
    print STDERR "." if $DEBUG;
  }
  return 1;
}

sub trim {
  my $msg = $_[0];
  $msg =~ s/^\s+//;
  $msg =~ s/\s+$//;
  return $msg;
}

sub urldecode {
	my $str = $_[0];
	$str =~ tr/+/ /;
	$str =~ s/%([a-fA-F0-9]{2,2})/chr(hex($1))/eg;
	$str =~ s/<!--(.|\n)*-->//g;
	return $str;
}

sub urlencode {
	my $str = $_[0];
	$str =~ s/([\W])/"%" . uc(sprintf("%2.2x",ord($1)))/eg;
	return $str;
}

sub log {
	my $message = $_[0];
	write_log($message);
	
	return 1;
}

sub log_error {
	my $message = $_[0];
	my $die = $_[1];
	write_log("ERROR: ".$message);
	if ($die) {die("Encountered a fatal error - $message");}

	return 1;
}

sub write_log {
	my $message = $_[0];
	my $logfile = $DEFAULT_LOG_DIR."pg.log";
	if ($config{'logfile'}) {
		$logfile = $config{'logfile'};
	}

	my $entry = get_timestamp()."\t".$0."\t".$message."\n";
	open(LOG, ">>".$logfile) or warn("Couldn't open logfile $logfile");
	print LOG $entry;
	close(LOG);

	if ($DEBUG) {print STDERR $entry;}

	return 1;
}

sub get_timestamp {
	my $days_ago = $_[0];
	
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	
	if ($days_ago) {$mday = ($mday - $days_ago); if ($mday <= 0) {$mday = 1;}}
	
	return sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min,$sec);
}

return 1;
