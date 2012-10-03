package strictures;

use strict;
use warnings FATAL => 'all';

use constant _PERL_LT_5_8_4 => ($] < 5.008004) ? 1 : 0;

our $VERSION = '1.004004'; # 1.4.4

sub VERSION {
  for ($_[1]) {
    last unless defined && !ref && int != 1;
    die "Major version specified as $_ - this is strictures version 1";
  }
  # disable this since Foo->VERSION(undef) correctly returns the version
  # and that can happen either if our caller passes undef explicitly or
  # because the for above autovivified $_[1] - I could make it stop but
  # it's pointless since we don't want to blow up if the caller does
  # something valid either.
  no warnings 'uninitialized';
  shift->SUPER::VERSION(@_);
}

our $extra_load_states;

sub import {
  strict->import;
  warnings->import(FATAL => 'all');

  if ($ENV{PERL_STRICTURES_EXTRA}) {
    if (_PERL_LT_5_8_4) {
      die 'PERL_STRICTURES_EXTRA checks are not available on perls older than 5.8.4: '
        . "please unset \$ENV{PERL_STRICTURES_EXTRA}\n";
    }

    $extra_load_states ||= do {

      my (%rv, @failed);
      foreach my $mod (qw(indirect multidimensional bareword::filehandles)) {
        eval "require $mod; \$rv{'$mod'} = 1;" or do {
          push @failed, $mod;

          # courtesy of the 5.8 require bug
          # (we do a copy because 5.16.2 at least uses the same read-only
          # scalars for the qw() list and it doesn't seem worth a $^V check)

          (my $file = $mod) =~ s|::|/|g;
          delete $INC{"${file}.pm"};
        };
      }

      if (@failed) {
        my $failed = join ' ', @failed;
        print STDERR <<EOE;
strictures.pm extra testing active but couldn't load all modules. Missing were:

  $failed

Extra testing is auto-enabled in checkouts only, so if you're the author
of a strictures-using module you need to run:

  cpan indirect multidimensional bareword::filehandles

but these modules are not required by your users.
EOE
      }

      \%rv;
    };

    indirect->unimport(':fatal') if $extra_load_states->{indirect};
    multidimensional->unimport if $extra_load_states->{multidimensional};
    bareword::filehandles->unimport if $extra_load_states->{'bareword::filehandles'};
  }
}

1;

__END__
=head1 NAME

strictures - turn on strict and make all warnings fatal

=head1 SYNOPSIS

  use strictures 1;

is equivalent to

  use strict;
  use warnings FATAL => 'all';

except when the C<PERL_STRICTURES_EXTRA> environment variable is set, in which case

  use strictures 1;

is equivalent to

  use strict;
  use warnings FATAL => 'all';
  no indirect 'fatal';
  no multidimensional;
  no bareword::filehandles;

Note that C<PERL_STRICTURES_EXTRA> may at some point add even more tests, with only a minor
version increase, but any changes to the effect of C<use strictures> in
normal mode will involve a major version bump.

If any of the extra testing modules are not present, L<strictures> will
complain loudly, once, via C<warn()>, and then shut up. But you really
should consider installing them, they're all great anti-footgun tools.

=head1 FORK NOTE

Most of this document is written in the voice of Matt Trout.  He thinks it's
OK to turn these on if the general clues in the filesystem I<suggest> that
development is happening.  Chip Salzenberg does not agree, and Matt has
proven impervious to reasoning and pleas.  Thus this fork, which makes no
guesses, so it cannot be wrong.

=head1 DESCRIPTION

I've been writing the equivalent of this module at the top of my code for
about a year now. I figured it was time to make it shorter.

Things like the importer in C<use Moose> don't help me because they turn
warnings on but don't make them fatal -- which from my point of view is
useless because I want an exception to tell me my code isn't warnings-clean.

Any time I see a warning from my code, that indicates a mistake.

Any time my code encounters a mistake, I want a crash -- not spew to STDERR
and then unknown (and probably undesired) subsequent behaviour.  Thus the
extra tests.

If additional useful author side checks come to mind, I'll add them to the
C<PERL_STRICTURES_EXTRA> code path only -- this will result in a minor version
increase (e.g. 1.000000 to 1.001000 (1.1.0) or similar). Any fixes only to the
mechanism ofthis code will result in a sub-version increase (e.g. 1.000000 to
1.000001 (1.0.1)).

If the behaviour of C<use strictures> in normal mode changes in any way, that
will constitute a major version increase -- and the code already checks
when its version is tested to ensure that

  use strictures 1;

will continue to only introduce the current set of strictures even if 2.0 is
installed.

=head1 METHODS

=head2 import

This method does the setup work described above in L</DESCRIPTION>

=head2 VERSION

This method traps the C<< strictures->VERSION(1) >> call produced by a use line
with a version number on it and does the version check.

=head1 EXTRA TESTING RATIONALE

The point of the extra testing -- especially C<no indirect> -- is to catch
mistakes that newbie users won't usual realise are mistakes.  For example,

  foo { ... };

where foo is an & prototyped sub that you forgot to import -- this is
pernicious to track down since all I<seems> fine until it gets called
and you get a crash. Worse still, you can fail to have imported it due
to a circular require, at which point you have a load order dependent
bug. I wrote L<http://shadow.cat/blog/matt-s-trout/indirect-but-still-fatal/>
to explain this particular problem before L<strictures> itself existed.

=head1 COMMUNITY AND SUPPORT

=head2 IRC channel

irc.perl.org #toolchain

(or bug 'mst' in query on there or freenode)

=head2 Git repository

Chip's fork of this module, which you are now reading, is at:

  https://github.com/chipdude/strictures-perl

=head1 AUTHOR

mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

chip - Chip Salzenberg (cpan:CHIPS) <chip@pobox.com>

=head1 COPYRIGHT

Copyright (c) 2010 the strictures L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
