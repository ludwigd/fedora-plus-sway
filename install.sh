#!/bin/bash
set -eo  pipefail

# Wifi-support and basic networking tools
subtask_network () {
    dnf -y install \
	bluez \
	iwlwifi-mvm-firmware \
	NetworkManager-openvpn \
	NetworkManager-openvpn-gnome \
	NetworkManager-wifi \
	nm-connection-editor \
	nm-connection-editor-desktop
}

# Install pipewire along with some tools
subtask_audio () {
    dnf -y install \
	pavucontrol \
	pipewire \
	pipewire-pulseaudio \
	playerctl \
	pulseaudio-utils
}

# Printing support
subtask_printing () {
    dnf -y install \
	cups \
	ghostscript \
	hplip \
	system-config-printer \
	--exclude PackageKit,PackageKit-glib
}

# Fonts
subtask_fonts () {
    dnf -y install \
	dejavu-sans-fonts \
	dejavu-sans-mono-fonts \
	dejavu-serif-fonts \
	fontawesome-fonts \
	fontconfig \
	google-noto-emoji-color-fonts \
	google-noto-sans-cjk-ttc-fonts \
	jetbrains-mono-fonts-all \
	liberation-mono-fonts \
	liberation-sans-fonts \
	liberation-serif-fonts
}

# Desktop
task_desktop () {
    subtask_network
    subtast_audio
    subtask_fonts
    subtask_printing

    # Repo for swaycaffeine and yaws
    dnf -y copr enable ludwigd/sway-supplemental

    dnf -y install \
	@Standard \
	clipman \
	desktop-backgrounds-compat \
	fish \
	gammastep \
	git-core \
	gnome-keyring \
	gnome-keyring-pam \
	i3status \
	kanshi \
	light \
	mate-polkit \
	rofi-wayland \
	sway \
	swaybg \
	swaycaffeine \
	swayidle \
	swaylock \
	vim-enhanced \
	wev \
	xlsclients \
	yaws
}

# Extra desktop apps
task_apps () {
    dnf -y install \
	adwaita-gtk2-theme \
	adwaita-icon-theme \
	android-file-transfer \
	android-tools \
	borgbackup \
	distrobox \
	emacs \
	flatpak \
	gnome-icon-theme \
	gnome-themes-extra \
	htop \
	imv \
	lynx \
	mutt \
	podman \
	powertop \
	ranger \
	sshfs \
	thunar \
	udiskie \
	virt-manager \
	xsane \
	zathura \
	zathura-plugins-all \
	zathura-fish-completion

    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak remote-modify --enable flathub
	
    flatpak install -y flathub \
	    com.github.xournalpp.xournalpp \
	    io.github.quodlibet.QuodLibet \
	    io.mpv.Mpv \
	    org.chromium.Chromium \
	    org.gimp.GIMP \
	    org.inkscape.Inkscape \
	    org.keepassxc.KeePassXC \
	    org.libreoffice.LibreOffice \
	    org.mozilla.firefox
}

# Development Tools
task_development () {
    dnf -y install \
	autoconf \
	automake \
	bc \
	binutils \
	bison \
	cargo \
	cmake \
	ctags \
	flex \
	gcc \
	gcc-c++ \
	gdb \
	git \
	glibc-devel \
	java-latest-openjdk \
	java-latest-openjdk-devel \
	javacc \
	make \
	patch \
	patchutils \
	python3 \
	python3-pip \
	python3-virtualenv \
	rust \
	strace \
	zstd
}

# TeXlive and publishing
task_publishing () {
    # Note: This will also install some GUI programs not listed here
    # explicitly. Maybe I should open a bug report aksing to make them
    # weak dependencies (they are in Debian).
    #
    # - inkscape is required by texlive-xput which is part of the texlive-collection-pictures
    # - mupdf is required by texlive-dvisvgm which is part of the texlive-collection-binextra
    #
    # This means that we end up having two versions of inkscape
    # installed (dnf & flatpak). We will take care of that by hiding
    # the .desktop file for the dnf version on a per-user level (hint:
    # dotfiles).
    dnf -y install \
	aspell \
	aspell-de \
	aspell-en \
	hunspell \
	hunspell-de \
	ImageMagick \
	pandoc \
	texlive-collection-basic \
	texlive-collection-bibtexextra \
	texlive-collection-binextra \
	texlive-collection-context \
	texlive-collection-fontsextra \
	texlive-collection-fontsrecommended \
	texlive-collection-fontutils \
	texlive-collection-formatsextra \
	texlive-collection-langenglish \
	texlive-collection-langgerman \
	texlive-collection-latex \
	texlive-collection-latexextra \
	texlive-collection-latexrecommended \
	texlive-collection-luatex \
	texlive-collection-mathscience \
	texlive-collection-metapost \
	texlive-collection-pictures \
	texlive-collection-plaingeneric \
	texlive-collection-pstricks \
	texlive-collection-publishers \
	texlive-collection-xetex \
	texstudio \
	xfig \
	--exclude evince
}

# Updates
task_update () {
    dnf update -y --refresh
    if [[ -f "/usr/bin/flatpak" ]]; then
	flatpak -y update
    fi
}

# Dotfiles
task_dotfiles () {
    # Check dependencies
    if [[ ! $(which git) ]]; then
	exit 1
    fi
    
    # Clone the repository
    dotfiles=$HOME/.dotfiles
    git clone --bare https://github.com/ludwigd/dotfiles $dotfiles

    # Manage dotfiles the openSUSE way
    # See: https://news.opensuse.org/2020/03/27/Manage-dotfiles-with-Git/
    pushd .
    cd $HOME
    git --git-dir=$dotfiles --work-tree=$HOME checkout -f
    popd
}

usage () {
    echo "install.sh <task>"
    echo "  This script installs my Fedora+Sway environment."

    echo -e "\\nAvailable tasks:"
    echo "  update                  - install updates (dnf + flatpak)"
    echo "  desktop                 - sway plus tools, network, audio, printing"
    echo "  apps                    - desktop apps"
    echo "  development             - some programming languages and tools"
    echo "  publishing              - an opinionated selection of TeXlive collections and tools"
    echo "  dotfiles                - install dotfiles (requires desktop)"
    echo "  everything              - all of the above + some vodoo + reboot"
}

assure_root () {
    if [ $UID -ne 0 ]; then
	echo "You must be root to install software."
	exit 1
    fi
}

main () {
    local cmd=$1

    if [[ -z "$cmd" ]]; then
	usage
    elif [[ $cmd == "desktop" ]]; then
	assure_root
	task_desktop
    elif [[ $cmd == "apps" ]]; then
	assure_root
	task_apps
    elif [[ $cmd == "development" ]]; then
	assure_root
	task_development
    elif [[ $cmd == "publishing" ]]; then
	assure_root
	task_publishing
    elif [[ $cmd == "dotfiles" ]]; then
	if [ $UID -ne 0 ]; then
	    task_dotfiles
	else
	    echo "You should NOT be root for this task."
	    exit 1
	fi
    elif [[ $cmd == "update" ]]; then
	assure_root
	task_update
    elif [[ $cmd == "everything" ]]; then
	assure_root
	task_update
	task_desktop
	task_apps
	task_development
	task_publishing

	# Who am I?
	ME=$(who am i | cut -f1 -d" ")

	# Add user to libvirt group
	usermod -aG libvirt $ME

	# Disable Red Hat Graphical Boot
	grubby --remove-args=rhgb --update-kernel=ALL

	# Install dotfiles
	sudo -u $ME ./"$0" dotfiles

	# Reboot
	systemctl reboot
    else
	usage
    fi
}

main "$@"
