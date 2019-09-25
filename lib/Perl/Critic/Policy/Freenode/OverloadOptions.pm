package Perl::Critic::Policy::Freenode::OverloadOptions;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

our $VERSION = '0.032';

use constant DESC => 'Using overload.pm without a boolean overload or fallback';
use constant EXPL => 'When using overload.pm to define overloads for an object class, always define an overload on "bool" explicitly and set the fallback option. This prevents objects from autogenerating a potentially surprising boolean overload, and causes operators for which overloads can\'t be autogenerated to act on the object as they normally would.';

sub supported_parameters { () }
sub default_severity { $SEVERITY_HIGH }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Statement::Include' }

sub violates {
	my ($self, $elem) = @_;
	return () unless ($elem->type // '') eq 'use' and ($elem->module // '') eq 'overload';
	my @args = $elem->arguments;
	my ($has_bool, $has_fallback);
	my @options;
	while (@args) {
		my $arg = shift @args;
		# use overload qw(...);
		if ($arg->isa('PPI::Token::QuoteLike::Words')) {
			push @options, $arg->literal;
		# use overload 'foo', 1;
		} elsif ($arg->isa('PPI::Token::Quote')) {
			push @options, $arg->string;
		# use overload foo => 1;
		} elsif ($arg->isa('PPI::Token::Word') or $arg->isa('PPI::Token::Number')) {
			push @options, $arg->literal;
		# unpack lists and expressions
		} elsif ($arg->isa('PPI::Structure::List') or $arg->isa('PPI::Statement::Expression')) {
			unshift @args, $arg->schildren;
		}
	}
	# use overload; or use overload ();
	return () unless @options;
	foreach my $i (0..$#options) {
		my $item = $options[$i];
		if ($item eq 'fallback' and defined $options[$i+1] and $options[$i+1] ne 'undef') {
			$has_fallback = 1;
		} elsif ($item eq 'bool') {
			$has_bool = 1;
		}
	}
	return $self->violation(DESC, EXPL, $elem) unless $has_bool and $has_fallback;
	return ();
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::OverloadOptions - Don't use overload without
specifying a bool overload and enabling fallback

=head1 DESCRIPTION

The L<overload> module allows an object class to specify behavior for an object
used in various operations. However, when activated it enables additional
behavior by default: it L<autogenerates|overload/"Magic Autogeneration">
overload behavior for operators that are not specified, and if it cannot
autogenerate an overload for an operator, using that operator on the object
will throw an exception.

An autogenerated boolean overload can lead to surprising behavior where an
object is considered "false" because of another overloaded value. For example,
if a class overloads stringification to return the object's name, but the
object's name is C<0>, then the object will be considered false due to an
autogenerated overload using the boolean value of the string. This is rarely
desired behavior, and if needed, it can be set as an explicit boolean overload.

Without setting the C<fallback> option, any operators that cannot be
autogenerated from defined overloads will result in an exception when used.
By setting C<fallback> to C<1>, the operator will instead fall back to standard
behavior as if no overload was defined, which is generally the expected
behavior when only overloading a few operations.

 use overload '""' => sub { $_[0]->name };                    # not ok
 use overload '""' => sub { $_[0]->name }, bool => sub { 1 }; # not ok
 use overload '""' => sub { $_[0]->name }, fallback => 1;     # not ok
 use overload '""' => sub { $_[0]->name }, bool => sub { 1 }, fallback => 1; # ok

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Freenode>.

=head1 CONFIGURATION

This policy is not configurable except for the standard options.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>
