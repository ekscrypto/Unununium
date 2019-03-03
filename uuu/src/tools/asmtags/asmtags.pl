#!/usr/bin/perl -w

# this is yet another primitive perl tool, it generates tag files for editors.
# I have tried it with vim, but it should work with vi and emacs too.
# To use it, put a list of all your files you want tags for. Bash users can do
# this:
# ~/uuu/src/cells$ asmtags.pl `find -name *.asm | xargs`
# DOS users can get a better shell.
#
# This will produce a tags file called
# uuutags. You can use it in vim by doing ":set tags+=~/uuu/src/cells/uuutags".
# You could also put that in ~/.vimrc to have it run automajickly when you start
# vim.
#
# Now when you see "externfunc __fu" in the code, put your cursor on
# "__fu" and hit CTRL-] to jump to that function. The tags system isn't smart
# enough to know about classes, so you will get the first one vim likes; to see
# the next match do ":tn" (for tag-next). To get back where you were, press
# CTRL-t. Good stuff, have fun :P

$TAGFILE = ">uuutags";

die( "no files specified\n" )
  if( scalar @ARGV == -1 );

open TAGFILE or die( "couldn't open tag file: $!\n" );

#foreach $curfile ( @ARGV ) {
#  my $fh;
#  open( $fh, $_ )
#    or die "Can't open file: $_: $!\n";
  while( <> ) {
    if( /^\s*globalfunc\s+(__[\w\$\#\@\~\.\?]+)/ ) {
      chop $_;
      push @tags, "$1\t$ARGV\t/^$_\$/\n";
#      print TAGFILE "$1\t$ARGV\t/^$_\$/\n";
    }
  }
#}

print TAGFILE sort(@tags);
