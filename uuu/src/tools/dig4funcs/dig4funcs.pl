#!/usr/bin/perl -w

# oki, here's a tempoary fix until bradd either says "ok, i suck" or accually
# gets the script done. You can get a new fid by running this:
#
# ./dig4funcs.pl `find ../../../src/cells -name *.asm | xargs`
#
# Have fun.

$biggestfid = 0;
while(<>) {
  if( /^\s* globalfunc \s+
    (__[\w\$\#@~.?]+) \s*,\s*
    ([\w.?][\w\$\#@~.?]*) \s*,\s*
    (
      \d+		# decimal number
     ) \s*,\s*
    (
      \d+		# decimal number
    ) \s*$/xi ) {
    $biggestfid = $3 if( $3 > $biggestfid );
  }
}
print "congrats, ".$biggestfid++." is your lucky number\n";
