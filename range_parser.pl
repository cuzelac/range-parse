#! /usr/bin/perl -w

use warnings;
use strict;

# cuzelac@ubuntu:~$ sudo apt-get install libreadonly-perl libreadonly-xs-perl
use Readonly;
use Data::Dumper;

# Parses ranges of hosts, returning the list
# a1..3.domain.com:
#  a1.domain.com
#  a2.domain.com
#  a3.domain.com

Readonly::Scalar my $sep => '..';
Readonly::Scalar my $sep_re => "\Q$sep\E";

#tests 
# EXPRESSION = LIST OF STRINGS (compressed for readability)
# a1..3.domain.com = a{1,2,3}.domain.com
# a11..3.domain.com = a{11,12,13}.domain.com
# a118..20.domain.com = a{118,119,120}.domain.com
# a9..11.domain.com = a{9,10,11}.domain.com
my $arg = $ARGV[0];
#print join("\n", expand_first_range($arg)), "\n" if has_range($arg);
#print join("\n", expand_first_brace_expansion($arg)), "\n" 
#  if has_brace_expansion($arg);
#exit;
print join("\n", expand($arg)), "\n";

sub has_brace_expansion {
  my $str = shift;
  return $str =~ /\{.*\}/;
}

# NOTE: Nested braces are not supported
# TODO: Support nested brace expansion?

#TODO
#tests:
# 'a{1,3..4,13}1.asdf.com'

sub expand_first_brace_expansion {
  my $str = shift;
  $str =~ /([^{]*)\{(.*?)\}(.*)/;
  my $preamble = $1;
  my $list = $2;
  my $postamble = $3;

  my @expanded_list;
  for my $item (split /,/, $list){
    if (has_range($item)){
      push @expanded_list, expand_first_range($item);
    }
    else {
      push @expanded_list, $item;
    }
  }

  my @return;
  for my $item (@expanded_list){
    push @return, $preamble . $item . $postamble;
  }
  return @return;
}

# What is a range?
#  A range is two numbers, A and B, separated by $sep according to the following 
#  rules:
#   1. len(A) == len(B)
#   2. len(A) < len(B)
# Output: a list
#
#tests
# a1..5 = 1..5
# a10..5 = 0..5
# a10..100 = 10..100

sub expand_first_range {
  my $str = shift;
#  $str =~ /(\D*)(\d+)$sep_re(\d+)(.*)/;
  $str =~ /(.*?)(\d+)$sep_re(\d+)(.*)/;
  my $preamble = $1;
  my $pre = $2;
  my $post = $3;
  my $postamble = $4;

  # if there are extra digits in the $pre numeral,
  # extract them and append them to the preamble
  if (length $pre > length $post){
    my $offset = length($pre) - length($post);
    $preamble .= substr $pre, 0, $offset;
    $pre = substr $pre, $offset;
  }

  my @expansion;
  for my $num ($pre .. $post){
    push @expansion, $preamble . $num . $postamble;
  }

  return @expansion;
}

sub has_range {
  my $str = shift;
  return $str =~ /$sep_re/;
}

sub is_expandable {
  my $str = shift;
  return has_range($str) || has_brace_expansion($str);
}

# Steps to expand a range:
#  1. find first expansion in string
#  2. Expand it into x number of results
#  3. Recursively expand each result until there is no more expansion to be
#  done

#TODO
# failed tests
# FIXT 'a{1,3..4,13}1.asdf.com'
# FIXT 'a9..11.domain1..3.com'
# FIXT 'a{1,13..4}.asdf{1,2..3}.com'
# FIXT 192.168.3.100..105
sub expand {
  my @expandables = @_;

  my @ret;

  if (1 == scalar @expandables){
    my $item = $expandables[0];
    if (!is_expandable($item)){
      #print "FIN\n";
      return $item;
    }
    elsif (has_brace_expansion($item)){
      #print "A\n";
      return expand(expand_first_brace_expansion($item));
    }
    elsif (has_range($item)){
      #print "B\n";
      return expand(expand_first_range($item));
    }
  }
  else {
    for my $item (@expandables){
      #print "C\n";
      push @ret, expand($item);
    }
  }
  return @ret;
}

=comment
idea for an interface:

$type->does_apply($str) returns list of strings
$type->expand($str) returns list of strings

Then the wrapper class wraps all the types and provides:
$range->expand($str) - must run the expansion in a certain order
$range->_is_expandable($str) - probably a private function
=cut
