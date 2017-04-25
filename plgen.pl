#!/usr/bin/perl
########################################
# ((( plgen ))) - a playlist generator
# (c) 2004, Zoltan Gabriel
########################################

use strict;
no strict 'refs';
use Getopt::Std;
use File::Spec;

########################################
# Variables
########################################

my %args;
my $myfile = "list.m3u";
my $mydir = ".";
my %filehash;

########################################
# Getopt Stuff
########################################

$Getopt::Std::STANDARD_HELP_VERSION = 1;
$main::VERSION = "0.2";

sub main::VERSION_MESSAGE()
{
    print "plgen.pl version $main::VERSION\n";
}
sub main::HELP_MESSAGE()
{
    print "\n((( plgen ))) - a PERL playlist generator by Zoltan Gabriel, 2004\n\n";
    print "Usage: plgen.pl [-f output_file] [-d directory] [-r] [-a] [-t days]\n\n";
    print " -f    The name of the playlist file to be written.\n";
    print "       Defaults to 'list.m3u'.\n";
    print " -d    The directory from where files should be read.\n";
    print "       Defaults to current directory.\n";
    print " -r    Process directories recursively.\n";
    print "       Default is non-recursive.\n";
    print " -a    Write absolute paths.\n";
    print "       Default is relative.\n";
    print " -t    Files which have been accessed within the given amount of days\n";
    print "       are excluded from the list. Default is 0.";
}

getopts('f:d:rat:', \%args);

if ($args{f})
{
    $myfile = $args{f};
}
if ($args{d})
{
    $mydir = $args{d};
}

########################################
# Main thingies
########################################

collect_files($mydir);
write_playlist();
print "\nPlaylist created.\n";

########################################
# Subroutine to process a
# directory(-tree)
########################################

sub collect_files()
{
    my $dir = shift;
    opendir(DIR, $dir) || die "can't opendir $mydir: $!";
    
    # Add other formats if you need to.
    my @pl_items = grep { /.*?\.((mp3)|(ogg)|(wma)|(wav)|(flac))$/i && -f "$dir/$_" } readdir(DIR);
    my @directories;
    if ($args{r})
    {
        rewinddir(DIR);
        # Collect directories, except for '.' and '..'
        @directories = grep { /^[^\.]|(\.[^\.])$/ && -d "$dir/$_" &! /System Volume Information/} readdir(DIR);
    }
    
    for (@pl_items)
    {
        my $filepath;
        # Write absolute paths
        if ($args{a})
        {
            if (File::Spec->file_name_is_absolute($dir))
            {
                $filepath = $dir;
            }
            else
            {
                my @dirs = (File::Spec->rel2abs(File::Spec->curdir()), $dir);
                $filepath = File::Spec->catdir(@dirs);
            }
        }
        # Write relative paths
        else
        {
            if (File::Spec->file_name_is_absolute($dir))
            {
                $filepath = File::Spec->catdir(File::Spec->abs2rel($dir));
            }
            else
            {
                $filepath = $dir;
            }
        }
        my @fileparts = split(/\./, $_);
        my $ext = pop(@fileparts);
        my $filename = join(".", @fileparts);
        $filehash{$filename}{$ext}{$filepath} = (stat(File::Spec->catfile($filepath, $filename.".".$ext)))[8];
    }
    
    # Recursive call
    if ($args{r})
    {
        for (@directories)
        {
            my @dirs=($dir, $_);
            collect_files(File::Spec->catdir(@dirs));
        }
    }
    closedir DIR;
}

########################################
# Write playlist.
########################################

sub write_playlist
{
    my $prevfile;
    my @finalitems;
    # Remove duplicate files
    for my $file(sort keys %filehash)
    {
        for my $ext(sort keys %{$filehash{$file}})
        {
            for my $path(sort keys %{$filehash{$file}{$ext}})
            {
                # Check whether file is a duplicate
                if(!(lc($file) eq lc($prevfile)))
                {
                    # If file accestime limit is given
                    if($args{t})
                    {
                        my $deadline = time() - $args{t}*60*60*24;
                        if($filehash{$file}{$ext}{$path} < $deadline)
                        {
                            if (!$args{r} && $path eq ".")
                            {
                                push @finalitems, $file.".".$ext;
                            }
                            else
                            {
                                push @finalitems, File::Spec->catfile($path, $file.".".$ext);
                            }
                        }
                    }
                    else
                    {
                        if (!$args{r} && $path eq ".")
                        {
                            push @finalitems, $file.".".$ext
                        }
                        else
                        {
                            push @finalitems, File::Spec->catfile($path, $file.".".$ext);
                        }
                    }
                }
                $prevfile = $file;
            }
        }
    }
    # Write playlist, ordered by directories
    open PLFILE,">$myfile" || die "Can't open file $myfile: $!";
    for my $item(sort {lc($a) cmp lc($b)} @finalitems)
    {
        print PLFILE $item."\n";
    }
    close PLFILE;
}