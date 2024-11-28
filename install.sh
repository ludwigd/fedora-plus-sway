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
    subtask_audio
    subtask_fonts
    subtask_printing

    # Repo for swaycaffeine and yaws
    dnf -y copr enable ludwigd/sway-supplemental

    dnf -y install \
        @standard \
        brightnessctl \
        clipman \
        desktop-backgrounds-compat \
        fish \
        gammastep \
        git-core \
        gnome-keyring \
        gnome-keyring-pam \
        i3status \
        kanshi \
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
    dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
    
    dnf config-manager setopt fedora-cisco-openh264.enabled=1

    dnf -y install --best --allowerasing \
        ffmpeg \
        gstreamer1-plugin-libav \
        mesa-va-drivers-freeworld \
        mesa-vdpau-drivers-freeworld
    
    dnf -y install \
        adwaita-icon-theme \
        aerc \
        android-tools \
        borgbackup \
        chromium \
        distrobox \
        emacs \
        firefox \
        gimp \
        gvfs-mtp \
        htop \
        imv \
        keepassxc \
        mpv \
        podman \
        powertop \
        quodlibet \
        sshfs \
        thunar \
        virt-manager \
        xsane \
        zathura \
        zathura-fish-completion \
        zathura-plugins-all
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
task_update () {
    dnf update -y --refresh
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
    echo "  update                  - install updates (dnf only)"
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
