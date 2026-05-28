#!/usr/bin/env bash
# QuestAlarm Oyun Editörü — web-server + hazır olunca tarayıcı aç.
set -e
cd "$(dirname "$0")/.."

PORT=7357
URL="http://127.0.0.1:${PORT}"

echo "Port ${PORT} temizleniyor..."
lsof -ti tcp:"${PORT}" | xargs kill 2>/dev/null || true
sleep 1

echo "Admin panel başlatılıyor (ilk açılış 30-60 sn sürebilir)..."

# Sunucu hazır olunca tarayıcıyı aç.
(
  for _ in $(seq 1 90); do
    if curl -sf "${URL}/" >/dev/null 2>&1; then
      echo "Sunucu hazır → ${URL}"
      open "${URL}"
      exit 0
    fi
    sleep 2
  done
  echo "Uyarı: Sunucu 3 dakika içinde yanıt vermedi. Manuel açın: ${URL}"
) &

exec flutter run -d web-server -t lib/admin_main.dart --web-port="${PORT}" --web-hostname=127.0.0.1
