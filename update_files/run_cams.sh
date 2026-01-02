#!/usr/bin/env bash
set -euo pipefail

# Directory that contains preprocessed videos (e.g. cam0_clean.mp4, cam1_clean.mp4, ...)
VIDEO_DIR="${VIDEO_DIR:-/videos_clean}"

# Base RTSP publish URL of MediaMTX.
# In docker-compose, this is typically: rtsp://mediamtx:8554
RTSP_BASE="${RTSP_BASE:-rtsp://127.0.0.1:8554}"

# How many seconds to wait between launching streams (avoid burst load)
START_GAP_SEC="${START_GAP_SEC:-0.2}"

echo "[INFO] VIDEO_DIR=${VIDEO_DIR}"
echo "[INFO] RTSP_BASE=${RTSP_BASE}"

shopt -s nullglob
files=("${VIDEO_DIR}"/*_clean.mp4 "${VIDEO_DIR}"/*.mp4)

if [ ${#files[@]} -eq 0 ]; then
  echo "[ERROR] No .mp4 files found in ${VIDEO_DIR}"
  exit 1
fi

mkdir -p /tmp/rtsp_pids

i=0
for f in "${files[@]}"; do
  bn="$(basename "$f")"

  # Prefer stream name like "cam0" from "cam0_clean.mp4"
  name="${bn%_clean.mp4}"
  name="${name%.mp4}"

  # Skip duplicates if both *_clean.mp4 and *.mp4 are present
  if [ -f "${VIDEO_DIR}/${name}_clean.mp4" ] && [ "$bn" = "${name}.mp4" ]; then
    continue
  fi

  url="${RTSP_BASE}/${name}"
  log="/tmp/${name}.ffmpeg.log"
  pidfile="/tmp/rtsp_pids/${name}.pid"

  echo "[INFO] (${i}) Publishing ${f}  ->  ${url}"

  # Why these flags:
  # -stream_loop -1     : loop forever (like MediaMTX docs example)
  # -re                 : pace in real time
  # -fflags +genpts     : generate missing PTS if needed (helps some broken files)
  # -c:v copy           : no re-encode (lightweight)
  # -bsf:v h264_mp4toannexb : convert H264 from MP4 (AVCC) to Annex-B byte-stream
  # -rtsp_transport tcp : stable transport
  nohup ffmpeg -hide_banner -loglevel warning -nostdin \
    -re -stream_loop -1 -fflags +genpts \
    -i "$f" \
    -an -c:v copy -bsf:v h264_mp4toannexb \
    -f rtsp -rtsp_transport tcp \
    "$url" \
    >"$log" 2>&1 &

  echo $! > "$pidfile"
  i=$((i+1))
  sleep "$START_GAP_SEC"
done

echo "[OK] Started ${i} RTSP publishers."
echo "     Logs: /tmp/<cam>.ffmpeg.log"
echo "     PIDs: /tmp/rtsp_pids/<cam>.pid"
