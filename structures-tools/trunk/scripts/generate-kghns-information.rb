#!/usr/bin/env ruby
#
# Ruby script for generating a KGetHotNewStuff file
#
# (c) 2007 Carsten Niehaus <cniehaus@gmx.de>
# License: GPL V2

require "rexml/document"

#return the chemical name of the molecule stored in the file
def getMoleculeName(filename)
	file = File.new( filename )
	doc = REXML::Document.new file
	doc.elements.each("molecule/name") { |element| 
		return element.text
	}
end

#return the XML for the molecule with the name "name" in the the given file
#and in the given directory
def xmlof(name, filename, directory) 
	#For the HTML-previewpage we need to change the filename a bit
	strippedstring = filename.sub('.cml' , '_en.html' )
	aString = <<EOS
	<stuff>
                <name>#{name}</name>
                <type>40</type>
                <author>Jerome Pansanel</author>
                <email>j.pansanel@pansanel.net</email>
                <license>FreeBSD</license>
                <summary>Important molecule</summary>
                <version>2.0.1</version>
                <release></release>
                <releasedate>2007-02-28</releasedate>
                <preview>http://chem-file.sourceforge.net/data/#{directory}/#{strippedstring}</preview>
                <payload>http://chem-file.sourceforge.net/data/#{directory}/#{filename}</payload>
                <rating></rating>
                <downloads></downloads>
                <more></more>
        </stuff>
EOS
end

#this Array stores all directories in the chem-struct database. I could find the out by some
#tricky Ruby-code but this hardcoding is far easier
directories = ["alcohols" , "aldehydes" , "alkanes" , "alkenes" , "alkynes" , "amides" , "amines" , "amino_acids" , "aromatics" , "carbamides" , "carbohydrates" , "carboxylic_acids" , "drugs" , "esters" , "ethers" , "fatty_acids" , "haloalkanes" , "heteroaromatics" , "ketones" , "macrocycles" , "nitriles" , "nitroalkanes" , "nucleobases" , "polycyclic_alkanes" , "polycyclic_aromatics" , "sulfones" , "sulfoxides" , "thioethers" , "thiols" , "water"]

xmloutputfile = File.new( "xmlout.xml", File::CREAT|File::TRUNC|File::RDWR )

xmloutputfile << "<?xml version=\"1.0\"?>\n"
xmloutputfile << "<knewstuff>\n"
	
#a global counter for the molecules
@@counter = 1

#go over all directories
directories.each{ |d|
	Dir.chdir( "/home/carsten/svn/blueobelisk/trunk/structures/src/#{d}" )
	list = Dir.glob("*.cml")

	#in each directory parse all files, get the valid XML and put the XML in the file
	list.each{|filename| 
		puts "#{@@counter}: " +  "Parsing #{filename}".center( 100, "-" )
		moleculename = getMoleculeName(filename) 
		xmloutputfile <<  xmlof(moleculename,filename,d)
		@@counter+=1
	}
}

xmloutputfile << "</knewstuff>"
