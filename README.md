# usb-mount
Linux USB Automount for USB Hub + several drives attached

# Install:
```sh
mv usb-mount.sh /usr/local/bin
chmod +x /usr/local/bin/usb-mount.sh
mv usb-mount@.service /etc/systemd/system
mv 99-local.rules /etc/udev/rules.d
udevadm control --reload-rules
systemctl daemon-reload
```

### References
- https://andreafortuna.org/2019/06/26/automount-usb-devices-on-linux-using-udev-and-systemd/
- https://unix.stackexchange.com/questions/681379/usb-flash-drives-automatically-mounted-headless-computer
