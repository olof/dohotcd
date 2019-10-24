#!/usr/bin/perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $github = 'https://github.com/olof/dohotcd';

WriteMakefile (
	NAME => 'App::DoHoT',
	AUTHOR => 'Olof Johansson <olof@cpan.org>',
	#LICENSE => 'perl',
	ABSTRACT_FROM => 'lib/App/DoHoT.pm',
	VERSION_FROM => 'lib/App/DoHoT.pm',
	SIGN => 1,

	MIN_PERL_VERSION => 5.014,

	EXE_FILES => ['dohotcd'],

	PREREQ_PM => {
		'AnyEvent' => 0,
		'AnyEvent::HTTP' => 0,
		'AnyEvent::Handle::UDP' => 0,
		'Net::DNS' => 0,
		'Net::Statsd' => 0,
		'Test::More' => 0,
		'YAML' => 0,
	},

	INSTALLSCRIPT => '/usr/sbin',
	INSTALLSITESCRIPT => '/usr/local/sbin',
	INSTALLVENDORSCRIPT => '/usr/sbin',

	META_MERGE => {
		resources => {
			bugtracker => "$github/issues",
			repository => $github,
		},
	},
);

