#!/bin/bash

# Memeriksa jika pengguna adalah root atau memiliki akses sudo
if [[ $EUID -eq 0 ]]; then
    # Jika root, jalankan apt update dan apt upgrade
    apt update && apt upgrade -y && apt install libcurl4-openssl-dev libssl-dev libjansson-dev automake autotools-dev build-essential git -y
else
    # Jika bukan root, periksa jika pengguna memiliki akses sudo
    if command -v sudo >/dev/null; then
        sudo apt update && sudo apt upgrade -y && sudo apt install libcurl4-openssl-dev libssl-dev libjansson-dev automake autotools-dev build-essential git -y
    else
        # Jika tidak ada akses sudo, periksa jika paket-paket sudah terinstal
        required_packages=("libcurl4-openssl-dev" "libssl-dev" "libjansson-dev" "automake" "autotools-dev" "build-essential" "git")

        missing_packages=()
        for package in "${required_packages[@]}"; do
            if ! dpkg -l | grep -q "^ii.*$package "; then
                missing_packages+=("$package")
            fi
        done

        if [[ ${#missing_packages[@]} -gt 0 ]]; then
            echo "Paket-paket berikut belum terinstal: ${missing_packages[*]}"
            echo "Silakan instal paket-paket ini terlebih dahulu."
            exit 1
        fi
    fi
fi


# Mengidentifikasi arsitektur sistem
arch=$(uname -m)

# Menentukan URL repositori GitHub berdasarkan arsitektur
if [[ "$arch" == "aarch64" || "$arch" == "armv7l" ]]; then
    branch="ARM"
elif [[ "$arch" == "x86_64" ]]; then
    branch="Verus2.2"
fi

# Mengunduh dan menginstal ccminer dari branch yang sesuai
cd ~
git clone --single-branch -b $branch https://github.com/monkins1010/ccminer.git
cd ccminer

# Menjalankan build.sh, dan jika ada kesalahan, keluar dengan pesan kesalahan
if ! bash build.sh; then
    echo "Error: Gagal menjalankan build.sh."
    exit 1
fi

# Menjalankan make, dan jika ada kesalahan, keluar dengan pesan kesalahan
if ! make; then
    echo "Error: Gagal menjalankan make."
    exit 1
fi

cd ~

# Konfigurasi autorun.sh
echo -e "contoh: \e[92mRW7abSx7vi8GgYpsp92fA5Nq1LezcxJTAR\e[0m"
echo -n "Masukkan WALLETADDRESS: "
read wallet

echo -e "contoh: \e[92mvps1\e[0m"
echo -n "Masukkan nama worker: "
read worker

cat <<EOL > autorun.sh
#!/bin/bash

./ccminer/ccminer -a verus -o stratum+tcp://ap.luckpool.net:3960 -u $wallet.$worker -p x -t 3
EOL

# Memberikan hak eksekusi ke autorun.sh
chmod +x autorun.sh

# Menampilkan pesan bahwa kompilasi berhasil
echo "Kompilasi ccminer berhasil."

# Menanyakan pengguna apakah ingin menjalankan autorun.sh
while true; do
    echo -n "Apakah Anda ingin menjalankan program sekarang? (Y/N): "
    read yn
    case $yn in
        [Yy]* )
            # Menjalankan autorun.sh dalam latar belakang dengan nohup
            nohup bash autorun.sh &
            echo "Program telah dijalankan dalam latar belakang."
            break;;
        [Nn]* )
            echo "Terima kasih. Anda dapat menjalankan program nanti dengan menjalankan autorun.sh."
            exit;;
        * ) echo "Harap jawab dengan Y (Ya) atau N (Tidak).";;
    esac
done

rm ccminer-install.sh