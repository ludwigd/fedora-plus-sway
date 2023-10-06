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

# Very basic desktop, just sway and vim along with audio and wifi support
task_basic_desktop () {
    subtask_network
    subtask_audio
    
    dnf -y install \
	@Standard \
	sway \
	vim-enhanced
}

# An enhanced desktop environment
task_enhanced_desktop () {
    task_basic_desktop
    subtask_fonts
    subtask_printing
    
    dnf -y install \
	clipman \
	gammastep \
	i3status \
	kanshi \
	light \
	mate-polkit \
	rofi \
	wev \
	xlsclients

    dnf -y copr enable ludwigd/sway-supplemental
    dnf -y install \
	swaycaffeine \
	yaws
}

# Extra desktop apps
task_apps () {
    local flatpak=$1
    
    dnf -y install \
	adwaita-gtk2-theme \
	adwaita-icon-theme \
	android-file-transfer \
	android-tools \
	borgbackup \
	distrobox \
	emacs \
	fish \
	git-core \
	gnome-icon-theme \
	gnome-keyring \
	gnome-keyring-pam \
	gnome-themes-extra \
	htop \
	imv \
	lynx \
	lxmenu-data \
	mutt \
	pcmanfm \
	podman \
	powertop \
	sshfs \
	virt-manager \
	xsane \
	zathura \
	zathura-plugins-all \
	zathura-fish-completion

    if [[ -z "$flatpak" ]]; then
	dnf -y install \
	    chromium \
	    ffmpeg-free \
	    firefox \
	    gimp \
	    gstreamer1-plugin-libav \
	    inkscape \
	    keepassxc \
	    libreoffice \
	    libreoffice-x11 \
	    mozilla-openh264 \
	    mpv \
	    quodlibet \
	    xournalpp
    elif [[ $flatpak == "flatpak" ]]; then
	dnf -y install flatpak
	
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
	
	flatpak override \
		--env=MOZ_ENABLE_WAYLAND=1 \
		org.mozilla.firefox
    else
	echo "Unknown parameter '$flatpak'. Must be empty or 'flatpak'."
	exit 1
    fi
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
task_update_system () {
    dnf update -y --refresh
    if [[ -f "/usr/bin/flatpak" ]]; then
	flatpak -y update
    fi
}

# Dotfiles
task_dotfiles () {
    # Check dependencies
    if [[ ! $(which {git,python3}) ]]; then
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

    echo -e "\\nTasks:"
    echo "  basic                   - just sway and vim (incl. audio and wifi support)"
    echo "  enhanced                - an enhanced environment compared to basic"
    echo "  apps [flatpak]          - desktop apps"
    echo "  development             - some programming languages and tools"
    echo "  publishing              - an opinionated selection of TeXlive collections and tools"
    echo "  everything [flatpak]    - enhanced + apps +  development + publishing"
    echo "  update                  - install updates (dnf + flatpak)"
    echo "  dotfiles                - install dotfiles (requires enhanced + apps)"
    echo "  unattended [flatpak]    - update + everything + dotfiles + reboot"
    
    echo -e "\\nApplications affected by the flatpak parameter:"
    echo "  Chromium"
    echo "  Firefox"
    echo "  GIMP"
    echo "  Inkscape"
    echo "  KeepassXC"
    echo "  LibreOffice"
    echo "  mpv"
    echo "  Quodlibet"
    echo "  Xournal++"
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
    elif [[ $cmd == "basic" ]]; then
	assure_root
	task_basic_desktop
    elif [[ $cmd == "enhanced" ]]; then
	assure_root
	task_enhanced_desktop
    elif [[ $cmd == "apps" ]]; then
	assure_root
	task_apps "$2"
    elif [[ $cmd == "development" ]]; then
	assure_root
	task_development
    elif [[ $cmd == "publishing" ]]; then
	assure_root
	task_publishing
    elif [[ $cmd == "everything" ]]; then
	assure_root
	task_enhanced_desktop
	task_apps "$2"
	task_development
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
	task_update_system
    elif [[ $cmd == "unattended" ]]; then
	assure_root
	tast_update_system
	task_enhanced_desktop
	task_apps "$2"
	task_development
	task_publishing
	sudo -u $(who am i | cut -f1 -d" ") ./"$0" dotfiles
	systemctl reboot
    else
	usage
    fi
}

main "$@"
