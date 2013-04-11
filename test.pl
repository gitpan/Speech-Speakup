#! /usr/bin/perl
#########################################################################
#        This Perl script is Copyright (c) 2002, Peter J Billam         #
#               c/o P J B Computing, www.pjb.com.au                     #
#                                                                       #
#     This script is free software; you can redistribute it and/or      #
#            modify it under the same terms as Perl itself.             #
#########################################################################
use Test::Simple tests => 12;

use Speech::Speakup();

my @gettables = Speech::Speakup::speakup_get();
my $n_gettables = scalar @gettables;
ok ($n_gettables > 5, "there are $n_gettables gettable speakup parameters");

my @settables = Speech::Speakup::speakup_set();
my $n_settables = scalar @settables;
ok ($n_settables > 5, "there are $n_settables settable speakup parameters");

#my %gets = map { $_, 1 } @gettables;
#ok (!$gets{'silent'}, "silent is not gettable");

#my %sets = map { $_, 1 } @gettables;
#ok ($sets{'silent'}, "silent is settable");

my $rc = Speech::Speakup::speakup_set('silent', 7);
ok ($rc, "set silent to 7");

$rc = Speech::Speakup::speakup_set('silent', 4);
ok ($rc, "set silent to 4");

my $tmp = Speech::Speakup::speakup_get('synth');
ok ($tmp, "synth was set to $tmp");
ok (! $Speech::Speakup::Message, '$Speech::Speakup::Message was not set');

$tmp = Speech::Speakup::speakup_get('SxDcFvGb99');
ok (!$tmp, "attempting to get an inexistent speakup parameter failed");
ok ($Speech::Speakup::Message,
'$Speech::Speakup::Message was correctly set');

my @gettables = Speech::Speakup::synth_get();
my $n_gettables = scalar @gettables;
ok ($n_gettables > 5, "there are $n_gettables gettable synth parameters");

my @settables = Speech::Speakup::synth_set();
my $n_settables = scalar @settables;
ok ($n_settables > 5, "there are $n_settables settable synth parameters");

my $vol = Speech::Speakup::synth_get('vol');
ok (defined $vol, "synth vol was $vol");

$rc = Speech::Speakup::synth_set('vol', $vol);
ok ($rc, "set synth vol back to $vol");
