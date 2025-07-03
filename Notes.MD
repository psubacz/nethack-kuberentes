#
## Nethack

* nethack is compile to /root/nh/install/games/ instead of the standard /var/lib/nethack 
* the runtime contianer needs to match the expected directory sturcture of the build at 
/var/lib/nethack
* you technically dont need GDBPATH as its specifically for crash debugging.


## dgamelaunch
* configuration file path is hardcoded at compile time. By default, it's /etc/dgamelaunch.conf