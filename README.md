# Fedora Plus Sway

Deployment script for a Fedora Linux desktop utilizing the Sway window
manager.

The package selection is somewhat opinionated and may not work for you
personally (applications, tools) or even your system (firmware,
printer drivers).

## Usage

1. Download the /Everything/ ISO from
   [here](https://alt.fedoraproject.org/) and burn it to CD/DVD/USB.
2. Follow the installation process. Under "Software Selection" make
   sure to select "Fedora Custom Operating System" and do not choose
   additional groups or packages.
3. After the installation is complete, reboot into the freshly
   installed system and log in as your normal user, i.e., not `root`.
4. Run the following commands to download the deployment script and
   make it executable:
``` bash
curl -L https://raw.githubusercontent.com/ludwigd/fedora-plus-sway/main/install.sh -o install.sh
chmod +x install.sh
```
5. Run `./install.sh` to see available options.
