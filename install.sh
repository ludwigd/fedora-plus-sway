#!/bin/bash
set -eo  pipefail

# Desktop
task_desktop () {
    # Enable repo for swaycaffeine and yaws
    dnf -y copr enable ludwigd/sway-supplemental

    # Basic desktop
    dnf -y install \
        @hardware-support \
        @standard \
        bluez \
        brightnessctl \
        clipman \
        fish \
        foot\
        gammastep \
        git-core \
        gnome-keyring \
        gnome-keyring-pam \
        i3status \
        kanshi \
        mate-polkit \
        NetworkManager-wifi \
        nm-connection-editor \
        nm-connection-editor-desktop \
        pavucontrol \
        pipewire \
        pipewire-pulseaudio \
        playerctl \
        pulseaudio-utils \
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

    # Fonts
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

    # Printing
    dnf -y install \
        @printing \
        system-config-printer \
        --exclude PackageKit,PackageKit-glib,samba-client
}

# Extra desktop apps and enhanced experience
task_apps () {
    local gpu=$1
    
    # Enable RPMfusion
    dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

    # Enable repo for openh264
    if (( $(rpm -E %fedora) < 41 )); then
        dnf config-manager --enable fedora-cisco-openh264
    else
        dnf config-manager setopt fedora-cisco-openh264.enabled=1
    fi

    # Install full ffmpeg and mesa from RPMfusion
    local pkgs=( ffmpeg gstreamer1-plugin-libav libavcodec-freeworld )
    case $gpu in
        "intel")
            pkgs+=( libva-intel-driver intel-media-driver )
            ;;
        "amd")
            ;&
        "*")
            pkgs+=( mesa-va-drivers-freeworld mesa-vdpau-drivers-freeworld )
            ;;
    esac
    dnf -y install --best --allowerasing "${pkgs[@]}"

    # Apps and tools
    dnf -y install \
        aerc \
        android-tools \
        borgbackup \
        chromium \
        emacs \
        firefox \
        gimp \
        gvfs-mtp \
        htop \
        imv \
        irssi \
        keepassxc \
        mpv \
        podman \
        powertop \
        quodlibet \
        ranger \
        sshfs \
        thunar \
        tuned \
        virt-manager \
        xsane \
        zathura \
        zathura-fish-completion \
        zathura-plugins-all

    # Enable tuned
    systemctl enable tuned
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
    echo -e "install.sh <task> [\e[4mamd\e[0m|intel]"
    echo "  This script installs my Fedora+Sway environment."

    echo -e "\\nAvailable tasks:"
    echo "  update          - install updates (dnf only)"
    echo "  desktop         - sway plus tools, network, audio, printing"
    echo "  apps            - desktop apps"
    echo "  development     - some programming languages and tools"
    echo "  publishing      - an opinionated selection of TeXlive collections and tools"
    echo "  dotfiles        - install dotfiles (requires desktop)"
    echo "  unattended      - all of the above + some vodoo + reboot"
}

assure_root () {
    if [ $UID -ne 0 ]; then
        echo "You must be root to install software."
        exit 1
    fi
}

main () {
    local cmd=$1
    local gpu=$2

    if [[ -z "$cmd" ]]; then
        usage
    elif [[ $cmd == "desktop" ]]; then
        assure_root
        task_desktop
    elif [[ $cmd == "apps" ]]; then
        assure_root
        task_apps "$gpu"
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
    elif [[ $cmd == "unattended" ]]; then
        assure_root
        task_update
        task_desktop
        task_apps "$gpu"
        task_development
        task_publishing

        # Who am I?
        ME=$(who am i | cut -f1 -d" ")

        # Install dotfiles
        sudo -u $ME ./"$0" dotfiles

        # Reboot
        systemctl reboot
    else
        usage
    fi
}

main "$@"
