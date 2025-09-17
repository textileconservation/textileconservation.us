#!/usr/bin/perl

exit unless $ARGV[0];
exit unless $ARGV[0] =~ /^\d+\.\d+\.\d+.\d+$/;

my $ip = $ARGV[0];

`sudo fail2ban-client set texcon banip $ip`;
1;
