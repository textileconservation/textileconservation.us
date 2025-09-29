#### fail2ban use

textileconservation.us is a static site of four routes. One of the routes has a mail form that attracts spam.

Spam detection/banning is accomplished using timing and honeypot values in the mail form that trigger fail2ban processing. Ancillary use of fail2ban simplifies the management of ban durations.

A separate utility route displays the ban log and enables bans of recurring ip subnets.

Banning is logged using dancer2's built-in 'file' logging engine. Durations are configured using separate fail2ban jails.

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
bantime  = 172800
#2 days

[texcon-subnet]
enabled  = true
port     = http,https
bantime  = 864000
#10 days
.
.
.

```
