#!/usr/bin/perl
use Storable;

exit unless $ARGV[0];
exit unless $ARGV[0] eq ("texcon") || ("texcon-subnet");

my $jail = $ARGV[0];
my $base_dir = '/var/www/textileconservation.us';

my @ipbans = `sudo fail2ban-client status $jail`;
my $ipbans = pop(@ipbans);
$ipbans =~ s/^\s*\`-\sBanned\sIP\slist:\s*//;
$ipbans =~ s/\n//;
@ipbans = split(/\s/,$ipbans);

map { $_ =~ s/\.0\/24// } @ipbans;

store (\@ipbans, "$base_dir/public/bans/$jail.txt");
chown(33,33,("$base_dir/public/bans/$jail.txt"));
1;
