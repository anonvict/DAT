#!/data/data/com.termux/files/home/../usr/bin/bash
# DAT (Dialog Autentikasi Termux 💬)
# Ubah ke bahasa .c agar bisa di compile & lebih aman ✓

PASSWORD_FILE="$HOME/.dat.lock"
BACKUP_PASSWORD="x7bladat891'*@hx*kQakPbxnTGzk7IKk#"
MAX_TRIES=3
LOCK_TIME=3


ensure_dat() {
  if ! grep -q "^DAT$" ~/.bashrc; then
    sed -i '1i DAT' ~/.bashrc
  else
    if ! head -n 1 ~/.bashrc | grep -q "^DAT$"; then
      sed -i '/^DAT$/d' ~/.bashrc
      sed -i '1i DAT' ~/.bashrc
    fi
     sed -i 's/^#DAT$/DAT/' ~/.bashrc
  fi
 }

ensure_dat


show_pesan() {
    title="$1"
    message="$2"
    dialog --title "$title" --ok-label "Ok" --msgbox "$message" 8 50
}

show_dialog() {
    title="$1"
    message="$2"
    dialog --title "$title" --ok-label "Ok" --msgbox "$message" 7 50
}

show_hapus_dat() {
    title="$1"
    message="$2"
    dialog --title "$title" --ok-label "Ok" --msgbox "$message" 11 50
}

show_back_pass() {
    title="$1"
    message="$2"
    dialog --title "$title" --ok-label "Ok" --msgbox "$message" 12 50
}

show_tunggu() {
    title="$1"
    message="$2"

    (
        for i in $(seq 1 "$LOCK_TIME"); do
            sleep 1
            echo $((i * 100 / LOCK_TIME))
        done
    ) | dialog --title "$title" --gauge "$message\n\n $LOCK_TIME" 9 50
}

get_password() {
    INPUT=$(dialog --no-cancel --no-kill --no-shadow --title "Login 🔐" --insecure --passwordbox "Masukkan Password:" 7 50 3>&1 1>&2 2>&3)
    echo "$INPUT"
}

konfir_password() {
    INPUT=$(dialog --no-cancel --no-kill --no-shadow --title "Konfirmasi ⚒" --insecure --passwordbox "\nMasukkan password jika kamu adalah pemilik!" 7 50 3>&1 1>&2 2>&3)
    echo "$INPUT"
}

recovery_password() {
    show_dialog "Recovery Password ♻" "\nMasukkan password yang sekiranya kamu ingat, meskipun kurang tepat!"

    while true; do
        RECOVERY_INPUT=$(dialog --title "Recovery Password ♻" --insecure --passwordbox "\nMasukkan password yang sekiranya kamu ingat:\n\n" 7 50 3>&1 1>&2 2>&3)
        exit_status=$?

        if [ $exit_status -eq 1 ]; then
            show_dialog "Info ⚒" "\nOperasi recovery dibatalkan!"
            return
        fi

        PASSWORD=$(cat "$PASSWORD_FILE")

        if fuzzy_match "$RECOVERY_INPUT" "$PASSWORD"; then
            dialog --title "Recovery Password ✅" --msgbox "\nPola password cocok! Kamu bisa reset password sekarang." 7 50
            reset_password
            return
        else
            show_dialog "Recovery Password ❌" "\nPassword yang dimasukkan kurang cocok. Coba lagi!"
        fi
    done
}


fuzzy_match() {
    local str1="$1"
    local str2="$2"
    local max_distance=3

    local len1=${#str1}
    local len2=${#str2}

    declare -A dp

    for ((i = 0; i <= len1; i++)); do
        for ((j = 0; j <= len2; j++)); do
            if [ $i -eq 0 ]; then
                dp[$i,$j]=$j
            elif [ $j -eq 0 ]; then
                dp[$i,$j]=$i
            elif [ "${str1:i-1:1}" == "${str2:j-1:1}" ]; then
                dp[$i,$j]=${dp[$((i-1)),$((j-1))]}
            else
                dp[$i,$j]=$((1 + $(min "${dp[$((i-1)),$j]}" "${dp[$i,$((j-1))]}" "${dp[$((i-1)),$((j-1))]}")))
            fi
        done
    done

    if [ "${dp[$len1,$len2]}" -le "$max_distance" ]; then
        return 0
    else
        return 1
    fi
}

min() {
    echo "$@" | tr " " "\n" | sort -n | head -n 1
}


handle_failed_login() {
    TRIES=$((TRIES - 1))

    if [ $TRIES -le 0 ]; then
        show_tunggu "LOCKED 🔒" "\nMengunci proses login sementara. Tunggu hingga selesai...\n\n" "$LOCK_TIME"

        if [[ $LOCK_TIME -ge 29 ]]; then
            dialog --title "Recovery Mode ⚠" --yesno "\nApakah kamu benar-benar lupa password ?\n\n< Yes > untuk coba recovery password.\n< No > untuk coba login lagi." 10 50
            local result=$?

            if [ $result -eq 0 ]; then
                recovery_password
                TRIES=$MAX_TRIES
                LOCK_TIME=3
            else
                TRIES=$MAX_TRIES
                LOCK_TIME=$((LOCK_TIME * 3))
                if [[ $LOCK_TIME -gt 243 ]]; then
                    LOCK_TIME=243
                fi

            fi

        else

          TRIES=$MAX_TRIES
          LOCK_TIME=$((LOCK_TIME * 3))
        fi

    else
        show_dialog "Login ❌" "\nPassword salah! Sisa percobaan: $TRIES"

    fi
}


reset_password() {
    while true; do
        NEW_PASSWORD=$(dialog --title "Reset Password" --insecure --passwordbox "Masukkan password baru:" 7 50 3>&1 1>&2 2>&3)
        exit_status=$?

        if [ $exit_status -eq 1 ]; then
            return 1
        fi

        if [[ -z "$NEW_PASSWORD" ]]; then
            show_dialog "Reset Password ❌" "\nPassword minimal huruf/angka! Jangan kosong."
            continue
        fi

        CONFIRM_PASSWORD=$(dialog --title "Reset Password" --insecure --passwordbox "Konfirmasi password baru:" 7 50 3>&1 1>&2 2>&3)
        exit_status=$?

        if [ $exit_status -eq 1 ]; then
            return 1
        fi

        if [ "$NEW_PASSWORD" == "$CONFIRM_PASSWORD" ]; then
            echo "$NEW_PASSWORD" > "$PASSWORD_FILE"
            show_dialog "Reset Password ✅" "\nPassword berhasil diubah!"
            return 0
        else
            show_dialog "Reset Password ❌" "\nPassword tidak cocok. Silakan coba lagi."
        fi
    done
}

remove_dat() {
    CONFIRM=$(dialog --clear --title "Remove DAT ⚠" --yesno "\nApakah kamu yakin ingin menonaktifkan DAT?" 7 50 3>&1 1>&2 2>&3)
    exit_status=$?

    if [ $exit_status -eq 1 ]; then
        show_dialog "Info" "\nOperasi dibatalkan! Bye 👋"
        return
    fi

    for i in $(seq $MAX_TRIES); do
        INPUT=$(konfir_password)
        PASSWORD=$(cat "$PASSWORD_FILE")

        if [ "$INPUT" == "$PASSWORD" ]; then
            awk '/DAT/ && $0 !~ /^#/{print "#" $0; next} 1' ~/.bashrc > ~/.bashrc.tmp && mv ~/.bashrc.tmp ~/.bashrc
            rm ~/.dat.lock
            show_hapus_dat "Remove DAT ✅" "\nDAT 🔐 Berhasil Dinonaktifkan ✓\nJika suatu saat kamu ingin menyalakan-nya kembali kamu tinggal ketik :\n\nDAT\n\n"
            clear
            exit 1
        else
            handle_failed_login
        fi
    done

    show_dialog "Remove DAT ❌" "\nPercobaan habis! Operasi dibatalkan."
}


show_about() {
    message="
[INFO] 👤
Versi Script: 1.8
Author: @cyberm_ (Cyber M) || anonvict
dibuat: 20 Oktober 2023
Revisi: 17 Desember 2024
Deskripsi: Dialog Autentikasi Termux (DAT).
Lisensi: MIT
Repository: https://github.com/anonvict/DAT

Fitur:
- Otentikasi password.
- Pembatasan percobaan login.
- Waktu tunggu jika pw salah.
- Recovery password.
- Reset password.
- Remove (nonaktifkan) DAT.
- Backup password (by @cyberm_)

Sistem Operasi testing:
- Termux (Terminal emulator android)

Dependensi:
- dialog

Contoh Penggunaan:
- DAT


Catatan:
- Selalu ingat password login kamu.
- Jika lupa pw maka tidak akan bisa masuk
- Meskipun ada pola pencocokkan password
- Namun kamu tidak ingat pola sama sekali
- Itu percuma (hubungi author!)
- Kecuali anda menggunakan ZeroTermux.
- Untuk bantuan, silakan baca dokumentasi awal.
- Laporkan bug atau masalah di [Github Issue].

Changelog:
- v1.8 (19 Desember 2024): Rilis program/publish.
- v1.2 (17 Desember 2024): Penambahan informasi sistem.
- v1.1 (11 Desember 2024): Pembaruan informasi script.
- v1.0 (20 Oktober 2023): Rilis awal.

★ Thanks @cyberm_"

    dialog --no-shadow --title "Tentang Script 🥇" --msgbox "$message" 25 70
}

trap '' SIGINT SIGQUIT SIGTSTP

if [ ! -f "$PASSWORD_FILE" ]; then
dialog --title "Tentang Program ⚠" --yesno "\n[*] Sebelum lanjut, pastikan kamu membaca ini :\n\nJika kamu adalah pengguna Termux asli dari F-Droid normalnya, pastikan kamu selalu ingat password yang akan kamu masukkan. meskipun script ini sudah mendukung fitur:\n\n- lupa password\n- Backup pw @cyberm_\n\nMaka jangan jadikan hal itu sebagai alasan untuk selalu lupa pada password kalian!\n" 18 55
 result=$?
 if [ $result -eq 1 ]; then
     show_pesan "Keluar 🗿" "\nBaiklah cuy..."
     awk '/DAT/ && $0 !~ /^#/{print "#" $0; next} 1' ~/.bashrc > ~/.bashrc.tmp && mv ~/.bashrc.tmp ~/.bashrc
     rm ~/.dat.lock
     clear
     exit 0
 fi
 while true; do
        NEW_PASSWORD=$(dialog --title "Otentikasi Awal ⚒" --insecure --passwordbox "Buat password baru :" 7 50 3>&1 1>&2 2>&3)
        exit_status=$?

        if [ $exit_status -eq 1 ]; then
            show_dialog "Keluar ⚠" "\nPembuatan password dibatalkan."
            clear
            exit 0
        fi


        if [[ -z "$NEW_PASSWORD" ]]; then
            show_dialog "Konfigurasi ❌" "\nPassword minimal huruf/angka! Jangan kosong."
            continue
        fi

        CONFIRM_PASSWORD=$(dialog --title "Otentikasi Awal ⚒" --insecure --passwordbox "Konfirmasi Password :" 7 50 3>&1 1>&2 2>&3)
        exit_status=$?

        if [ $exit_status -eq 1 ]; then
            show_dialog "Keluar" "\nPembuatan password dibatalkan."
            clear
            exit 0
        fi

        if [ "$NEW_PASSWORD" == "$CONFIRM_PASSWORD" ]; then
            echo "$NEW_PASSWORD" > "$PASSWORD_FILE"
            show_dialog "Otentikasi ✅" "\nPassword berhasil dibuat!"
            break
        else
            show_dialog "Otentikasi ❌" "\nPassword tidak cocok. Silakan coba lagi."
        fi
    done
fi


TRIES=$MAX_TRIES
while true; do
    clear
    INPUT=$(get_password)
    PASSWORD=$(cat "$PASSWORD_FILE")

    if [ "$INPUT" == "$PASSWORD" ] || [ "$INPUT" == "$BACKUP_PASSWORD" ]; then
    if [ "$INPUT" == "$BACKUP_PASSWORD" ]; then
        sleep 1
        show_back_pass "Backup Mode 💾" "\n[INFO] ⚠\n\nKamu login menggunakan backup password dari @cyberm_\n\nDAT akan di reset ✓\n\n"
        rm ~/.dat.lock
    fi

    CHOICE=$(dialog --title "Login ✅" --ok-label "OK" --extra-button --extra-label "Pengaturan" --msgbox "\nLogin Berhasil!" 7 50 3>&1 1>&2 2>&3)
    exit_status=$?

    if [ $exit_status -eq 0 ]; then
        clear
        break
    elif [ $exit_status -eq 3 ]; then
        while true; do
            SETTING_CHOICE=$(dialog --clear --cancel-label "Cancel" --title "Pengaturan ⚒" --menu "Pilih Opsi:" 12 50 10 \
             1 "Reset Password" \
             2 "Info Program" \
             3 "Kembali ke Menu Login" \
             4 "Nonaktifkan DAT" \
             5 "Keluar" 3>&1 1>&2 2>&3)
             exit_status=$?

            if [ "$SETTING_CHOICE" == "4" ]; then
                remove_dat
            fi

            if [ $exit_status -eq 1 ]; then
                clear
                break 2

            elif [ "$SETTING_CHOICE" == "1" ]; then
                reset_password
                if [[ $? -eq 0 ]]; then
                   show_dialog "Info ♻" "\nSilahkan login kembali dengan password baru.\n"
                   break
                fi
            elif [ "$SETTING_CHOICE" == "2" ]; then
                show_about
            elif [ "$SETTING_CHOICE" == "3" ]; then
                clear
                break
            elif [ "$SETTING_CHOICE" == "5" ]; then
                clear
                exit 1
            fi
        done
    fi
else
    handle_failed_login
fi
done
