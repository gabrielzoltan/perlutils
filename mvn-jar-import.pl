#!/bin/perl
use strict;

use Getopt::Std;
use IO::Uncompress::Unzip qw(unzip $UnzipError) ;

my $pomSkeleton = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<project xsi:schemaLocation=\"http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd\" xmlns=\"http://maven.apache.org/POM/4.0.0\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">\n  <modelVersion>4.0.0</modelVersion>\n  <groupId>GROUPID</groupId>\n  <artifactId>ARTIFACTID</artifactId>\n  <version>VERSION</version>\n</project>";
my $mvnSettings = "c:\\\\Users\\\\zgabriel\\\\.m2\\\\settings.xml";
my $snapshotRepositoryId = "bb-mif-snapshot";
my $releaseRepositoryId = "bb-mif-release";
my $snapshotRepositoryUrl = "https://maven.w.up/content/repositories/bb-mobilegatewayinterface-snapshot/";
my $releaseRepositoryUrl = "https://maven.w.up/content/repositories/bb-mobilegatewayinterface-release/";
my $trustStore = "c:\\\\Users\\\\zgabriel\\\\.m2\\\\jssecacerts";
my $trustStoreType = "jks";
my $trustStorePassword = "changeit";

my %options=();
getopts('d:', \%options);
print "Util for installing third party jars to your local maven repository.\n";
print "Usage: mvn-jar-import.pl -d <directory>\n";
if ($options{d} eq "") {
  $options{d} = ".";
}
print "\nDirectory to import from: " . $options{d} . "\n";

foreach my $fp (glob("$options{d}/*.jar")) {
  printf "\n\n%s\n\n", $fp;
  my $u = new IO::Uncompress::Unzip $fp
    or die "Cannot open $fp: $UnzipError";
  die "Zipfile has no members"
    if ! defined $u->getHeaderInfo;
  for (my $status = 1; $status > 0; $status = $u->nextStream) {
    my $name = $u->getHeaderInfo->{Name};
    if ($name =~ /pom.properties/) {
      my $buff;
      my $pom;
      while (($status = $u->read($buff)) > 0) {
        (my $version) = ($buff =~ /version=(\S*)/);
        (my $groupId) = ($buff =~ /groupId=(\S*)/);
        (my $artifactId) = ($buff =~ /artifactId=(\S*)/);
        $pom = $pomSkeleton;
        $pom =~ s/VERSION/$version/g;
        $pom =~ s/GROUPID/$groupId/g;
        $pom =~ s/ARTIFACTID/$artifactId/g;
      }
      last if $status < 0;
      my $pomFile = $fp;
      $pomFile =~ s/.jar/.pom/;

      if (-f $pomFile) {
        unlink $pomFile
          or die "Cannot delete $pomFile";
      }

      my $OUTFILE;

      open $OUTFILE, '>>', $pomFile
        or die "Cannot open $pomFile";

      print { $OUTFILE } $pom
        or die "Cannot write to $pomFile";

      close $OUTFILE
        or die "Cannot close $pomFile";
      my $repositoryId = $releaseRepositoryId;
      my $repositoryUrl = $releaseRepositoryUrl;
      if ($pom =~ /SNAPSHOT/) {
        $repositoryId = $snapshotRepositoryId;
        $repositoryUrl = $snapshotRepositoryUrl;
      }
      my $command = "mvn deploy:deploy-file -s $mvnSettings -DpomFile=$pomFile -Dfile=$fp -DrepositoryId=$repositoryId -Durl=$repositoryUrl -Djavax.net.ssl.trustStore=$trustStore -Djavax.net.ssl.trustStoreType=$trustStoreType -Djavax.net.ssl.trustStorePassword=$trustStorePassword";
      print $command . "\n";
      my $stdout = qx($command);
      print $stdout;

      unlink $pomFile
        or die "Cannot delete $pomFile";
    }
  }
}
