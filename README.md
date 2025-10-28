# Fedora Plus Sway

Deployment script for my Fedora Linux desktop.

The package selection is somewhat opinionated and may not work for you
personally (applications, tools) or even your system (firmware,
printer drivers).

## Usage

1. Download the _Everything_ ISO from
   [here](https://alt.fedoraproject.org/) and flash it to a thumb
   drive, or burn it to CD/DVD.
2. Follow the installation process. Under "Software Selection" make
   sure to select "Fedora Custom Operating System" and do not choose
   additional groups or packages.
3. After the installation is complete, reboot into the freshly
   installed system and log in as your normal user, i.e., not
   `root`. Make sure `sudo` is available for you.
4. Run the following commands to download the deployment script and
   make it executable:
``` bash
curl -L https://raw.githubusercontent.com/ludwigd/fedora-plus-sway/main/install.sh -o install.sh
chmod +x install.sh
```
5. Run `./install.sh` to see available groups and patterns.
6. Run `sudo ./install.sh <group|pattern>` to install. 
