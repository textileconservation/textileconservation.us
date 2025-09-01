### textileconservation.us

Essentially a static site consisting of four routes, with fail2ban signaling behind a mail form.

Spambot deterrence is accomplished using a hidden get/post timer and honeypot field in the mail form, both conditions being capable of halting submission and logging the ip for fail2ban processing. 

There is also an extra utility route for log display and enabling bans of recurring ip subnets.

Uses dancer2's built-in 'file' logging engine. Prompting of fail2ban in the form and utility routes relies on separate jails responding to 'error' and 'warning' log entries for ip bans and subnet bans respectively.

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
