#!/usr/bin/perl

my %categories = (
"bioinformatics", "bioinformatics",
"biotechnology", "biotechnology",
"chemistry", "chemistry",
"clinicalpracticeandresearch", "clinicalpractice",
"earthandenvironment", "earth",
"home", "home",
"lifesciences", "lifesciences",
"naturalhistory", "naturalhistory",
"neuroscience", "neuroscience",
"pharmacology", "phamacology",
"physics", "physics",
"scienceandsociety", "sciencesoc",
"sciencenews", "sciencenews"
);

my %shared_styles;
my %customs;

foreach my $category (keys(%categories)) {
	print STDERR "Getting CSS for $category\n";
	my $file = "pg_".$categories{$category}.".css";
	my $run = `scp euan\@neutron.nature.com:~luke/interface/$file $category/custom.css`;
	
	open(CSS, $category."/custom.css");
	my @lines = <CSS>;
	close(CSS);
	
	my $output;
	
	foreach my $line (@lines) {
		if ($line =~ /(.*)url\(['"](.*)['"]\)(.*)/i) {
			my $image = $2;
			my @bits = split(/\//, $image);
			$image = $bits[(scalar(@bits) - 1)];
			#print STDERR "\tGot image $1 url('$image')$3\n";
			$output .= $1."url('".$image."')".$3;
		} else {
			$output .= $line;
		}
	}
	
	open(CSS, ">".$category."/custom.css");
	print CSS $output;
	close(CSS);
	
	next;
	
	my %custom_styles = extract_styles($category."/custom.css");
	
	if (!%shared_styles) {%shared_styles = %custom_styles;}
	foreach my $style (keys(%custom_styles)) {
		if ($shared_styles{$style} eq $custom_styles{$style}) {
			# great!
		} else {
			delete $shared_styles{$style};
		}
		
		# delete 'shared' styles that link to url()s...
		if ($shared_styles{$style} =~ /url\(/ig) {
			delete $shared_styles{$style};
		}
	}
	$customs{$category} = \%custom_styles; 	
	
	# also copy graphics across
	my $dir = "images/".$categories{$category};
	my $run = `scp euan\@neutron.nature.com:~luke/interface/$dir/* $category/.`;
}

# go through all the custom styles and delete the parts that are shared.
foreach my $category (keys(%customs)) {
	my %styles = %{$customs{$category}};
	foreach my $style (keys(%styles)) {
		if ($shared_styles{$style}) {
			# delete $styles{$style};
		}
	}
	#write_styles(\%styles, $category."/custom.css");
}
#write_styles(\%shared_styles, "shared.css");

sub write_styles {
	my %styles = %{$_[0]};
	my $filename = $_[1];
	
	open(CSS, ">$filename");
	my @styles = keys(%styles);
	@styles = sort(@styles);
	
	foreach my $style (@styles) {
		print CSS sprintf("%s {\n\t%s}\n", $style, $styles{$style});
	}
	close(CSS);
}

sub extract_styles {
	my $css = $_[0];
	my %styles = ();
	
	# get shared CSS styles...
	open(CSS, $css);
	my @lines = <CSS>;
	close(CSS);
	my $lines = "@lines";

	my %styles;

	while ($lines =~ /[\n\r](.*?)(?:[\s]*){(.*?)}/sig) {
		my $name = $1;
		my $style = $2;
		
		$name =~ s/\/\*(.*?)\*\/([\s\r\n\t]*)//ig;
		$name =~ s/^(\s*)//ig;
		$style =~ s/[\r\n\t]//ig;
		$style =~ s/[;]/\;\n\t/ig;
		
		my @names = split(/,/, $name);
		foreach my $name (@names) {
			$name =~ s/^(\s*)//ig;
			$styles{$name} = $style;
		}
	}

	return %styles;
}













