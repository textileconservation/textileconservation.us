#### fail2ban use on textileconservation.us

textileconservation.us is a static site of four routes, but it departs from simplicity with the use of a mail form and its attendant attraction of spam.

Spam detection/banning is accomplished using timing and honeypot values in the mail form that trigger a log entry for fail2ban processing. Secondary processing by fail2ban avoids deadlocks that prevent modifying the server firewall directly.

A separate utility route on the site enables bans of recurring ip subnets by making similar entries to the same log.

The site uses dancer2's built-in 'file' logging engine. Triggering of fail2ban in the form and utility routes relies on separate jails responding to 'error' and 'warning' log entries for ip bans and subnet bans respectively.

#### jail.local
```
.
.
.
#
# HTTP servers
#

[texcon]
enabled  = true
port     = http,https
logpath  = /var/log/texcon/formbots.log
maxretry = 1
bantime  = 172800
filter   = texcon

[texcon-subnet]
enabled  = true
port     = http,https
logpath  = /var/log/texcon/formbots.log
maxretry = 1
bantime  = 172800
filter   = texcon-subnet
action   = texcon-subnet
```

#### filter.d/texcon.conf
```
[Definition]

failregex = ^\[Texcon::App:\d+\]\serror.*?>\s<HOST>

ignoreregex =
```

#### filter.d/texcon-subnet.conf
```
[Definition]

failregex = ^\[Texcon::App:\d+\]\swarning.*?>\s<HOST>

ignoreregex =
```

#### action.d/texcon-subnet.conf
a copy of iptables-multport.conf (the default) modified to ban subnets:
```
.
.
.
actionban = <iptables> -I f2b-<name> 1 -s <ip>/24 -j <blocktype>

actionunban = <iptables> -D f2b-<name> -s <ip>/24 -j <blocktype>

[Init]
```

