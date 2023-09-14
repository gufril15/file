#!/bin/sh
#
# install script for eggdrop
#

local_dir="$HOME/.local"

# Periksa apakah folder .local ada
if [ ! -d "$local_dir" ]; then
    echo "Folder $local_dir tidak ada."
    exit 1  # Keluar dengan status kesalahan
fi

# Aktifkan mode eksekusi berhenti jika ada kesalahan
set -e

echo "Install tcl8.6.12"
cd "$local_dir"
wget https://prdownloads.sourceforge.net/tcl/tcl8.6.12-src.tar.gz
tar -xf tcl8.6.12-src.tar.gz
cd tcl8.6.12/unix
./configure --prefix="$HOME/.local"
make && make install

# Cek apakah proses sebelumnya berjalan dengan sukses
if [ $? -eq 0 ]; then
    echo "Instalasi tcl8.6.12 selesai."
    
    echo "Install tcllib-1.20"
    cd "$local_dir"
    wget https://core.tcl-lang.org/tcllib/uv/tcllib-1.20.tar.gz
    tar -xf tcllib-1.20.tar.gz
    cd tcllib-1.20
    ./configure --prefix="$HOME/.local"
    make && make install

    # Cek apakah proses sebelumnya berjalan dengan sukses
    if [ $? -eq 0 ]; then
        echo "Instalasi tcllib-1.20 selesai."
    else
        echo "Terjadi kesalahan selama instalasi tcllib-1.20."
    fi
else
    echo "Terjadi kesalahan selama instalasi tcl8.6.12."
fi

# Menonaktifkan mode eksekusi berhenti jika sampai di sini tanpa kesalahan
set +e

if ! grep -q 'export PATH="$PATH:$HOME/.local"' "$HOME/.bashrc"; then
    # Jika tidak ada, tambahkan PATH tersebut ke .bashrc
    echo 'export PATH="$PATH:$HOME/.local"' >> "$HOME/.bashrc"
    echo "PATH ke \$HOME/.local ditambahkan ke .bashrc."
fi
