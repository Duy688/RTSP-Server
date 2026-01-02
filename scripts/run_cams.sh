#!/usr/bin/env bash
set -euo pipefail

VIDEO_DIR="${VIDEO_DIR:-/videos_clean}"
RTSP_BASE="${RTSP_BASE:-rtsp://mediamtx:8554}"
START_GAP_SEC="${START_GAP_SEC:-0.2}"

shopt -s nullglob
mapfile -t files < <(find "$VIDEO_DIR" -maxdepth 1 -type f \
  \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.mov' -o -iname '*.avi' -o -iname '*.ts' \) | sort)

if [ ${#files[@]} -eq 0 ]; then
  echo "[ERROR] No videos found in $VIDEO_DIR"
  exit 1
fi

pids=()

cleanup() {
  echo "[INFO] Stopping publishers..."
  for pid in "${pids[@]:-}"; do
    kill "$pid" 2>/dev/null || true
  done
  wait 2>/dev/null || true
}
trap cleanup EXIT INT TERM

i=0
for f in "${files[@]}"; do
  name="$(basename "$f")"
  base="${name%.*}"

  # Nếu file đã tên cam0/cam1... thì giữ nguyên; không thì tự gán cam<i>
  if [[ "$base" =~ ^cam[0-9]+$ ]]; then
    path="$base"
  else
    path="cam${i}"
  fi

  url="${RTSP_BASE}/${path}"
  echo "[INFO] Publish: $f -> $url"

  # NOTE: -c:v copy để nhẹ CPU, vì bạn đã preprocess thành H264 “chuẩn stream”
  # +genpts giúp ổn định PTS khi input hơi “lạ”
  ffmpeg -hide_banner -loglevel warning \
    -stream_loop -1 -re -fflags +genpts \
    -i "$f" \
    -an -sn -dn \
    -c:v copy \
    -rtsp_transport tcp -f rtsp \
    "$url" &

  pids+=("$!")
  i=$((i+1))
  sleep "$START_GAP_SEC"
done

echo "[INFO] Started ${#pids[@]} publishers."
wait -n
echo "[ERROR] A publisher exited unexpectedly."
exit 1
