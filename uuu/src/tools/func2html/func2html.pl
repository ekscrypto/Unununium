#!/usr/bin/perl
#Func2HTML version 2.0 by Raptor-32 (Richard Fillion)
#My approach may be crude, but it should do the trick for now.




print "Opening Functions text file\n";

open(FUNC, "< functions.txt");
@funcs=<FUNC>;
close(FUNC);
#we got what we wanted from that guy.



#lets go through the file we got, and seperate it.

print "Creating Database... this may take a while\n";
foreach $function (@funcs){
	if ($function eq ""){
		#we've got a blanc line on our hands
	}
	else {
		#yay, something. :)
		@info=split(/ /, $function);
		if (@info[0] eq "object:"){
			#we hit an object header.
			$providedcount = 0;
			$requiredcount = 0;
			@info[1]=~ s/..\/..\/src//;
			@info[1]=~ s/\n//;
			$prov="provided";
			$requ="required";
			$refp = "@info[1]$prov";
			$refr = "@info[1]$requ";
			$objects{@info[1]} = "@info[1]" ;
			@objectnames[$objectcount]="@info[1]";
			$objects{$refp}= \@$refp;
			$objects{$refr}= \@$refr;
			$objectcount++;
		}
		if (@info[0] eq "\tp:"){
			#we hit a provided function
			@info[1]=~ s/\n//;
			@stats=split(/,/ , @info[1]);
			@fidcid=split(/\./ , @stats[2]);
			@fidcid[0]=~ s/__//;
			@fidcid[1]=~ s/c_//;
			$prov_array_name="@info[1]";
			@$prov_array_name=("@fidcid[0]","@fidcid[1]","@stats[0]","@stats[1]");
			@$refp[$providedcount]= "@$prov_array_name";
			$providedcount++;
		
		}
		if (@info[0] eq "\tr:"){
			@info[1]=~ s/\n//;
			@stats=split(/,/ , @info[1]);
			@fidcid=split(/\./ , @stats[2]);
			@fidcid[0]=~ s/__//;
			@fidcid[1]=~ s/c_//;
			$required_array_name="@info[1]";
			@$required_array_name=("@fidcid[0]","@fidcid[1]","@stats[0]","@stats[1]");
			@$refr[$requiredcount]="@$required_array_name";
			$requiredcount++;
			
		}
	}
} 	
print "Database Created.\n";
#database created. 
open(HTML, "> functions.html");
#make an out file


#@objectnames = sort @objectnames;

if (@ARGV == "") {
	print "Func2HTML 2.0 by Raptor-32\n";
	print "Possible command line options are:\n";
	print "\t-normal *(just process the file and format the html with default values.)\n";
	print "\t-sorted *(normal but with cells in alpha-numeric order.)\n";
	print "\t-provided_only *(only output provided functions.)\n";
	print "\t-required_only *(only output required functions.)\n";
	print "\t-cell_name_only *(only output the cell names.)\n";
	print "\t-strip_FID_CID *(do not output CIDs and FIDs.)\n";
	print "\t-php *(outputs php instead of html)\n";
	print "* indicates working.\n";
}
	

# check which option they picked

if (@ARGV[0] =~ /\-normal/i){
	html_header();
	normal(1,1,1);
	print "does this work?";
	end_file();
	}
elsif (@ARGV[0] =~ /\-sorted/i){
	@objectnames =  sort @objectnames;
	html_header();
	normal(1,1,1);
	end_file();
	}
elsif (@ARGV[0] =~ /\-provided_only/i){
	@objectnames = sort @objectnames;
	html_header();
	normal(1,0,1);
	end_file();
	}
elsif (@ARGV[0] =~ /\-required_only/i){
	@objectnames = sort @objectnames;
	html_header();
	normal(0,1,1);
	end_file();
	}
elsif (@ARGV[0] =~ /\-cell_name_only/i){
	@objectnames = sort @objectnames;
	html_header();
	normal(0,0,0);
	end_file();
	}
elsif (@ARGV[0] =~ /\-strip_FID_CID/i){
	@objectnames = sort @objectnames;
	html_header();
	normal (1,1,0);
	end_file();
	}

elsif (@ARGV[0] =~ /\-php/i){
	close(HTML);
	open(PHP, "> functions.php");
	select(PHP);
	@objectnames = sort @objectnames;
	php();
	close(PHP);
	select(STDOUT);
	print "PHP file created as functions.php, simply put both function.php and index.php in same dir, read index.php to see function listings.\n";
	}

#print "@objectnames";


sub template(){
foreach $name (@objectnames){
	print "\n$name\n\n";
	$reference="$name$prov";
	$reference2="$name$requ";
	$var= $objects{$reference};
	$var2= $objects{$reference2};
	foreach $provfunc (@$var) {
		$testvar="$provfunc";
		@provinfo = split(/ /, $testvar);
		print "\t@provinfo\n";
	}
	foreach $reqfunc (@$var2) {
		@reqinfo = split(/ /, $reqfunc);
		print "\t@reqinfo\n";
		}
	}
}

sub normal($,$,$){
	my @option = @_;
foreach $name (@objectnames){
        #print "\n$name\n\n";
	print "<tr><td width='100%'><br><br> <b><i>&nbsp;&nbsp;&nbsp;&nbsp; $name </i></b><br></td></tr>\n";
	$reference="$name$prov";
        $reference2="$name$requ";
        $var= $objects{$reference};
        $var2= $objects{$reference2};
        @$var = sort @$var;
	@$var2 = sort @$var2;
	if (@option[0] == 1) {
	foreach $provfunc (@$var) {
                $testvar="$provfunc";
                @funcinfo = split(/ /, $testvar);
                print "<tr><td width='20%'><b>Provided:</b></td>\n";
		print "<td width='20%'>@funcinfo[0]</td>\n";
                print "<td width='20%'>@funcinfo[1]</td>\n";
		if (@option[2] == 1){  #are we printing FID/CID?
                	print "<td width='20%'>@funcinfo[2]</td>\n";
                	print "<td width='20%'>@funcinfo[3]</td>\n";
			}
		print "</tr>\n";
		}
	}
	if (@option[1] == 1) {
	foreach $reqfunc (@$var2) {
		$testvar = "$reqfunc";
		@funcinfo = split(/ /, $testvar);
		print "<tr><td width='20%'><b>Required:</b></td>\n";
		print "<td width='20%'>@funcinfo[0]</td>\n";
                print "<td width='20%'>@funcinfo[1]</td>\n";
		if (@option[2] == 1){ #we printing FID/CID?
			print "<td width='20%'>@funcinfo[2]</td>\n";
               		print "<td width='20%'>@funcinfo[3]</td>\n";
			}
		print "</tr>\n";
	
		}
	}
        }
}


sub php(){
print "<?\n";
foreach $name (@objectnames){
        print qq| startCell("$name");\n|;
        $reference="$name$prov";
        $reference2="$name$requ";
        $var= $objects{$reference};
        $var2= $objects{$reference2};
        @$var = sort @$var;
        @$var2 = sort @$var2;
        foreach $provfunc (@$var) {
                $testvar="$provfunc";
                @funcinfo = split(/ /, $testvar);
                print qq| providedFunction( "@funcinfo[0]", "@funcinfo[1]", @funcinfo[2], @funcinfo[3] );\n |;
		}
        foreach $reqfunc (@$var2) {
                #next if( !defined($reqfunc) );
                $testvar = "$reqfunc";
                @funcinfo = split(/ /, $testvar);
                #print "\t$reqfunc\n";
		print qq| requiredFunction( "@funcinfo[0]", "@funcinfo[1]", @funcinfo[2], @funcinfo[3] );\n |;
                }
        print "endCell();\n";
	}
print "?>\n";						
}
																			

sub html_header(){
	select(HTML);
	print "<html><body bgcolor='black' text='white'><title>Required and Provided Functions</title>";
	print "<table width='640'>";
	print "<td width='20%'><b>Required/Provided</b></td>\n <td width='20%'><b>Function</b></td> \n <td width ='20%'><b>Class</b></td><td width='20%'><b>FID</b></td> \n <td width='20%'><b>CID</b></td>\n";
	}

sub end_file(){
print "</table>";
print "</body></html>";
close(HTML);
select(STDOUT);
print "Func2HTML (c) 2001 Richard Fillion\n\n";
}


