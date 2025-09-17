#### fail2ban-client permissions

/etc/sudoers.d/www-data:
```
www-data ALL=(ALL) NOPASSWD:/var/www/textileconservation.us/lib/f2b/banlist.pl,/var/www/textileconservation.us/lib/f2b/bansubnet.pl,/var/www/textileconservation.us/lib/f2b/banip.pl
```