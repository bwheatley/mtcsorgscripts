#!/usr/bin/perl -w
#
##########################################################
# Goals of this file:
# Test for common problems with (gs) Grid-Service accounts
#
#
#Use FTP authentication to confirm identity in order to run script via CGI.

#check for db logins
#check ssh
#beancounters
#check db external access privs (maybe only dv)
#parse ftp fail for simultaneous connections
#check for SSL errors in web
#validate ssl (maybe)
#check sftp subsystem
#
#
# Testing for:
# PHP modifications
# DNS pointed correctly
#
# Planned testing for:
# Mail sending on all accounts
# Mail delivered on all accounts
# 
#Creating and configuring:
#Symlinks for domains
#php.ini
#
#Doing Stuff:
#allow easy use of find command
#
#Written by Mike H
#Big thanks to Nat, John(shiftops), Anthony, and Rob C.

##########################################################
use strict; 
use lib "lib";
use Getopt::Long;
use File::Find;
use Switch;
use IO::Socket::INET;
use IO::Select;
use Net::SMTP::SSL;
use Net::SMTP;
use Net::FTP;
use Cwd qw(abs_path);
use DBI;
use Socket 'inet_ntoa';
use Sys::Hostname 'hostname';
use Term::ANSIColor;
use MIME::Base64;
use sigtrap 'handler' => \&IntHandler, 'INT';
#use CGI::Carp qw(fatalsToBrowser);
#use Regexp::Common;

our $serviceType; #dv or gs
our $cluster;
our $herd;
our $vz;
my $file = "~/";
my $pwd = "";
my $checkPHP;
our $dir;
my $checkMail;
my $help = "";
my $access; #access domain
my $accessDom = "";
my $accessIP = "";
our @digIt; #results of dig to test for CNAME
our $host;
our $dvAddr;
my @recordIs;
my @domainsHosted;
my @domainsBadDNS;
my @domainsGoodDNS;
my $mailConnect = "";
my $phpChanged = "";
our $exists; #checks if the registraation exists
my $checkDNS = "";
my $dnsChecked = 0;
my $siteId = "";
@main::makeLink = ();
our $matchUser; #regexen for finding the username in a cms db conf
our $matchPass; #regexen for the password
our $matchDB;
our $matchHost; #regexen for grabbing the hostname they're using
our $searchLine; #what to generally use to find the file with them
my $dbUser = "";
my $dbPass = "";
our %db = ();
$db{'pass'} = "";
our $db_ref;
our $results; #results from the db
our $dbc = ""; #database connection
our $dbError;
our $userHasAccess = "0"; #if 1, the db in their cms conf file was found when listing databases.
our $cms; #if using gs, the type of cms so I can find the configuration file for fast testing
our $cmsConfName; #name of the configuration file generally used by the CMS
our $confSearch; #thing to search for to get the db log in information
our @confs;
our @confMatches;
my @folders;
my $sentTime = "";
our %email = ();
$main::linkDir = "";
our $domain = "";
our $type; #type of DNS search to run
our $record; #results of dns check
our $whoisSearch;
our $grep;
our $mailStatus = "";
our %ftpLogin = ();
our $ftperror;
our $error; #just plan old error messages
our $db_query; #query against psa db
our @results;
our $rsa = '-----BEGIN RSA PRIVATE KEY-----
MIIEoQIBAAKCAQEAwsGSY12ce0eqg1EqR8sPYwUlmtQCjJutw5kvtPDm8M+ThVFk
gQy8FVfL0aGZfX9edDilUdpbSU8/1p6SrdwyWUE//SasD6Fl5aVx949/4abyAodn
fBZ4tVJ+5bN6F9pCbpdVO2h79ndSydyTIP6HYUdv4aIbOwtwqrOwF89wSam5PhIW
e0hUHsvW9RsHlNBQB8YZESAJfvpC931qFOu2NGZzaz0YiLBsvcCR/Vz46SA9ZcPE
qXEAbxbPZ3j+EJBU/NL4tVTGCB0N7H0RlGxeeI65dVk8DkIf6yw/nTgj0hsw9JAw
5jzW2UNU0HbtprCrAnVay/14gdOD0qnzYKBH8QIBIwKCAQEAvTER3N6YArqlpCL1
31eLSj+DnbgCefZRBycYZqDgV6US9omU1SJQTz9YR/wRcpj8q2o6MkHVBWLtjqir
vtXnxGtFeZNIDy8Sh1BC0zrxQZrcd3w4pG2Z1LaJ5nPVsMVlGvlovV4vRzIV6Kpj
ChvT+BmCoKwac986P2y5sLriG6p8s34z8FkRYAa1Wi7+6g8ALlfO50tIOSqLe9SD
Rl3Ud/Cn+LSwlxBCIBzTqUHu2BnpvYmabkmj6LHLuCllZXzy1sy24Ju3dKiK5272
KCP3qKfypUsFFvVXemHHrRHYPP3N5+/Xq1I3P2mk54fAnO9fjkg/2ktGhSyn1Kas
KhMhKwKBgQD0a0zW1VN5v+aXrG4iyKwHmoT9jFsPd/rcv4sCnhLj/o2IsYuC5l4A
masba26WyLOY1dFQCHlV7kLXn6HtkvKf74TLWm10rQDOOWIB8SAaGlhs4eHtcjcH
7FpGlfQjMm9Rh0k2jFY8+knvXeEX2y98PGaQsB1jMBcJIU94s1rODQKBgQDL++Fz
l/OEuEfA1UBHzCPmW6p7PFHVU630wAENgTv/Bax6DH8cFd/Nt7uNn+5GnFH3tj8o
errrL2g8qGEoHKwke3txGVYUgSN0eZI/ausBqRDw6U+6T7Qu4rica7GiBoh8Z+4y
7U4z0mb/dS+8sXu10bVbM6GnE/Bkg5/YgfWMdQKBgA33gLvRrP+kkNV3kUPQ8+Mt
Zq9nGyV0kf38URYXqU7bWIt33BYbytt2fs5d6Q/uNiX9lu6hZgTpCyJDotpgKx8V
AEYibKeU23l/nzNPm280tJiB76crGRZlRvy4HJRMBlxuIXDU0bpXcfBrw7g4aR0K
xAhEk/cKD/HkpXSciNiTAoGAaOfwShOhzzozh74hDvtFqat8P2DZoOk05EV84l+4
dIaTN3QkHRKQWytKg1mQfBXhAw1FDYDyalLlJoJ7G/F9GhOeke/F3qjQZ8l+acH1
NA3OMsEhsEY/aJHbSSFxTANcIrkbaqXttEBSOjxEb6u79xtklU3A2ZU5zUsBv83O
vUMCgYBJijPaHdu+LUmosekQHEneeSM+LhV3zSWYkGPKlHKbUoxIJydWah4VCKq2
wSf32ROfPz6DH+U6esF99f1rzd0r37noE0YRMK6VvLytsBBcRC14Yap0bv2k0vcR
N89ZrwOjtutHE8XxwgQn1+3+OLEDukqpO2SGcZfyG3h3wU/Kiw==
-----END RSA PRIVATE KEY-----';
our $rsa_pub = q|ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAwsGSY12ce0eqg1EqR8sPYwUlmt
	QCjJutw5kvtPDm8M+ThVFkgQy8FVfL0aGZfX9edDilUdpbSU8/1p6SrdwyWUE//SasD6Fl5aVx949/
	4abyAodnfBZ4tVJ+5bN6F9pCbpdVO2h79ndSydyTIP6HYUdv4aIbOwtwqrOwF89wSam5PhIWe0hUHs
	vW9RsHlNBQB8YZESAJfvpC931qFOu2NGZzaz0YiLBsvcCR/Vz46SA9ZcPEqXEAbxbPZ3j+EJBU/NL4
	tVTGCB0N7H0RlGxeeI65dVk8DkIf6yw/nTgj0hsw9JAw5jzW2UNU0HbtprCrAnVay/14gdOD0qnzYK
	BH8Q== whoistool| . "\n";

##Don't let users ctrl-c out!
my $interrupted = 0;
#$SIG{'INT'} = 
$SIG{'INT'} = 'IGNORE';
#sub IntHandler {
	#exit;
#	$interrupted++;
#	print color 'bold underline';
#	print "\n\nSorry, I have to prevent you from exiting that way. Please exit ";
#		print "through the menu.\n\n"; 
#		print color 'reset'; 
#	&menu;
#}

#runIt();
GetOptions (
	'help!' => \$help , 
	'checkPHP!' => \$checkPHP ,
	'checkMail!' => \$checkMail, 
	'checkDNS!' => \$checkDNS , 
	'makeLink=s%' => \%main::makeLink, 	
	'finder=s' => \$cmsConfName
);


######################
#Run
######################
#runFromCGI();

#$help = 1 if (!$checkDNS && !$checkPHP && !$checkMail && !$main::finder && !$main::makeLink{'to'} && !$main::makeLink{'from'});
#print end_html;
if ($help) {
	print "This script is intended to allow the easy access of functions that ";
		print "would normally require use of the command line.\n\n";
	print "The current options for this script are:\n";
	print "\t --checkDNS \t This determines if the domains hosted on your account";
		print " have DNS records.\n";
	print "\t --checkPHP \t This shows whether you are using the default ";
		print "php.ini.\n";
	print "\t --checkMail\t Checks mailserver connections over POP, IMAP, and ";
		print "SMTP.\n";
	print "\t --makeLink \t Create symlinks. Should be in the form of --makelink";
		print " from= --makelink to=\n";
	print "\t --finder \t Easy file searching. Enter this option, then the name";
		print " of the file you want to search for. Regexen characters such as ";
		print "\$ and \^ can be included by enclosing your search string in quotes\n";
#die print "Please run this with an option\n";
}

#print "Please run this with an option. A list of available options can be found using --help"; 

sub runIt{
	if ($checkDNS) {
		&checkDNS;
	}
	if ($checkPHP) {
		checkPHP();
	}
	if ($checkMail) {
		checkMailServers();
	}
	if (exists $main::makeLink{'to'} && exists $main::makeLink{'from'}) {
		createSymlink();
	}
	if ($cmsConfName ne "") {
		confFind();
	}
}
#####################
#Menu
####################
our $homeDir;
if (-e '/opt/mt/etc/roles') {
	$serviceType = "gs"; 
	&whatAccessDomain; 
	$homeDir = "~/domains/"; 
	&getCluster;
} else {
	$serviceType = "dv"; 
	&getDvIp; 
	$host = $dvAddr; 
	$homeDir = "/var/www/vhosts$domain"; 
	&getVZ; 
	&checkDiskSpace;
}
print "This script will assist you in diagnosing issues on the ";
	print "($serviceType)\n";
&menu;
&runagain;
sub runagain {
	print color 'reset';
	print "That was awesome; want to do that again? [y/n]\n";
	my $awesomeness = <STDIN>;
	if ($awesomeness =~ /y/) {
		&menu;
		&runagain;
	}
	#else {die;}
}
sub menu {
	print color 'reset';
	print "The problem is with:\n 1. One domain\n 2. All domains on the service\n";
	if ($serviceType eq "dv") {
		print " 3. Plesk\n";
	} 
	print " 0. Exit\n";
	my $howMany = <STDIN>; 
	chomp $howMany;
	switch ($howMany) {
		case "1" {
			print "What domain is having trouble? ";
			if ($serviceType eq "gs") {
				print "If this is for an email problem,"; 
				print "and the address is\nset to \@(all domains), please use the";
				print " acccess domain:\n ";
			}
			if ($domain ne "") {
				print "If you'd like to use $domain again, press enter.\n";
			}
			my $trouble = <STDIN>; 
			if ($trouble ne "\n"){
				chomp($trouble);
				$domain = $trouble;
			} else {
				if ($domain eq "") {
					print "You didn't enter a domain. ";
					&menu;
				}
			}
			$type = ''; 
			&checkDNS($type, $domain);
			$record = 0 unless defined $record;
			if ($record eq "0"){
				print color 'bold underline';
				print "\nThat domain doesn't have an A record listed for it. Fatality!\n";
				$whoisSearch = $domain;
				print "whois search = $whoisSearch";
				$type = 'NS';
				&checkDNS($type, $domain);
				&whois($whoisSearch, $grep);
				if ($recordIs[0] !~ m/ns\+d\.mediatemple\.net/ && $recordIs[1] !~ m/ns\+d\.mediatemple\.net/){
					print "That domain isn't pointed to our nameservers. The customer will";
						print " either need to point the domain to:\nns1.mediatemple.net\n";
						print "ns2.mediatemple.net\n\n\tThey can also contact their DNS";
						print " provider to point their root A record, and www A record";
						print "to their IP. That's found by looking at the zone file section ";
						print "of the service page in Hostops.\n";
				}
			}
			print "Looks like it's pointed to the IP $record.\n";
			print color 'bold underline';
			if ($serviceType eq "gs"){
				$record =~ s/(.+)\.$/$1/;
				my $serviceIP = $record;
				$type = "A";
				my $findGSIP = checkDNS($type, $accessDom);
				print "The IP I found was $findGSIP\n";
				if ($findGSIP ne $serviceIP && $digIt[2] ne "CNAME") {
					print "\n\nThat domain is pointed to $serviceIP, but the IP for the"; 
						print "service is $findGSIP. If this user doesn't have an SSL";
						print " certificate and it's not pointed to a CNAME record, there's";
						print " your problem.\n\n";
					print "Do you want to return to the main menu?";
					my $returnToMenu = <STDIN>;
					chomp $returnToMenu;
					if ($returnToMenu =~ /(y|Y)/){
						&menu;
					} else {
						die "I saw a sign on this door; it said, Exit Only. So, I entered it and 
							went up to the guy working there, and I was like, I have some good news. 
							You have severely underestimated this door over here by like, 100%, man. 
							--Demitri Martin";
					}
				}else {
					print "All your DNS are belong to us!\n";
				}
			&checkIfUs($domain);
			} else {
				print "This is record $record, this is dv ip $dvAddr\n\n"; 
				if ($record ne $dvAddr) {
					$db_query = qq|
					SELECT
						name
					FROM
						domains;|;
					plesk_db_query($db_query);
					our $inPlesk = 0;
					foreach (@results) {
						print "$_\n\n";
						if ($_ eq $domain) {
							$inPlesk++;
						}
					}
					if ($inPlesk < 1) {
						print "That domain isn't listed in the Plesk database. Are you sure it's";
							print " hosted on this server?\n";
						&menu;
					} else {
					print "\n\nThat domain doesn't appear to point to the IP address that";
						print " the Plesk database says it should";
					print color 'reset';
					}
					&checkIfUs;
					print "Do you want to return to the main menu?\n";
					my $returnToMenu = <STDIN>;
					chomp $returnToMenu;
					if ($returnToMenu =~ /(y|Y)/){
						&menu;
					} else {
						die "\tI saw a sign on this door; it said, Exit Only. So, I entered it 
							and went up to the guy working there, and I was like, .I have some 
							good news. You have severely underestimated this door over here by, 
							like, 100%, man. --Demitri Martin\n";
					}	
				}
			}
			print "All your DNS are belong to us!\n";
		
	#	}
			
			print color 'reset';
		} case "2" {
			print "Problems with all domains on a service may indicate a suspended";
				print " account.\n";
			if ($serviceType eq "dv") {
				my $apacheRunning = `/etc/init.d/httpd status`;
				if ($apacheRunning !~ m/is running\.\.\./){
					print "The Apache server does not appear to be running. If the user";
						print " was unable to access their sites, this was likely the cause.";
						print " Attempting to restart the web server.\n";
					my $restart = `/etc/init.d/httpd restart`;
					$apacheRunning = `/etc/init.d/httpd status`;
					if ($apacheRunning !~ m/is running\.\.\./){
						print "The Apache server still does not appear to be running. This ";
							print "issue is likely scoped because they've made modifications ";
							print "to the configuration. The actual message when I tried to ";
							print "restart it was $restart\n";
					} else {
						print "Apache seems to be running.\n";
					}
				} else {
					print "Apache seems to be running.\n";
				}
			} else {
				if (-e "/home$pwd/.suspended") {
					print color 'bold underline'; 
					print "This domain has been suspended using a .suspended file. Please ";
						print "consult previous tickets for information on the issue.\n\n";
					print color 'reset'; return
				}
				else {
					print "The domain wasn't suspended using a .suspended file, but may have";
						print " been suspended through HostOps. Please check there.";
				}
				$domain = $accessDom;
				print "\n\nTests will be run using the access domain $accessDom.\n";
				print color 'bold underline';
				print "Please check for an incident on cl$cluster.h$herd.\n\n\n";
				print color 'reset';
			}
		} case "3" {
			if ($serviceType eq "gs") {
				print "\nDon't try to get tricky now, it doesn't suit you.\n\n"; 
				&menu;
			}
			die qq|	Please check the QoS alerts for this server. Those are outside the
				 	scope of our support, but information can be found here:\n 
					http://wiki.mediatemple.net/w/(dv):Use_QoS_Alerts_and_beancounters
					_to_analyze_system_resource_limits\n|;
		} case "0" {
			die "Well then, good day to you!\n"
		} case "" {
			print "You really need to give me some information for this to work\n"; 
			&menu;
		} else {
			print "\nDon't try to get tricky now, it doesn't suit you.\n"; 
			&menu;
		}
	}
	switch ($serviceType) {
		case "gs" {
			$homeDir = "domains/$domain/html/";
		} case "dv" {
			$homeDir = "/var/www/vhosts/$domain/httpdocs/";
		}
	}
	print "Please enter the number that corresponds with the menu option.\nThe";
		print " problem is with:\n 1. Web\n 2. Databases\n 3. Email\n 4. FTP\n ";
		print "5. Multiple Services\n 0. Exit\n";
	my $problem = "0"; 
	$problem = <STDIN>;
	if ($problem eq "\n") {
		print color 'bold'; 
		print "Don't give up. Please try again. A message of inspiration from ";
			print "your friends at Yoplait. --Hedberg\n"; 
		print color 'reset';
	}
	chomp $problem;
	switch ($problem) {
		case "1" { 
			print "The website is:\n 1. Inaccessible\n 2. Slow\n 3. Displaying an error\n"; 
			if ($serviceType eq "dv") {
				print " 4. Displaying a Plesk default page\n 5. Displaying a CentOS default page\n";
			}
			my $siteerror = <STDIN>; chomp $siteerror;
			switch ($siteerror){
				case "1" {
					my $testPage = "<html>\n<body>\n(mt) Test!\n</body>\n</html>";
					my $testFile = $homeDir . "mt-test.html";
					print "\n\ndomain is $domain \n\n";
					unless (-e "$testFile"){
						open (TESTHTTP, '>', $testFile) or die "Couldn't create $testFile";
						print TESTHTTP $testPage;
						close TESTHTTP;
					} else {
						print "\nIt looks like the file $testFile already exists. I can't run this next test here. ";
					}
					my $isItUp = `curl -s $domain/mt-test.html`;
					chomp $isItUp;
					if ($isItUp ne $testPage) {
						print color 'bold underline';
						print "I created a test page, but wasn't able to find it at $domain/mt-test.html \n"; 
						print color 'reset';
					} else {
						print "I was able to write a test file for that domain at $testFile, and ";
							print "was able to access it. \nIf you're not able to view the page, ";
							print "this likely indicates a problem with the coding for their site.";
							print "\nOtherwise, please have the customer load the site through a ";
							print "proxy. \nIf they can view the site through a proxy, they'll ";
							print "need to contact their ISP. \nIf they still can't view the page ";
							print "through a proxy, please have them provide the error message ";
							print "they receive and the results of a traceroute, and escalate ";
							print "this to ts.\nThere are instructions on running a traceroute ";
							print "here:\nhttp://kb.mediatemple.net/questions/736/Using+the+traceroute+command \n\n";
					}
					unlink $testFile;
				} case "2" {
					print "Is the site slow for you? [y/n]\n"; 
					my $slow = <STDIN>; 
					chomp $slow;
					switch ($slow) {
						case m/y/i {
							print "Please run a site speed test, such as at";
								print " http://tools.pingdom.com/fpt\nIf there are a lot of";
								print " externally loaded objects, that can definitely cause ";
								print "site slowness, since the site loading is dependent on the site";
								print " they're pulling content from.\n\nIf the first or second bar";
								print " has a large green line, it indicates that the site is loading";
								print " slowly when retrieving their data, likely from their";
								print " database. That can be caused by inefficient MySQL queries. If";
								print " they're running a CMS (WordPress, Joomla, Drupal, etc) have ";
								print "them disable all themes and plugins. If that doesn't correct ";
								print "the issue, please escalate.";
						} case m/n/i {
							print "Please have the customer provide the results of a traceroute:\n ";
							print "http://wiki.mediatemple.net/w/(gs):Using_traceroute\n";
						} else {
							print "y or n only please.\n"; 
							return;
						}
					}
				} case "3" {
					print "Is the error:\n 1. 403 Forbidden\n 2. 404 File not found\n 3. 500";
					print " Internal Server error\n 4. 502 Bad Gateway\n"; 
					local $error = <STDIN>; 
					chomp $error;
					switch ($error) {
						case "1" {
							unless (-e "$homeDir/index.html" || "$homeDir/index.php") {
								print "It doesn't look like there's an index file present in their";
									print "document root directory $homeDir. A forbidden error is";
									print " received because directory listings are disabled by default. ";
									print "Make sure that there is an index file in their html directory";
									print ", or any subdirectory they're trying to access directly.\n";
							} else {
								our $perm = `stat $homeDir | grep "Access"`;
								if ($perm =~ /Access: \((\d)(\d)(\d)(\d)\//) {
									$perm = "$1$2$3$4";
									my $s = $1;
									my $u = $2;
									my $g = $3;
									my $w = $4;
									print "It looks like there's an index file there. The permissions ";
										print "for the directory are $perm.\n";
									if ($u < "5") {
										print "It appears that the user permission may be incorrect. ";
									}
									if ($g < "5") {
										print "it appears that the group permission may be incorrect. ";
									} 
								}
							}
						} case "2" {
							print "The particular file they're trying to access does not exist. ";
								print "Linux is case sensitive, so if the casing for the file name is ";
								print "not exactly as the file exists, this error will be displayed.\n";
						} case "3" {
							print "There are errors, most likely with the script. Error logs are ";
								print "helpful in determining the cause of these.\n";
							if ($serviceType eq "gs") {
								print "Make sure that's enabled for the customer.\n ";
									print q|http://kb.mediatemple.net/questions/732/How+can+I+find+the+
										access_log+and+error_log+files+for+my+%28gs%29+Grid-Service%3F#gs|;
							}
							if ($serviceType eq "dv") {
								print q|Those can be found in /var/www/vhosts/$domain/statistics/
									logs/error_log\n|;
							}
						} case "4" {
							print "This can occur when there's a problem connecting to a container.";
								print " The container may need to be restarted.\n";
						} else {
							print "That wasn't a valid option.\n";
						}
					}
				} case "4" {
					if ($serviceType eq "gs") {
						print "\nDon't try to get tricky now, it doesn't suit you.\n"; 
						&menu;
					}
					our $pleskIP;
					$db_query = qq|
						SELECT
							name,ip_address from domains
						JOIN
							hosting on domains.id=hosting.dom_id 
						JOIN
							IP_Addresses on IP_Addresses.id=hosting.ip_address_id
						WHERE
							name=\'$domain\';|;
					plesk_db_query($db_query);
					local @results;
					foreach (@$db_ref) {
											
						chomp $_;
						push (@results, $_);
					}
					$pleskIP = "0" unless defined $results[0];	
					if ($pleskIP ne "0") {
						$pleskIP = $results[1];
					}
					if ($pleskIP ne $record) {
						print "\nIt appears the IP address that has been set in Plesk doesn't ";
							print "match the IP that the DNS record for that domain is pointing ";
							print "to. That causes the problem you indicated.\n";
					} else {
						print "Please escalate this issue. Normally this is caused by the ";
							print "domain being pointed to a different IP than Plesk is using, ";
							print "but Plesk is using $pleskIP, and the domain is pointing to ";
							print "$record.\n";	
					}
				} case "5" {
					unless (-e "$homeDir/index.html" || "$homeDir/index.php"){ 
						print "They don't appear to have an index file.\n";
					}
					print "That problem typically occurs when there's a misconfiguration of ";
						print "the server. What did they do?";
				} else {
					print "\nNo dice, try again.\n";
				}
			}
				
			#case "2" {print "If there is no ongoing system incident that would cause this, the service may be suspended. A billing suspension would occur in Hostops. An abuse suspension on the (gs) Grid-Service would have a file called .suspended in their directory.\n";}
			
		} case "2" {
			print "The error is seen with:\n 1. Their site\n 2. phpMyAdmin\n"; 
			local $error = <STDIN>; 
			chomp $error;
			switch ($error) {
				case "1"	{
					print "If you know the location of the configuration file, please ";
						print "enter it. Otherwise, press return.";
					my $config = <STDIN>;
					if ($config eq "\n"){
						print "This will eventually search for configuration files.\n";
					}
					print "This will grab the log in info. Once I have that, I can log ";
						print "in to their database and parse any errors when connecting.\n";
					if ($serviceType eq "dv") {
						$host = 'localhost';
						$db_query = qq|
							SELECT
								domains.name AS domain_name,data_bases.name 
							AS 
								database_name, db_users.login, accounts.password 
							FROM
								data_bases, db_users, domains, accounts 
							WHERE
								domains.name = \'$domain\' AND data_bases.dom_id = domains.id 
								AND db_users.db_id = data_bases.id AND db_users.account_id = accounts.id
							ORDER BY 
								domain_name;|;	
						plesk_db_query($db_query);
						#unless ($db{'user'} eq "admin"){
						$db{'user'} = $results[2];
						$db{'pass'} = $results[3];
						print "Checking the psa db for log in info:\n";
						#}
					#else {return "It appears that the domain doesn't have a database set up in Plesk. This can definitely cause some problems.\n";}
					} else {
						print "If the site using CMS software like WordPress or Joomla, please ";
							print "indicate which.\n 1. Wordpress\n 2. Joomla\n 3. Drupal\n 4. ";
							print "ZenCart\n 5. Expression Engine\n 6. other:\n";
						$cms = <STDIN>;
						chomp $cms;
						our $searchLine;
						switch ($cms) {
							case 1 {
								$cms = "WordPress";
								$cmsConfName = "wp-config.php";
								$confSearch = 'define\(\'DB_';
								#$matchUser = "define\('DB_USER',\ \'(.+)\'";
								#$matchPass = "define\('DB_PASSWORD',\ \'(.+)\'";
								&confFind;
								grabDBConf($matchUser, $matchPass, $confSearch);
							} case 2 {
								$cms = "Joomla";
								$cmsConfName = "configuration.php";
								$confSearch = 'var $';
								&confFind;
								grabDBConf($matchUser, $matchPass, $confSearch);
							} case 3 {
								$cms = "Drupal";
								$cmsConfName = "settings.php";
								$confSearch = '\$db_url = \'mysql:';
								&confFind;
								grabDBConf($matchUser, $matchPass, $confSearch);
							} case 4 {
								$cms = "ZenCart";
								$cmsConfName = "configure.php";
								$confSearch = 'define\(\'DB_';
							} case 5 {
								$cms = "EE";
								$cmsConfName = "database.php";
								$confSearch = '\$db\[\'expressionengine\'\]';
							} case 6 {
								$cms = "custom software";
							} else {
								print "Huh? I didn't see that as an option"; 
								return;
							}
						}
					}
					#if ($db{'pass'} =~ m/.{6,}/) {
					print "Running checkdb\n\n";
					&checkDb($db{'user'}, $db{'pass'});
					#}
					#else {print color 'bold underline'; print "I wasn't able to find a password in the database configuration file.\n"; print color 'reset';}	
				} case "2" {
					if ($serviceType eq "gs") {
						unless (-d '~/data/tmp') {
							print color 'bold underline';
							print "It appears that the directory ~/data/tmp has been deleted. ";
							print "That will prevent phpMyAdmin from working properly.";
							print color 'reset';
						}
					} 
					print "phpMyAdmin error messages are generally reliable. If you're not ";
						print "able to get to phpMyAdmin at all, even when using the access ";
						print "domain, check to make sure the symbolic link from the access ";
						print "domain to the primary domain exists in their domains folder. ";
						print "If you receive an authentication error when you believe the log ";
						print "in information is correct, clear your cache and refresh the ";
						print "page. You may have cached the error page. That can be done by ";
						print "holding down the shift key when refreshing the page.\n\n If the ";
						print "error is regarding max connections, it is likely the site is ";
						print "getting either too much traffic, or more likely, that it isn't";
						print " using database connections efficiently. Database connections ";
						print "should be closed as soon as the data is received.\n\n If the ";
						print "error is \'#2013 - Lost connection to MySQL server at 'reading";
						print " initial communication packet\'\', it will require the attention";
						print " of an administrator. Determine the database server they're ";
						print "using, then look under Monitors/Reports/Logs for the Grid ";
						print "Monitoring section. Select the live monitoring for the ";
						print "appropriate cluster, and click on the MySQL graph. Look for ";
						print "the database server on the next page. If there appears to be ";
						print "latency, include that in your notes, as well as in your admin ";
						print "chat alert (AFTER you have a support request number to provide ";
						print "admins)\n";
				} else {
					print "\nNot a valid option\n";
				}
			}
		} case "3" {
			our $user;		
			print "Please let me know which email address is having problems. If it's ";
			print "many email accounts, please provide one. If you already entered the";
			print " domain, you can leave it off here:\n ";
			$email{'user'} = <STDIN>;
			if ($email{'user'} ne "\n") {
				chomp $email{'user'};
				if ($email{'user'} =~ m/(\w+)@/) {
					$user = $1;
				} else {
					$user = $email{'user'};
				}
			} else {
				print "You haven't entered an email user\n";
				return;
			}
			if ($serviceType ne "dv"){
				unless (-d &pwd."../".$user."%".$domain or -d &pwd."../".$user) {
					print "email user = $email{'user'}";	
						print color 'bold underline';
						print "That email user doesn\'t appear to exist. If you\'re testing an ";
						print "email alias, that\'s fine. Otherwise, that\'s likely to cause ";
						print "some problems. This script can\'t test aliases at the moment.\n";
						print color 'reset';
					return;
				}
				print "You're gonna need to change their email password in the ";
					print "AccountCenter, then enter it here:\n ";
				$email{'pass'} = <STDIN>;
				chomp $email{'pass'};
			}
			if ($email{'user'} !~ m/\w+@\w+\.\w{2,}/){
				$email{'user'} = $email{'user'} . "@" . $domain;
			}
			print "There are problems:\n 1. Sending\n 2. Receiving\n 3. Both\n"; 
			local $error = <STDIN>; 
			chomp $error;
			switch ($error){
				case "1" {
					if ($howMany eq "2") {
						if ($serviceType eq "dv"){
							my $smtpUp = `/usr/local/psa/bin/service --status smtp`;
							if ($smtpUp =~ m/is running/){
								print "The outgoing mail server appears to be running. Determine if ";
									print "port 25 is blocked for the customer.\n";
									print qq|http://wiki.mediatemple.net/w/(gs):Port_25_test_and_
										troubleshooting\nhttp://wiki.mediatemple.net/w/(dv):Port_25_test_and_
										troubleshooting\n\nIf port 25 is not blocked, make sure they have 
										authentication enabled in their email client:\n
										http://wiki.mediatemple.net/w/Category:Email_setup\n\n If you 
										believe the SMTP server may need to be restarted, I can handle that. 
										Would you like it restarted?\n|;
								my $restartMail = <STDIN>;
								chomp $restartMail;
								switch ($restartMail){
									case m/y/ {
									`/usr/local/psa/bin/service --restart smtp`; 
									print "The SMTP server has been restarted.\n";
									}
								}
							}
						}
					} else {
						&sendTestMail;
						print "Determine if port 25 is blocked for the customer.\n";
							print "http://wiki.mediatemple.net/w/(gs):Port_25_test_and_troubleshooting\n";
							print qq|http://wiki.mediatemple.net/w/(dv):Port_25_test_
									and_troubleshooting\n\n|;
							print "If port 25 is not blocked, make sure they have authentication ";
							print q|enabled in their email client:\nhttp://wiki.mediatemple.net/w/
									Category:Email_setup\n\n|;
					}
				} case "2" {
					&checkMailServers;
					if ($serviceType eq "gs"){
						print "Make sure incoming mail is enabled on their server.\n";
							print "http://wiki.mediatemple.net/w/(gs):Enable_or_disable_email\n";
							print "http://wiki.mediatemple.net/w/(dv):Enable_or_disable_local_mail";
							print "\n\nIf webmail won't load completely either, there may be too ";
							print "many emails in the account. That can be tested by logging in ";
							print "to the email account via SSH and running: cd Maildir/cur; ";
							print "ls -lsha | wc -l\n If the number listed is greater than 5000, ";
							print "the user may want to remove some email from the account.\n";
					} else { 
						if ($record ne $dvAddr) {
							print "It doesn't look like the MX record is pointed to us. If ";
								print "they're hosting mail elsewhere, mail should be disabled for ";
								print "the domain. Would you like me to turn mail off for you now?\n";
							our $mailStatus = <STDIN>;
							chomp $mailStatus;
							switch ($mailStatus){
								case m/y/ {
									`/usr/local/psa/bin/mail --off $domain`; 
									print "\nMail should be disabled now.\n";
								} case m/n/ {
									print color 'bold underline'; 
									print "If mail is hosted elsewhere, and mail is enabled, mail sent ";
										print "from this server will not reach the third-party host. This ";
										print "is because when email is enabled, the server won't waste ";
										print "resources trying to send mail out, when mail should be sent ";
										print "to the account directly on this server. Disabling mail ";
										print "should allow the server to send elsewhere.\n"; 
								}
								print color 'reset';
							}
						} else {
							print "It looks like mail is pointed to this server.";
							my $imapUp = `/usr/local/psa/bin/service --status mail`;
							if ($imapUp =~ m/is running/){
								print "It appears that the IMAP service is running. ";
									print "You'll want to make sure mail is enabled for that domain. I ";
									print "can do that for you. Would you like me to enable mail for this ";
									print "domain?\n";
								$mailStatus = <STDIN>;
								switch ($mailStatus){
									case m/y/ {
										`/usr/local/psa/bin/mail --on $domain`; 
										print "\nMail should be enabled now.\n";
									} case m/n/ {
										print "If mail is pointed to this domain, but mail is turned off, ";
											print "all mail sent to this domain will bounce back.\n"
									}
								}
							}
						}
					}
				} case "3" {
					print "Do the MX and mail records point to us?\n";
				} else {
					print "\nThat doesn't seem right. Was the option valid?\n";
				}
			}
		} case "4" {
			print "The customer is unable to:\n 1. Connect\n 2. Authenticate\n ";
			print "3. View files after authentication\n 4. Upload files\n"; 
			$ftperror = <STDIN>; 
			chomp $ftperror;
			if ($ftperror =~ m/(1|2|3|4)/) {
				&checkFTP;
				switch ($ftperror){
					case "1" {
						print "Have the customer submit a traceroute. It's likely they're ";
							print "encountering network routing issues.\n";
					} case "2" {
						print "Make sure the username is correct, and have the customer change ";
							print qq|their password.\n http://wiki.mediatemple.net/w/%28gs%29:FTP_
								and_SFTP#Password\n http://wiki.mediatemple.net/w/%28dv%29:FTP_and_
								SFTP#Username_and_password\n|;
					} case "3" {
						print "Make sure passive mode is enabled in their FTP client. Otherwise";
							print " they'll authenticate, but fail to retrieve a listing of files.\n";
					} case "4" {	
						my $perm;
						print "File permissions may be an issue.\n"; 
						$perm = `stat $homeDir | grep "Access: ("`; 
						$perm =~ s/Access: \(\d+{,4}\/(.+)\)//; 
						print "The permissions are $perm\n";
					} else {
						print "That doesn't seem like a valid option\n\n"; 
						&menu
					}
				}
			} else {
				print "\nThat option doesn't live here anymore\n\n";
			}
		} case "5" {
			print color 'bold underline';
			print "\n\nPlease check for an incident on ";
			if ($serviceType eq "dv"){
				print $vz;
				} else {
					print "cl$cluster.h$herd";
				}
				print color 'reset'; 
				print "\n\n";
		} case "0" {
			die "Goodnight Everybody!\n"
		} else {
			print "Try that again. I don't think the choice was valid.\n";
		}
	}
}
######################
#Subs
######################

sub getVZ {
$vz = `traceroute 8.8.8.8 | head -n 2 | tail -n 1| awk '{print \$2}'`;
}

sub getCluster{
	&pwd;
	if ($pwd =~ s/\/nfs\/c(\d+)\/h(\d+)\/mnt//){
		$cluster = $1;
		$herd = $2;
	#print "Cluster is $cluster and herd is $herd\n";
	}
}

sub checkDiskSpace {
	my @df = `df | awk '{print \$5}'`;
	chomp $df[1];
	$df[1] =~ s/(\d{1,3})%/$1/;
	if ($df[1] > 93 && $df[1] < 98) {
		print "This server is almost out of disk space.\nIt is using $df[1]%. The ";
			print "customer will want to resolve their disk space issues soon:\n ";
			print "http://wiki.mediatemple.net/w/%28dv%29:Resolve_out_of_disk_";
			print "space_errors\n\n";
	}
	elsif ($df[1] > 98) {
		print color 'bold underline';
		print "This server is at $df[1]% disk space usage. This is critical and ";
			print "must be corrected immediately, or the server may stop functioning ";
			print "properly. http://wiki.mediatemple.net/w/%28dv%29:Resolve_out_of_";
			print "disk_space_errors\n\n";
		print color 'reset';
	}
}


#pull the current working directory.
sub pwd {
#$pwd = getcwd();
$pwd = abs_path($ENV{'PWD'});
if ($pwd =~ m/\/home(.*?)\.home/) {
	$main::linkDir = "/home" . $1 . "home/domains/";
	}
if ($pwd =~ m/\/nfs(.*?)domains/) {
	$main::linkDir = "/nfs" . $1 . "domains/";
	}
	return $main::linkDir;
}
#determine domains hosted by checking the folders in ~/domains. Then takes each and checks to make sure it's at least dom.tld.
sub checkDomainsFromFolders {
	my @domainsListed = `ls ~/domains | tr '/' '\n'`;
	chomp (@domainsListed);
	foreach (@domainsListed){
		if ($_ =~ m/([a-zA-Z0-9]+)(\.[a-zA-Z0-9]{2,})+/) {
			push (@main::domainsHosted, $_);
		}
	}
}

#list all the domains deteremined by folders.
sub listDomainsFromFolders {
	print "This account has these folders that look like domains in the domains ";
		print "folder:\n";
	foreach (@main::domainsHosted) {
		print "$_ \n";
	}	
}
	
#check if php.ini has been changed by determining if it exists in the etc folder..
sub checkPHP {
	print "### PHP ###\n";
	if (-e "../../../etc/php.ini") {
		print "Your php.ini has been changed.\n Customized php configurations are ";
			print "outside the scope of (mt) Media Temple Support.\n";
		$phpChanged = 1;
	} else {
		$phpChanged = 0;
		print "This appears to be a default php.ini configuration.\n"
	}
	print "\n";	
}

sub getAccessDom{
	if ($accessDom =~ m/(^s\d{4,6}\.gridserver\.com)/){
		$accessDom = $1;
		chomp ($accessIP);
		if ($accessDom eq /^s(\d{4,6})/) {
			$siteId = $1;
		}
	}	
}
sub getDvIp {
	my $hostname = hostname();
	$dvAddr = `dig $hostname | grep $hostname | grep -v ';' | awk '{print \$5}'`;
	chomp $dvAddr;
}
#check if A record for sites are working correctly.
sub checkDNS {
	$dnsChecked = 1;
	@recordIs = ("0", "0" , "0") ;
	@digIt = `dig $_[1] | grep $_[1] | awk {'print \$4'}`;
	$digIt[2] = 0 unless defined $digIt[2];
	chomp $digIt[2];
	$whoisSearch = $domain;
	$grep = 'grep -i \'no match\'';	
	if ($digIt[2] =~ m/CNAME.+/) {
		print color 'bold';
		print "\n\nDANGER: it appears that this domain has a CNAME record set up ";
			print "as its root record. That can cause major problems if you didn't ";
			print "enter a sub-domain.\n\n"; 
		print color 'reset'; 
		print "When a CNAME record is used, no other records will work on that ";
			print "domain or sub-domain. That means it won't be able to pick up the ";
			print "NS records, MX records, or any sub-domain records. If the customer ";
			print "is trying to point their domain to a third party, have them add the";
			print " CNAME to the www sub-domain record, then use an .htaccess rewrite ";
			print "to send users from domain.com to www.domain.com.\n ";
			print "http://wiki.mediatemple.net/w/%28gs%29:Rewrite_rules#Add_www_or_https\n"; 
	}
	elsif ($digIt[2] eq "0") {
		print "That domain doesn\'t appear to have DNS records associated.\n"; 
		$whoisSearch =~ m/(\w+)((\.\w{1,4}){1,2})$/;
		&checkRegistered($whoisSearch, $grep); 
		return;
	}
	@recordIs = `dig $type $domain | grep $domain | awk {'print \$5'}`;
	my $morethan2 = @recordIs;
	return $record = "0" unless ($morethan2 > 2);
	chomp (@recordIs);
	shift (@recordIs);
	shift (@recordIs);
	if ($recordIs[0] ne "0"){
		$record = $recordIs[0];
	} else {
		$record = "0"; 
		print "That domain doesn't appear to have any A record set up for it.\n";
	}
	return $record;
}

sub checkIfUs {			
	$whoisSearch = $record;
	$grep = 'grep -v \"#\" | grep -v \'\\[\'\ \ | grep -v \'American Registry 
		for Internet Numbers\' | grep -v \'Level 3\'';
	our @IpOwner = &whois($whoisSearch, $grep);
	foreach (@IpOwner) {
		chomp $_;
		if ($_ !~ m/Media Temple/){
			if ($_ =~ m/\n(.+)\(/) {
				our $owner = $1;
				print " but it doesn't look like that IP is ours. The owner of the ";
					print "network it\'s on appears to be $owner. \n";
				print color 'reset';
				return;
			}
		}
	}
	print "\n";
}
sub whois {
	if ($serviceType eq "dv") {
		$exists = `whois $whoisSearch | $grep`;
	} elsif ($serviceType eq "gs") {
		our @pubfile;
		unless (-d ".ssh") {
			mkdir (".ssh") or die "could not create directory";
		}
		open RSA, ">", '.ssh/rsa.mt' or die "Can't write to file [$!]\n";
		print RSA $rsa;
		close (RSA);
		open RSA_PUB, ">>", '.ssh/id_rsa.pub' or die "Can't write to file [$!]\n";
		print RSA_PUB $rsa_pub;
		close RSA_PUB;
		system('chmod 600 .ssh/rsa.mt');
		$exists = `ssh -q -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null 
			-o StrictHostKeyChecking=no -i ~/.ssh/rsa.mt whoistool\@talesoffail.com 
			whois $whoisSearch | $grep`;
		open RSA_PUB, '.ssh/id_rsa.pub' or die "Can't write to file [$!]\n";
		@pubfile = <RSA_PUB>;
		close RSA_PUB;
		chomp $rsa_pub;
		open RSA_PUB, ">", '.ssh/id_rsa.pub' or die "Cant write to file [$!]\n";
		foreach (@pubfile){
			unless ($_ eq $rsa_pub) {
				print RSA_PUB $_;
			}
		}	
		close RSA_PUB;
		unlink ('.ssh/rsa.mt');
	}
	chomp $exists;
	return $exists;
}
sub checkRegistered {
	print color 'reset';
	$grep = "grep -i \'no match\'";
	&whois($whoisSearch, $grep);
	if ($exists ne "") {
		print color 'bold underline';
		print "That domain hasn't been registered. If you didn't misspell that, ";
			print "odds are that\'s your problem.\n";
		print color 'reset'; die "\n";
	} else {
		&checkIfUs;
	}
}	

sub whatAccessDomain {
	&checkDomainsFromFolders();
	my $foundAccess = 0;
	#Determine access domain and IP.
	foreach (@main::domainsHosted) {
		if ($_ =~ m/^s\d{4,6}\.gridserver\.com/) {
			$accessDom = $_;
			$host = $accessDom;
			$foundAccess = 1;
		#print "and your IP appears to be $accessIP. If your site is using SSL, this may not match.\n\n";
			$siteId = $1 if $accessDom =~ m/^s(\d{4,6})/;
		}	
	}
	if ($foundAccess == 0) {
		print "I couldn't find the access domain. I do that quick and dirty by ";
			print "looking for the symlink, and there's no symlink. If the customer ";
			print "can't get into webmail or phpMyAdmin, a symlink needs to be ";
			print "created, pointing the access domain to the primary domain. That's ";
			print "done using the command \'ln -s s\#\#\#\#\#.gridserver.com ";
			print "primarydomain.com\'.\n";
	}
}
	
#Test connection to database with username and password, then list databases.
sub plesk_db_query {
	$db{'user'} = 'admin';
	open my $db_pass, "<", "/etc/psa/.psa.shadow"
		or die "Failed to read /etc/psa/.psa.shjadopw: $!";
	open (DBPASS, "/etc/psa/.psa.shadow") or die $!; #get db password
	$db{'pass'} = <DBPASS>;
	close (DBPASS);
	chomp $db{'pass'};
	my $dberror = "";
	$dbc = DBI->connect('DBI:mysql:psa:host=localhost', $db{'user'}, $db{'pass'}) or $dberror = DBI->errstr . "\n";
	my $db_ref = $dbc->selectrow_arrayref($db_query);
	my $listed = 0;
	$dbc->disconnect;
	for my $res (@$db_ref) {
		print "$res\n\n";
		chomp $res;
		push (@results, $res);
	}
	#foreach (@$db_ref) {print "said $_\n";};
	return @results;
}
sub grabDBConf {
	switch ($cms) {
		case "WordPress" {
			$matchUser = "define\\('DB_USER',\ \'(.+)\'";
			$matchPass = "define\\('DB_PASSWORD',\ \'(.+)\'";
			$matchDB = "define\\('DB_NAME',\ \'(.+)\'";
			$matchHost = "define\\('DB_HOST',\ \'(.+)'";
		} case "Joomla" {
			$matchUser = 'var \$user = \'(.+)\';';
			#$matchUser = "var\ \$user\ \=\ '(.+)';";
			$matchPass = 'var \$password\ = \'(.+)\';';
			$matchDB = 'var \$db\ = \'(.+)\';';
			$matchHost = 'var \$host\ = \'(.+)\';';
		} case "Drupal" {
			$matchUser = '\$db_url = \'mysql:\/\/(.+):.+\';';
			#$matchUser = '\$db_url = (.+);';
			$matchPass = '\$db_url = \'mysql:\/\/.+:(.+)@.+\';';
			$matchDB = '\$db_url = \'mysql:\/\/.+:.+@.+/(.+)\';';
			$matchHost = '\$db_url = \'mysql:\/\/.+:.+@(.+)\/.+\';';
		} case "ZenCart" {
			$matchUser = "define\\('DB_USER',\ \'(.+)\'";	
			$matchPass = "define\\('DB_PASSWORD',\ \'(.+)\'";
			$matchDB = "define\\('DB_NAME',\ \'(.+)\'";
			$matchHost = "define\\('DB_HOST',\ \'(.+)'";
		} case "EE" 	{
			$matchUser = ".+\[\'username\'\] = \"(.+)\"\;";
			$matchPass = ".+\[\'password\'\] = \"(.+)\"\;";
			$matchDB = ".+\[\'database\'\] = \"(.+)\"\;";
			$matchHost = ".+\[\'hostname\'\] = \"(.+)\"\;";
		}
	}		
	foreach (@confs){
		open DB, $_ or die "Couldn't open file $_";
		my @confContents = <DB>;
		my @dbResults;
		if ($serviceType eq "gs") {
			$db{'host'} = "internal-db.$host";
		} else {$db{'host'} = "localhost";
		}
		foreach (@confContents) {
			if ($_ =~ m/$confSearch/){
				print "Matched the line $_";
				$searchLine = $_;
				switch ($searchLine) {
					case m/$matchHost/i {
						$searchLine =~ m/$matchHost/;
						my $matchedHost = $1;
						unless ($matchedHost eq $db{'host'}) {
							print color 'bold underline'; 
							print "It appears that the hostname used in the configuration file ";
								print "$cmsConfName may not be correct. It normally should be ";
								print "$db{'host'} , but is set to $matchedHost\n";
							print color 'reset';
							return;
						}
					} case m/$matchUser/i {
						$searchLine =~ m/$matchUser/;
						$db{'user'} = $1;
						print "searched for $matchUser and set dbuser $db{'user'}";
						next;
					} case m/$matchPass/i {
						$searchLine =~ m/$matchPass/;
						$db{'pass'} = $1;
						print "\n\n$db{'pass'}\n\n";
						next;
					} case m/$matchDB/i {
						$searchLine =~ m/$matchDB/;
						$db{'name'} =$1;
						chomp $db{'name'};
						print "\n\nusing database $db{'name'}\n\n";
						next;
						push (@dbResults, $_);	
					}
				}
			}
		}
	}		
}				

sub checkDb {
	our $dsn;
#@dbs = DBI->data_sources("mysql");
	if ($serviceType eq "dv"){
		$dsn = "DBI:mysql:host=$host";
	} else {
		$dsn = "DBI:mysql:host=internal-db.$host";
	}
	$dbError = "";
	print "Connecting\n\n";
		$dbError = DBI->errstr; 
		noDB($dbError); 
		return; 
	if ($dbError eq m/""/){
		my $query = 'SHOW DATABASES;';
		my $databases = $dbc->selectcol_arrayref($query);
		print "Connected\n\n";
		#$checkDb::dbError = DBI->errstr;
		my $dbHash = @$databases;
		print "The databases available to that user are:\n";
		foreach (@$databases){
			print $_ . "\n";
			chomp $_;
			if ($serviceType eq "gs") {
				if ($_ eq $db{'name'}) {
					$userHasAccess = "1";
				}
			}
		}
	}	
	$dbc->disconnect;
	if ($serviceType eq "gs") {	
		if ($userHasAccess eq "1") {
			print "The retrieval of a database listing will not diagnose issues ";
				print "with slowness, but will determine whether or not a connection ";
				print "could be made at all. It appears that the database server is ";
				print "responding.\n";
			$userHasAccess = "0";
		} else {
			print color 'bold'; 
			print "\n\n\tThe database listed in the configuration file wasn't found ";
				print "when logging in with the username and password in that file. ";
				print "Please make sure the database exists, and that the user has ";
				print "access to it.\n\n\t (gs): ";
				print q|http://wiki.mediatemple.net/w/%28gs%29:Manage_database_users#
					Setting_Permissions_for_a_Database_User\n\nIf the database doesn't 
					exist, determine if a backup is available.|; 
			if ($serviceType eq "dv" ) {
				print "This is not a common issue on (dv). It can be scoped. If the ";
					print "customer demands escalation, note the database that was missing ";
					print "and the domain it belongs to.\n\n";
			} 
			print color 'reset';
		}
	}
}
sub noDB {
	print color 'bold underline';
	if ($dbError =~ m/using password: YES\)$/) {
		print "\nIt appears they're using the wrong password.";
		if ($serviceType eq "gs") {
			print "Please check their notes and logs to determine if they have been ";
			print "tahiti'd. Otherwise,";
		} 
		print " they should update their password in their configuration file(s): \n";
		print color 'reset'; 
		foreach (@confs) {
			print "$_ ";
		}
		print "Once those are updated, set the password for that database user:\n ";
			print q|http://wiki.mediatemple.net/w/%28gs%29:Manage_database_users#
				Changing_the_password_for_a_Database_User\n|;
	}
	if ($dbError =~ m/Too many connections/) {
		print "\nTheir database has exceeded the maxiumum number of connections ";
			print "available. This can be the result of too many people accessing ";
			print "the database directly, or of a large amount of traffic. However ";
			print "it is almost always due to their code not closing database ";
			print "connections quickly enough (if at all) once the connection is no ";
			print "longer needed.\n";
	}
	if ($dbError =~ m/Lost connection to MySQL server/) {
		print "\nThe error they are geting indicates that this will need to be ";
			print "escalated to a T3. Please include this error message in the notes:";
			print "\n $dbError\n";
	} else {
		print "\nThere was a problem connecting to your database. The error returned ";
			print "was: $dbError\n";
	}
	print color 'reset';
}
#check to make sure IMAP mail server can be connected to
sub checkMailServers {
	$sentTime = time();
	my $mailFail;
	$domain = "$1$2" if ($email{'user'} =~ m/@(\w+)((\.\w+)+)/);
	$type = "MX";
	checkDNS($type, $domain); # if ($dnsChecked == 0);
	if ($serviceType eq "dv"){
		$db_query = qq|
			SELECT
				mail.mail_name,domains.name,accounts.password
			FROM
				domains,mail,accounts
			WHERE
				domains.id=mail.dom_id and accounts.id=mail.account_id;|;
		plesk_db_query($db_query);
		foreach (@$db_ref) {
			chomp $_;
			push (@results, $_);
		}
		$results[0] = "0" unless defined $results[0];
		unless ($results[0] eq "0"){
			$email{'user'} = $results[0] . "@" . $results[1];
			$email{'pass'} = $results[2];
		}
	} else {
		if ($email{'user'} eq "0"){
			print "Please enter the email username:\n ";
			$email{'user'} = <STDIN>;
			chomp $email{'user'};
		}
	}
	#sendTestMail();
	sleep (2);
	print "Please send a test email to the account from norepmt\@gmail.com. ";
		print "The subject of this email should be \"This is a test message ";
		print "$sentTime\"\n once that's done, wait a few seconds and press ";
		print "enter after sending the test message";
	my $checkReady = <STDIN>;
	checkIMAP();
	return $record;
}

#message for mail failing
sub mailFail{
	my $mailFail = `dig mail.$domain | grep $domain | grep -v ';' | awk '{print \$5}'`; 
	print "mailfail = $mailFail\n\n";
	if ($mailFail != m/$domain/){
		print "It appears that the domain is pointed to the MX record: $mailFail";
	}
}
sub checkIMAP {
	my $readNow = "";
	my $imapConnect = "";
	#print "Access Domain is: $accessDom";
#my $imapConnect;
	$imapConnect = IO::Socket::INET->new(	PeerAddr => "$host",
						PeerPort => '143',
						Proto => 'tcp',
						Timeout => '20');
	my $response;
	$readNow = <$imapConnect>;
	my $loginResponse;
	if ($readNow =~ m/^\* OK/) {
		my $login = 'mt001 LOGIN ' . $email{'user'} . " " . $email{'pass'} . "\n";
		my $emailCount;
		my $emailStart;
		$imapConnect->send($login) or exit print "Couldn't login to IMAP server";
		$imapConnect->recv($readNow, 1024);
		if ($readNow =~ m/mt001 OK/) {
			$imapConnect->send("mt001 EXAMINE INBOX\n");
			$imapConnect->recv($readNow, 1024);
			if ($readNow =~ m/\*\ (\d+)\ EXISTS/) {
				$emailCount = $1;
				print "There are $emailCount emails in the inbox for " . $email{'user'} . "\n";
				if ($emailCount > 2000) {
					print "More than about 2000 emails can cause issues. Please have the ";
						print "customer remove any junk mail they may have. It can also ";
						print "help to sort email into folders.\n";
				}
			}
		} elsif ($readNow =~ m/auth.{,10}failed/i) {
			print "It seems the password was wrong. The error message was:\n$readNow";
			print "\n\n Please re-enter the password: ";
			$email{'pass'} = <STDIN>;
			chomp($email{'pass'});
			&checkIMAP;
			
		} else {
			print "looks like $readNow\n\n Please email that error message to Hutch";
		}
		if ($emailCount > 5) {
			$emailStart = $emailCount - 6; #only get the last 6 emails
		} else {$emailStart = $emailCount;
		}
		$imapConnect->send(q|mt001 fetch $emailStart:$emailCount (body[header.fields 
			(subject)])"."\n\r|);
		my $emails;
		$imapConnect->recv($emails, 2048);
		while ($emails){
			chomp $emails;
			if ($emails =~ m/This is a test message $sentTime/){
				return print q|The test message was received to the inbox. Receiving mail 
					appears to be working.\n\n|;
			}
			elsif ($emails =~ m/mt001 OK FETCH completed./) {
				return print q|I wasn't able to find the test message that should 
					have been sent\n|;
			} else {
				return print "\nsomething went horribly, horribly wrong.\nPlease copy the last 15-20 lines and send those to Hutch.\n";
			}
		}
	}
	$imapConnect->close();
}

#check to make sure POP server can be connected to
sub checkPOP {
	my $popConnect;
	$popConnect = IO::Socket::INET->new( PeerAddr => "$accessDom",
						PeerPort => '110',
						Proto => 'tcp',
						Timeout => '30');
	$popConnect->recv(my $response , 1024);
	if ($response =~ m/\+OK/) {
		print "POP server connected successfully!\n";
	} else {
		exit "couldn't connect to IMAP server for $_\n"; 
		mailFail();
	}
	$popConnect->close();
}
#check to make sure SMTP server can be connected to
sub sendTestMail{
	$sentTime = time();
	checkDNS($type, $domain); # if ($dnsChecked == 0);
	if ($serviceType eq "dv"){
		$db_query = qq|
			SELECT
				mail.mail_name,domains.name,accounts.password
			FROM
				domains,mail,accounts
			WHERE
				domains.id=mail.dom_id and accounts.id=mail.account_id;|;
		plesk_db_query($db_query);
		foreach (@$db_ref) {
			chomp $_;
			push (@results, $_);
		}
		$results[0] = "0" unless defined $results[0];
		unless ($results[0] eq "0"){
			$email{'user'} = $results[0] . "@" . $results[1];
			$email{'pass'} = $results[2];
		}
	} else {
		if ($email{'user'} eq "0"){
			print "Please enter the email username:\n ";
			$email{'user'} = <STDIN>;
			chomp $email{'user'};
		}
	} 
	my $mailUser = $1 if ($email{'user'} =~ m/(\w+)\@/);
	my $smtpConnect;
	print "Sending a test email to norepmt\@gmail.com\n";
	if ($serviceType eq "gs") {
		$smtpConnect = Net::SMTP::SSL->new($accessDom,
						Hello 	=> $accessDom,
						Port	=> 465,
						Timeout	=> 15,
						Debug	=> 1)
			or die "Failed to connect $!";
	} else {
		$smtpConnect = Net::SMTP->new($domain,
			Hello   => $domain,
			Timeout => 15,
			Debug   => 0)
			or die "Failed to connect $!";
		$smtpConnect->auth($email{'user'},$email{'pass'}) 
			or die "Failed to auth $!";
		$smtpConnect->mail($email{'user'});
		$smtpConnect->to('norepmt@gmail.com' . "\n");
		$smtpConnect->data();
		$smtpConnect->datasend("To: norepmt\@gmail.com\n");
		$smtpConnect->datasend(q|From: (mt) Media Temple test 
			<test\@mediatemple.net\n|);
		$smtpConnect->datasend(qq|Subject: This is a test message from " . hostname() 
			. " \@ " . $sentTime . "\n"|);
		$smtpConnect->datasend(q|Please disregard this message. It is being used 
			to test this mail account.\n|);
		$smtpConnect->dataend() or exit print q|Couldn't send the email\n 
			This may indicate an issue with SMTP. Please escalate.\n $!|;
		$smtpConnect->quit;
		print "Please log in to the norepmt account and look for an email with ";
			print "$sentTime in the subject. SMTP appears to be working just fine.\n\n";
		return $sentTime;
	}
}

sub checkFTP {
	my $badDir;
	my $cantLogin = 0;
	if ($domain eq "") {
		print "What domain are we dealing with here?\n"; 
		$domain = <STDIN>;
		chomp $domain;
	}
	switch ($serviceType) {
		case "dv" { 
			$dir = "httpdocs"; 
			$badDir = "Couldn't access the folder $dir via FTP.";
			$db_query = qq|
				SELECT
					login, password, domains.id
				FROM
					domains, sys_users, accounts
				WHERE
					domains.name=\'$domain\' and accounts.id = domains.id and sys_users.home like \'\%$domain\' limit 1;|;
			&plesk_db_query($db_query);
			if ($results[0] ne ""){
				$ftpLogin{'user'} = $results[0];
				$ftpLogin{'pass'} = $results[1];
			} else {
				print "I wasn't able to find that domain in the Plesk database\n";
			}	
		} case "gs" { 
			$dir = "/domains/$accessDom"; $badDir = "Your username and password are correct, but I was unable to reach the folder for your access domain. That should be /domains/$accessDom. This is not a fatal error, but can cause problems for your site.";
			print "Please enter your FTP username:\n ";
			$ftpLogin{'user'} = <STDIN>;
			chomp $ftpLogin{'user'};
			print "Please enter your FTP password:\n ";
			$ftpLogin{'pass'} = <STDIN>;
			chomp $ftpLogin{'pass'};
			$cantLogin = 1 unless ($ftpLogin{'user'} && $ftpLogin{'pass'});
			if ($cantLogin == 1) {
				return " You didn\'t enter a username and/or password ";
			}
		}
	}
#Connect via FTP. Use confirmation of password as authentication for gs script.
	my $ftpConnect = Net::FTP->new($host)
		or print "Could not connect to $host.";
	$ftpConnect->login($ftpLogin{'user'}, $ftpLogin{'pass'})
		or die print "Access Denied. Either the username or password is incorrect. "; #. $ftpConnect->message;
	$ftpConnect->cwd("$dir")
		or return print $dir . $badDir;
	$ftpConnect->dir("$dir") 
		or return print "Couldn't list the directory contents.";
	print "FTP connections look pretty good. ";
	$ftpConnect->quit;
	return $domain;
}
	

#create symlink for customer
sub createSymlink {
	print "Trying to create a symlink";
	if ($pwd =~ m/"\/home"(.*?)".home"/) {
		#print "$1";
	}
	unless (-e "/home/$siteId/users/.home/" . $main::makeLink{'from'}) {
		symlink ("/home/$siteId/users/.home/" . $main::makeLink{'to'}, 
			"/home/$siteId/users/.home/" . $main::makeLink{'from'}) 
			or die "Link could not be created";
		print "Symbolic link created from ~/" . $main::makeLink{'from'}; 
			print " to ~/" . $main::makeLink{'to'} . "\n\n" ;
		print "Link is from: " . $main::makeLink{'from'} . " and to: "; 
			print "$main::makeLink{'to'}" . "\n\n";
	} else {
		print "It appears something exists at that path, I can't write over it";
	}
}

#EasyFind!
sub confFind {
	print "\n\nthe siteid is $siteId\n\n";
	if ($cmsConfName !~ /^[\w \.!?-]+$/) {
		print "Please refrain from using asterisks (\*) or backticks (\`) in your search\n";
	} else {
		find({wanted => \&wanted, follow_fast => 1, follow_skip => 2}, 
			"/home/$siteId/users/.home/domains/$domain/");
		return $File::Find::name;
	}	
}
sub wanted {
	if ($_ eq $cmsConfName && $_ !~ /\.1167$/) {
		my $found = grep (/$cmsConfName/,$_);
		chomp $_;
		push (@confs, $File::Find::name);	
		return @confs;
		#return print "$File::Find::name";
	}		
}
