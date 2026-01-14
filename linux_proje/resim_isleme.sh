#!/bin/bash

# =================================================================
# Gelişmiş Pardus Resim Editörü
# =================================================================

RESIM_KLASORU="$HOME/Masaüstü/linux_proje/resim"

# 1. Resim Bilgilerini Gösteren Fonksiyon
resim_bilgi_goster() {
    bilgi=$(identify -format "Dosya: %f\nFormat: %m\nBoyut: %wx%h\nRenk Alanı: %C" "$1")
    yad --info --title="Resim Bilgileri" --text="$bilgi" --width=350 --button="Tamam":0
}

# 2. Ana İşlem Motoru
resim_islem_motoru() {
    local girdi="$1"
    local islem="$2"
    local ekstra_param="$3" # Oran (%50) veya format (png) bilgisi
    
    local klasor=$(dirname "$girdi")
    local dosya_adi=$(basename "${girdi%.*}")
    local zaman=$(date +%M%S) 
    local cikti_yolu=""

    case "$islem" in
        *"Boyutlandır"*)
            local oran="${ekstra_param:-50%}"
            local oran_temiz=$(echo "$oran" | tr -d '%')
            cikti_yolu="$klasor/boyutlu_${oran_temiz}_${zaman}_$dosya_adi.jpg"
            convert "$girdi" -resize "$oran" "$cikti_yolu"
            ;;
        *"Format Değiştir"*)
            local ext="${ekstra_param:-png}"
            cikti_yolu="$klasor/donusturulmus_${zaman}_${dosya_adi}.${ext}"
            convert "$girdi" "$cikti_yolu"
            ;;
        *"Döndür"*)
            cikti_yolu="$klasor/dondurulmus_${zaman}_$dosya_adi.jpg"
            convert "$girdi" -rotate 90 "$cikti_yolu"
            ;;
        *"Siyah-Beyaz"*)
            cikti_yolu="$klasor/s_b_${zaman}_$dosya_adi.jpg"
            convert "$girdi" -colorspace Gray "$cikti_yolu"
            ;;
        *"Karakalem"*)
            cikti_yolu="$klasor/karakalem_${zaman}_$dosya_adi.jpg"
            convert "$girdi" -colorspace gray -edge 1 -negate "$cikti_yolu"
            ;;
    esac
}

# 3. Toplu İşlem Fonksiyonu
toplu_islem_yap() {
    local islem="$1"
    local parametre="$2"
    local mod="$3"
    
    # Klasör kontrolü (Eğer bu klasör yoksa hata verir)
    if [ ! -d "$RESIM_KLASORU" ]; then
        hata_msj="HATA: '$RESIM_KLASORU' klasörü bulunamadı!\nLütfen Masaüstünde 'linux_proje' ve içinde 'resim' klasörü olduğundan emin olun."
        [[ "$mod" == "GUI" ]] && yad --error --text="$hata_msj" || whiptail --msgbox "$hata_msj" 10 60
        return
    fi

    # Boş döngü hatasını önlemek için nullglob açıyoruz
    shopt -s nullglob
    count=0
    
    # Klasördeki tüm resim formatlarını tara
    for f in "$RESIM_KLASORU"/*.{jpg,png,webp,jpeg,JPG,PNG,WEBP}; do
        if [ -f "$f" ]; then
            resim_islem_motoru "$f" "$islem" "$parametre"
            ((count++))
        fi
    done
    shopt -u nullglob

    # Raporlama
    if [[ "$mod" == "GUI" ]]; then
        if [ $count -eq 0 ]; then
            yad --error --text="Klasörde hiç resim dosyası yok!" --width=300
        else
            yad --info --text="İşlem Tamamlandı!\nToplam $count dosya işlendi." --width=300
        fi
    else
        whiptail --msgbox "İşlem Tamamlandı! Toplam $count dosya işlendi." 10 40
    fi
}

# --- GUI MODU ---
gui_modu() {
    SECIM=$(yad --width=450 --height=500 --list --center --title="Pardus Resim Editörü" \
        --window-icon="applications-graphics" \
        --column="İşlem Listesi" \
        "Resim Bilgilerini Göster" "Boyutlandır (Özel Oran)" "Format Değiştir" \
        "Döndür (90 Derece)" "Siyah-Beyaz Yap" "Karakalem Efekti" \
        "TOPLU İŞLEM (Klasördeki Tüm Resimler)" --button="İptal":1 --button="Uygula":0)

    [[ -z "$SECIM" ]] && return

    # Seçimden gelen | karakteri siliyoruz
    SECIM=$(echo "$SECIM" | cut -d'|' -f1)

    if [[ "$SECIM" == *"TOPLU"* ]]; then
        T_ISLEM=$(yad --width=300 --list --center --title="Toplu İşlem" --column="İşlem" "Boyutlandır" "Format Değiştir" "Döndür" "Siyah-Beyaz" "Karakalem")
        T_ISLEM=$(echo "$T_ISLEM" | cut -d'|' -f1)
        
        if [[ "$T_ISLEM" == *"Boyutlandır"* ]]; then
            ORAN=$(yad --entry --text="Oran (Örn: 50%)" --entry-text="50%")
            toplu_islem_yap "Boyutlandır" "$ORAN" "GUI"
        elif [[ "$T_ISLEM" == *"Format"* ]]; then
            F_SEC=$(yad --list --column="Format" "PNG" "JPG" "WEBP")
            F_EXT=$(echo "$F_SEC" | cut -d'|' -f1 | tr '[:upper:]' '[:lower:]')
            toplu_islem_yap "Format Değiştir" "$F_EXT" "GUI"
        else
            toplu_islem_yap "$T_ISLEM" "" "GUI"
        fi

    elif [[ "$SECIM" == *"Boyutlandır"* ]]; then
        RESIM=$(yad --file-selection --title="Resim Seç")
        ORAN=$(yad --entry --text="Oran:" --entry-text="50%")
        resim_islem_motoru "$RESIM" "Boyutlandır" "$ORAN"
        yad --info --text="İşlem Tamamlandı"
    
    elif [[ "$SECIM" == *"Format Değiştir"* ]]; then
        RESIM=$(yad --file-selection --title="Resim Seç")
        F_SEC=$(yad --list --column="Format" "PNG" "JPG" "WEBP")
        F_EXT=$(echo "$F_SEC" | cut -d'|' -f1 | tr '[:upper:]' '[:lower:]')
        resim_islem_motoru "$RESIM" "Format Değiştir" "$F_EXT"
        yad --info --text="İşlem Tamamlandı"

    elif [[ "$SECIM" == *"Bilgileri"* ]]; then
        RESIM=$(yad --file-selection --title="Resim Seç")
        resim_bilgi_goster "$RESIM"
    else
        RESIM=$(yad --file-selection --title="Resim Seç")
        resim_islem_motoru "$RESIM" "$SECIM"
        yad --info --text="İşlem Tamamlandı"
    fi
}

# --- TUI MODU ---
tui_modu() {
    SECIM=$(whiptail --title "TUI: İşlem Menüsü" --menu "Yapılacak işlemi seçin:" 20 60 7 \
        "1" "Boyutlandır (Özel Oran)" \
        "2" "Format Değiştir (PNG, JPG, WEBP)" \
        "3" "Döndür (90 Derece)" \
        "4" "Siyah-Beyaz Yap" \
        "5" "Karakalem Efekti" \
        "6" "Toplu İşlem (Tüm Klasör)" 3>&1 1>&2 2>&3)

    [ $? -ne 0 ] && return

    if [ "$SECIM" = "6" ]; then
        # TOPLU İŞLEM
        T_SEC=$(whiptail --title "Toplu İşlem" --menu "Tüm klasöre ne yapılsın?" 15 60 5 \
            "1" "Boyutlandır" "2" "Format Değiştir" "3" "Döndür" "4" "Siyah-Beyaz" "5" "Karakalem" 3>&1 1>&2 2>&3)
        
        case "$T_SEC" in
            1) ORAN=$(whiptail --inputbox "Oran (Örn: 40%):" 10 60 "50%" 3>&1 1>&2 2>&3); toplu_islem_yap "Boyutlandır" "$ORAN" "TUI" ;;
            2) F_SEC=$(whiptail --title "Format" --menu "Hedef:" 15 60 3 "png" "PNG" "jpg" "JPG" "webp" "WEBP" 3>&1 1>&2 2>&3); toplu_islem_yap "Format Değiştir" "$F_SEC" "TUI" ;;
            3) toplu_islem_yap "Döndür" "" "TUI" ;;
            4) toplu_islem_yap "Siyah-Beyaz" "" "TUI" ;;
            5) toplu_islem_yap "Karakalem" "" "TUI" ;;
        esac
    else
        # TEKLİ İŞLEM
        DOSYA_ADI=$(whiptail --title "Dosya Seçimi" --inputbox "Dosya adı (resim/ klasöründeki):\n(Örnek: boru.jpg)" 10 60 3>&1 1>&2 2>&3)
        [ -z "$DOSYA_ADI" ] && return
        
        # TUI için de yeni klasör yolunu kullanıyoruz
        RESIM="$RESIM_KLASORU/$DOSYA_ADI"

        case "$SECIM" in
            1) ORAN=$(whiptail --inputbox "Oran:" 10 60 "50%" 3>&1 1>&2 2>&3); resim_islem_motoru "$RESIM" "Boyutlandır" "$ORAN" ;;
            2) F_SEC=$(whiptail --menu "Format:" 15 60 3 "png" "PNG" "jpg" "JPG" "webp" "WEBP" 3>&1 1>&2 2>&3); resim_islem_motoru "$RESIM" "Format Değiştir" "$F_SEC" ;;
            3) resim_islem_motoru "$RESIM" "Döndür" ;;
            4) resim_islem_motoru "$RESIM" "Siyah-Beyaz" ;;
            5) resim_islem_motoru "$RESIM" "Karakalem" ;;
        esac
        whiptail --msgbox "İşlem bitti!" 10 30
    fi
}

# --- BAŞLANGIÇ EKRANI ---
MOD=$(yad --title="Pardus Proje Giriş" --width=500 --height=150 --center \
    --window-icon="preferences-desktop-wallpaper" --image="applications-graphics" \
    --text="<span font='14'><b>Pardus Resim İşleme Merkezi</b></span>\n\nLütfen mod seçiniz:" \
    --button="🎨 GUI (Görsel)":0 --button="🖥️ TUI (Terminal)":1)

if [ $? -eq 0 ]; then gui_modu; else tui_modu; fi
