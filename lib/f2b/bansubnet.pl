#!/usr/bin/perl

exit unless $ARGV[0];
exit unless $ARGV[0] =~ /^\d+\.\d+\.\d+.\d+$/;

my $network = $ARGV[0];

$network =~ s/^(\d+\.\d+\.\d+).*/$1\.0\/24/;
`sudo fail2ban-client set texcon-subnet banip $network`;
1;
