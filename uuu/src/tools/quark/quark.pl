#!/usr/bin/perl -w

use Text::Wrap;
$Text::Wrap::columns = 70;

while(<>) {
  if( /^\s*;>\s*$/ ) {
    while(<>) {
    
      # check for end block
      last if /^\s*;<\s*$/;

      # strip out the leading ;; and error if it's not found
      if( ! s/^\s*;;// ) {
        print STDERR "line $.: `;;' not preceding line; ignoring paragraph\n";
        last;
      }

      s/[A-Z](\|+).*

      if $mode = "verbatim" {
        if s/D<plain>// {
          $mode = "plain";
	  next;
	}
	print;
      }
    }
  }
}
print "\n";

sub plain {
  while(<>) {
    last if /^\s*;<\s*$/;
    if( ! s/^\s*;;\s*// ) {
      print STDERR "line $.: `;;' not preceding line; ignoring paragraph\n";
      return;
    }
    chomp;
    if( ! $_ ) {
      print( wrap("", "", @_), "\n") if(@_);
      undef(@_);
      print "\n";
    } else {
      s/\bE<br>/\n/g;
      push( @_, $_);
    }
  }
  print( wrap("", "", @_), "\n") if(@_);
  undef(@_);
  print "\n";
}

sub verbatim {
  while(<>) {
    last if /^\s*;<\s*$/;
    if( ! s/^\s*;;// ) {
      print STDERR "line $.: `;;' not preceding line; ignoring paragraph\n";
      return;
    }
    print;
  }
}

sub function {
  if( ! /\G(__[\w.~@#\$?]+)\s*$/ ) {
    print STDERR "line $.: invalid function name `$1'; ignoring paragraph\n";
    return;
  }
  print "function: $1\n";
  while(<>) {
    last if /^\s*;<\s*$/;
    chomp;
    if( s/^\s*;;\s*// ) {
      if( ! $_ ) {
        print( wrap("", "", @_), "\n") if(@_);
        undef(@_);
	print "\n";
      } elsif( s/^=\s*// ) {
        print( wrap("", "", @_), "\n") if(@_);
        undef(@_);
        if( /^parameters$/ ) {
          print "parameters:\n";
        } elsif( /^returns$/ ) {
          print "returned values:\n";
        } elsif( /^([^:]*?)\s*:\s*(.*?)\s*$/ ) {
          print "  $1 = $2\n";
        } elsif( /^none$/i ) {
          print "  none\n";
        }
      } else {
        s/\bE\<br\>/\n/g;
        push( @_, $_);
      }
    
    } else {
      print STDERR "line $.: `;;' or ';=' not preceding line; ignoring paragraph\n";
      return;
    }
  }
  print( wrap("", "", @_), "\n") if(@_);
  undef(@_);
}
