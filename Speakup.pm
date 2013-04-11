# Speakup::Speakup.pm
#########################################################################
#        This Perl module is Copyright (c) 2002, Peter J Billam         #
#               c/o P J B Computing, www.pjb.com.au                     #
#                                                                       #
#     This module is free software; you can redistribute it and/or      #
#            modify it under the same terms as Perl itself.             #
#########################################################################

package Speech::Speakup;
$VERSION = '1.00';   # 
my $stupid_bloody_warning = $VERSION;  # circumvent -w warning
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(speakup_get speakup_set synth_get synth_set);
%EXPORT_TAGS = (ALL => [@EXPORT,@EXPORT_OK]);

no strict; no warnings;

$Speech::Speakup::Message = undef;
my $SpDir;
foreach ('/sys/accessibility/speakup','/proc/speakup') {
    if (-d $_) { $SpDir = $_; }
}
if (!$SpDir) { die "can't find the speakup directory\n"; }

use open ':locale';  # the open pragma was introduced in 5.8.6

sub speakup_get { get($SpDir,   @_); }
sub speakup_set { set($SpDir,   @_); }
sub synth_get   { get(synthdir(),@_); }
sub synth_set   { set(synthdir(),@_); }

sub set { my ($dir, $param, $value) = @_;
	if (! $param) {  # return a list of all settable params
		if (! opendir(D,$dir)) {
			$Message = "can't opendir $dir: ";
			return undef;
		}
		my @l = sort grep
		  { (!/^\./) && (-f "$dir/$_") && is_w("$dir/$_") } readdir(D);
		closedir D;
		$Message = undef;
		return @l;
	}
	if (! open(F, '>', "$dir/$param")) {
		$Message = "can't open $dir/$param: $!";
		return undef;
	} else {
		print F "$value\n"; close F;
		$Message = undef;
		return 1;
	}
}

sub get { my ($dir, $param) = @_; 
	if (! $param) {  # return a list of all gettable params
		if (! opendir(D,$dir)) {
			$Message = "can't opendir $dir: ";
			return undef;
		}
		my @l = sort grep
		  { (!/^\./) && (-f "$dir/$_") && is_r("$dir/$_") } readdir(D);
		closedir D;
		$Message = undef;
		return @l;
	}
	if (! open(F, '<', "$dir/$param")) {
		$Message = "can't open $dir/$param: $!";
		return undef;
	} else {
		my $value = <F>; close F; $value =~ s/\s+$//;
		$Message = undef;
		return $value
	}
}

sub synthdir {
	my $sd = get($SpDir,'synth');
	if (! $sd) { warn "can't find the synth directory\n"; return ''; }
	my $d = "$SpDir/$sd";
	if (! -e $d) { warn "synth directory $d does not exist\n"; return ''; }
	if (! -d $d) { warn "synth directory $d is not a directory\n"; return ''; }
	return $d;
}

sub is_w {
	# because -w as root reports yes regardless of file permissions
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
	  $atime,$mtime,$ctime,$blksize,$blocks) = stat($_[$[]);
	return $mode & 2;
}
sub is_r {
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
	  $atime,$mtime,$ctime,$blksize,$blocks) = stat($_[$[]);
	return $mode & 4;
}

sub enter_speakup_silent {   # 1.62
	# echo 7 > /sys/accessibility/speakup/silent  if it exists
	if (!$SpeakUpSilentFile) { return 0; }
	if ($IsSpeakUpSilent) {
		warn "enter_speakup_silent but already IsSpeakUpSilent\r\n"; return 1 ;
	}
	if (open(S, '>', $SpeakUpSilentFile)) { print S "7\n"; close S; }
	$IsSpeakUpSilent = 1;
	return 1;
}
sub leave_speakup_silent {   # 1.62
	# echo 4 > /sys/accessibility/speakup/silent  if it exists
	if (!$SpeakUpSilentFile) { return 0; }
	if (!$IsSpeakUpSilent) {
		warn "leave_speakup_silent but not IsSpeakUpSilent\r\n"; return 1 ;
	}
	if (open(S, '>', $SpeakUpSilentFile)) { print S "4\n"; close S; }
	$IsSpeakUpSilent = 0;
	return 1;
}

sub which {
	my $f;
	foreach $d (split(":",$ENV{'PATH'})) {$f="$d/$_[$[]"; return $f if -x $f;}
}
%SpeakMode = ();
sub END {
	if ($Eflite_FH) { print $Eflite_FH "s\nq { }\n"; close $Eflite_FH;
	} elsif ($Espeak_PID) { kill SIGHUP, $Espeak_PID; wait;
	}
}

1;

__END__

=pod

=head1 NAME

Speech::Speakup - a module to interface with the Speakup screen-reader

=head1 SYNOPSIS

 use Speech::Speakup;
 my @speakup_parameters = Speech::Speakup::speakup_get();
 my @synth_parameters   = Speech::Speakup::synth_get();
 print "speakup_parameters are @speakup_parameters\n";
 print "synth_parameters   are @synth_parameters\n";
 Speech::Speakup::speakup_set('silent', 7);  # impose silence
 Speech::Speakup::speakup_set('silent', 4);  # restore speech
 Speech::Speakup::synth_set('punct', 2);  # change the punctuation-level

=head1 DESCRIPTION

I<Speakup> is a screen-reader that runs on I<Linux>
as a module within the kernel.
A screen-reader allows blind or visually-impaired people
to hear text as it appears on the screen,
and to review text already displayed anywhere on the screen.
I<Speakup> will only run on the I<linux> consoles,
but is powerful and ergonomic, and runs during the boot process.
The other important screen-reader is I<yasr>,
which runs in user-space and is very portable, but has less features.

There are parameters you can get and set at the screen-reader level
by using the routines I<speakup_get> and I<speakup_set>.

One of those parameters is the particular voice synthesiser engine
that I<speakup> will use;
this synthesiser has its own parameters, 
parameters that I<speakup> will use when invoking it,
and which you can get and set
by using the routines I<synth_get> and I<synth_set>.

The synthesiser can be a hardware device, on a serial line or USB,
or it can be software.
The most common software synth for I<Linux> is I<espeak>,
and I<flite> is also important.

This is Speech::Speakup version 1.00

=head1 SUBROUTINES

All these routines set the variable B<$Speech::Speakup::Message>
to an appropriate error message if they fail.

=over 3

=item I<speakup_get>() or I<speakup_get>($param);

When called without arguments, I<speakup_get> returns a list
of the readable I<speakup> parameters.

When called with one of those parameters as an argument,
I<speakup_get> returns the current value of that parameter,
or I<undef> if the get fails.

=item I<speakup_set>() or I<speakup_set>($param, $value);

When called without arguments, I<speakup_set> returns a list
of the writeable I<speakup> parameters.

When called with $parameter,$value as arguments,
I<speakup_set> sets the value of that parameter.
It returns success or failure.

=item I<synth_get>() or I<synth_get>($param);

When called without arguments, I<synth_get> returns a list
of the readable synthesiser parameters.

When called with one of those parameters as an argument,
I<synth_get> returns the current value of that parameter,
or I<undef> if the get fails.

=item I<synth_set>() or I<synth_set>($param, $value);

When called without arguments, I<synth_set> returns a list
of the writeable synthesiser parameters.

When called with $parameter,$value as arguments,
I<synth_set> sets the value of that parameter.
It returns success or failure.

=back

=head1 PARAMETERS

Most I<speakup> parameters are 0 to 10, default 5.
The important I<silent> parameter is a bitmap,
but its bits are not well documented;
it is known that B<7> means silent and B<4> restores speech.
The I<synth> parameter is a string,
which must exist as a subdirectory of the speakup parameter directory.

=head1 EXPORT_OK SUBROUTINES

No routines are exported by default,
but they are exported under the I<ALL> tag,
so if you want to import all these you should:

 import Speech::Speakup qw(:ALL);

=head1 DEPENDENCIES

It requires Exporter, which is core Perl.

=head1 AUTHOR

Peter J Billam www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

 http://linux-speakup.org
 http://linux-speakup.org/spkguide.txt
 http://speech.braille.uwo.ca/mailman/listinfo/speakup
 http://people.debian.org/~sthibault/espeakup
 aptitude install espeakup speakup-tools
 aptitude install flite eflite
 http://search.cpan.org/perldoc?Speech::Speakup
 /sys/accessibility/speakup/ or /proc/speakup/

 http://espeak.sourceforge.net
 aptitude install espeak
 perldoc Speech::eSpeak
 http://search.cpan.org/perldoc?Speech::eSpeak
 http://linux-speakup.org/distros.html
 http://the-brannons.com/tarch/
 http://www.pjb.com.au/
 espeakup(1)
 emacspeak(1)
 espeak(1)
 perl(1)

There should soon be an equivalent Python3 module
with the same calling interface, at
http://cpansearch.perl.org/src/PJB/Speech-Speakup-1.00/py/SpeechSpeakup.py

=cut