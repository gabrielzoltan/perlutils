#!/bin/perl
use strict;

use List::Util qw/shuffle/;
use Digest::MD5 qw(md5);
use Time::HiRes qw(gettimeofday);
use Getopt::Std;

my @suites = ("Swords", "Pentacles", "Cups", "Wands");
my @minors = ("Ace", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Page", "Knight", "Queen", "King");
my @majorIdxs = ("0", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX", "XXI", "XXII");
my @majors = ("The Fool", "The Magician", "The High Priestess", "The Empress", "The Emperor", "The Hierophant", "The Lovers", "The Chariot", "Strength", "The Hermit", "Wheel of Fortune", "Justice", "The Hanged Man", "Death", "Temperance", "The Devil", "The Tower", "The Star", "The Moon", "The Sun", "Judgement", "The World");

sub generateCards {
  my ($majors, $suites, $minors) = @_;
  my @cards;
  for my $i (0 .. $#majors) {
    $cards[$i][0] = "Major Arcana";
    $cards[$i][1] = @majorIdxs[$i];
    $cards[$i][2] = @majors[$i];
  }

  for my $i (0 .. $#suites) {
    for my $j (0 .. $#minors) {
      my $cardIdx = $#majors + 1 + $i * ($#minors + 1) + $j;
      $cards[$cardIdx][0] = "Minor Arcana";
      $cards[$cardIdx][1] = @suites[$i];
      $cards[$cardIdx][2] = @minors[$j];
    }
  }
  return @cards;
}

sub printCard {
  my ($card) = $_[0];
  if (@$card[0] eq "Major Arcana") {
    return @$card[1] . " " . @$card[2];
  }
  if (@$card[0] eq "Minor Arcana") {
    return @$card[2] . " of " . @$card[1];
  }
  return "Unknown card";
}

sub shuffleCards {
  my ($times, $cards) = @_;
  for my $i (1 .. $times) {
    @$cards = shuffle @$cards;
  }
  return @$cards;
}

sub createSeed {
  my $phrase = @_[0];
  my   ($seconds, $microseconds) = gettimeofday;
  $phrase = $phrase . " " . $seconds . $microseconds;
  my $str = substr( md5($phrase . time()), 0, 4 );
  return unpack('L', $str);
}

sub drawCards {
  my ($seed, $times, $cards) = @_;
  my @cards = @{$cards};
  srand($seed);
  my @result;
  for my $i (0 .. $times - 1) {
    my $drawnIndex = int(rand($#cards));
    @result[$i] = @cards[$drawnIndex];
    splice(@cards, $drawnIndex, 1);
  }
  return @result;
}

my %options=();
getopts('q:n:', \%options);
print "Util for drawing tarot cards.\n";
print "Usage: tarot.pl -q <question> -n <number of cards>\n";
if ($options{n} eq "") {
  $options{n} = 3;
}
print "\nYour query: " . $options{q} . "\n";

my $seed = createSeed($options{q});
my @cards = generateCards(\@majors, \@suites, \@minors);
print "Shuffling deck " . ($seed % 10 + 1) . " times.\n";
my @cards = shuffleCards($seed % 10 + 1, \@cards);
#foreach my $i (0 .. $#cards) {
#  my $card = @cards[$i];
#  print $i . " " . printCard(\@$card) . "\n";
#}
print "Drawing " . $options{n} . " cards.\n";
my @drawn = drawCards($seed, $options{n}, \@cards);
print "\n";
foreach my $i (0 .. $#drawn) {
  my $drawnCard = @drawn[$i];
  my $index = $i + 1;
  print $index . ". " . printCard(\@$drawnCard) . "\n";
}
print "\n";
