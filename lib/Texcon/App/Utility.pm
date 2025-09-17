package Texcon::App::Utility;
use Dancer2 appname => 'Texcon::App';
use Net::Whois::IANA;
use Geography::Countries;
use Text::CSV::Simple;
use Storable;
use Try::Tiny;
use Carp;

post '/spambots' => sub {
  my $network = param "network";
  my $time = scalar(time);
  `sudo $Texcon::App::base_dir/lib/f2b/bansubnet.pl $network`; #fail2ban handoff
  warning "$network; gt:$time; pt:; n:; e:; bot:; b:";
  return template 'error', { title => 'fail2ban handoff', content => "$network subnet submitted" };
};

get '/spambots' => sub {
  foreach ("texcon","texcon-subnet") {
    `sudo $Texcon::App::base_dir/lib/f2b/banlist.pl $_`;
  }
  my $ipbans = retrieve("$Texcon::App::base_dir/public/bans/texcon.txt");
  my $subnetbans = retrieve("$Texcon::App::base_dir/public/bans/texcon-subnet.txt");
  my $ip_bans;
  my $subnet_bans;
  map { $ip_bans->{$_} = 1 } @$ipbans;
  map { $subnet_bans->{$_} = 1 } @$subnetbans;

  my $botgeo = retrieve("$Texcon::App::base_dir/public/bans/botgeo.txt");
  my $iana = Net::Whois::IANA->new;
  my $parser = Text::CSV::Simple->new({ binary => 1, sep_char => ";", escape_char => "\\", allow_loose_quotes => 1 });
  my @logfields = (qw/dateip start end name email phantom body/);
  $parser->field_map(@logfields);
  my $hostfreq;
  my $networkfreq;
  my $logfile1 = "/var/log/texcon/formbots.log.1";
  my $logfile2 = "/var/log/texcon/formbots.log";
  my @data1 = $parser->read_file($logfile1);
  my @data2 = $parser->read_file($logfile2);
  my @data = (@data1,@data2);

  foreach my $line (@data) {
    map { @$line{$_} =~ s/^\s\w+:// } @logfields;
    if ( @$line{dateip} =~ /^\[Texcon::App:\d+\]\swarning/ ) {
      @$line{network} = @$line{dateip};
      @$line{network} =~ s/.*>\s(\d+\.\d+\.\d+).*/$1/;
    } else {
      @$line{body} =~ s/^(.*)\sin\s.*$/$1/;
      @$line{body} =~ s/^(.{30}).*$/$1 \.\.\./;
      @$line{name} =~ s/^(.{30}).*$/$1 \.\.\./;
      @$line{ip} = @$line{dateip};
      @$line{ip} =~ s/.*>\s(\d+\.\d+\.\d+\.\d+)$/$1/;
      @$line{network} = @$line{ip};
      @$line{network} =~ s/^(\d+\.\d+\.\d+)\.\d+$/$1/;
      @$line{host} = @$line{ip};
      @$line{host} =~ s/^\d+\.\d+\.\d+(\.\d+)$/$1/;
      @$line{dateip} =~ s/^.*@(.*)>.*$/$1/;
      @$line{duration} = @$line{end} - @$line{start};
      $networkfreq->{@$line{network}}++;
      $hostfreq->{@$line{ip}}++;
      $botgeo->{@$line{network}} = undef unless $botgeo->{@$line{network}};
    }
  }

  my $indexcx = 0;
  my @netban_indexes = grep { $data[$_]{dateip} =~ /warning/ } 0..$#data;
  foreach (@netban_indexes) {
    splice(@data, $_ - $indexcx, 1);
    $indexcx++;
  }
   
  foreach my $network (keys %$botgeo) {
    unless ($botgeo->{$network}) {
      try {
        my $address = "$network\.0";
        $iana->whois_query(-ip=>$address);
        $botgeo->{$network} = country $iana->country;
      } catch {
        carp "caught error: $_"; # not $@
      };
    }
  }

  map { @$_{geo} = $botgeo->{@$_{network}},
          @$_{hostfreq} = $hostfreq->{@$_{ip}},
          @$_{networkfreq} = $networkfreq->{@$_{network}},
          @$_{ipban} = $ip_bans->{@$_{ip}},
          @$_{subnetban} = $subnet_bans->{@$_{network}}
      } @data;

  store ($botgeo, "$Texcon::App::base_dir/public/bans/botgeo.txt");

  my $first = keys $subnet_bans;
  my $last = keys $ip_bans;
  my @bans = ($first, $last);

  template 'spambots', { data => \@data, bans => \@bans };

};

true;
