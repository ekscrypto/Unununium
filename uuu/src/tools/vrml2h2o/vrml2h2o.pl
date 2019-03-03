#!/usr/bin/perl -w

# vrml2h2o
# a primitive vrml->hydro3d converter.

# This probally only works for simple VRML files saved by blender with only
# one object in them ATM...maybe I can get someone to write this program
# and make it a little more robust in C because I have had WAY too much HLL
# lately.

while(<>) {
  if( /^\s*point \[$/ ) {
    print "test_verts:\n";
    while(<>) {
      last if /^\s*]$/;
      /(\S+) (\S+) (\S+),/;
      print "dd $1, $2, $3\n";
      $vertcount++
    }
  }
  if( /^\s*coordIndex \[$/ ) {
    print "test_faces:\n";
    while(<>) {
      last if /^\s*]$/;
      /(\S+), (\S+), (\S+), -1,/;
      print "dw $1, $2, $3\ndd 0, 0, 0\n";
      $facecount++
    }
  }
}

print "\%define vertcount $vertcount\n\%define facecount $facecount\n";
