#!/bin/bash
set -euo  pipefail

# Only root can run this script
[ $UID -eq 0 ] || exit 1

# Ensure the system is up to date
dnf update -y --refresh

# Handy standard tools
dnf -y install \
    @Standard \
    vim-enhanced

# Basic Desktop
dnf -y install \
    clipman \
    foot \
    gammastep \
    grim \
    i3status \
    jq \
    kanshi \
    light \
    mate-polkit \
    python3-i3ipc \
    sway \
    wev \
    wofi \
    xlsclients \
    xorg-x11-server-Xwayland

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

# Audio, Bluetooth and Network
dnf -y install \
    bluez \
    gnome-keyring \
    gnome-keyring-pam \
    iwlwifi-mvm-firmware \
    NetworkManager-openvpn \
    NetworkManager-openvpn-gnome \
    NetworkManager-wifi \
    nm-connection-editor \
    nm-connection-editor-desktop \
    openssl \
    pavucontrol \
    pipewire \
    pipewire-pulseaudio \
    playerctl \
    pulseaudio-utils

# Printing
dnf -y install \
    cups \
    ghostscript \
    hplip \
    system-config-printer \
    --exclude PackageKit,PackageKit-glib

# Extra packages
dnf -y install \
    adwaita-gtk2-theme \
    adwaita-icon-theme \
    android-file-transfer \
    android-tools \
    borgbackup \
    distrobox \
    emacs \
    fish \
    flatpak \
    gimp \
    gnome-icon-theme \
    gnome-themes-extra \
    htop \
    imv \
    inkscape \
    lxmenu-data \
    lynx \
    mutt \
    pcmanfm \
    podman \
    powertop \
    sshfs \
    virt-manager \
    xournalpp \
    xsane \
    zathura \
    zathura-plugins-all \
    zathura-fish-completion

# (Kernel) Development Tools
dnf -y install \
    autoconf \
    automake \
    bc \
    binutils \
    bison \
    cargo \
    cmake \
    ctags \
    dwarves \
    elfutils-libelf-devel \
    flex \
    gcc \
    gcc-c++ \
    gdb \
    git \
    git-email \
    glibc-devel \
    java-latest-openjdk \
    java-latest-openjdk-devel \
    javacc \
    make \
    ncurses-devel \
    openssl-devel \
    patch \
    patchutils \
    python3 \
    python3-pip \
    python3-virtualenv \
    rust \
    strace \
    zstd

# TeXlive and publishing
dnf -y install \
    asciidoctor \
    aspell \
    aspell-de \
    aspell-en \
    hunspell \
    hunspell-de \
    ImageMagick \
    pandoc \
    rubygem-asciidoctor-pdf \
    rubygem-rouge \
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

# Add and enable Flathub
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-modify --enable flathub

# A word about flatpaks: While I prefer distro-provided packages, some
# are not available in Fedora (mpv, Bitwarden) or are not working as
# intended because of missing codecs, e.g., Quodlibet, Firefox,
# Chromium. LibreOffice is installed as a flatpak because I do not
# trust the documents I have to process with it and hence reduce the
# risk of local compromise by sandboxing LibreOffice. Okular, when
# installed as RPM, would draw in a lot of KDE dependencies. As I use
# it rarely and only for annotating PDFs (otherwise I use Zathura),
# the Flatpak comes in handy.

# Install some Flatpaks ...
flatpak install -y flathub \
    com.bitwarden.desktop \
    io.github.quodlibet.QuodLibet \
    io.mpv.Mpv \
    org.chromium.Chromium \
    org.kde.okular \
    org.libreoffice.LibreOffice \
    org.mozilla.firefox

# ... and alter them
flatpak override \
    --unshare=network \
    --nosocket=pulseaudio \
    --socket=cups \
    --nofilesystem=host \
    --filesystem=home \
    org.libreoffice.LibreOffice

flatpak override \
    --env=MOZ_ENABLE_WAYLAND=1 \
    org.mozilla.firefox

# Rebuild initramfs
dracut -f

# Restart
systemctl reboot
