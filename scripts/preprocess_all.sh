#!/usr/bin/env bash
set -euo pipefail

RAW_DIR="${1:-./videos_raw}"
OUT_DIR="${2:-./videos_clean}"

FPS="${FPS:-25}"                 # fps mục tiêu (int)
GOP_SEC="${GOP_SEC:-0.5}"        # keyframe mỗi bao nhiêu giây (float). 0.5s là khuyến nghị cho join nhanh
CRF="${CRF:-23}"                 # chất lượng; tăng lên (24-28) để giảm bitrate nếu keyframe dày làm bitrate tăng
PRESET="${PRESET:-veryfast}"     # veryfast/faster/fast...

mkdir -p "$OUT_DIR"

# Tính GOP theo frames, hỗ trợ GOP_SEC là số thực
GOP_FRAMES="$(awk -v fps="$FPS" -v sec="$GOP_SEC" 'BEGIN{g=fps*sec; if(g<1) g=1; printf "%d", (g+0.5)}')"
if [ "$GOP_FRAMES" -lt 1 ]; then GOP_FRAMES=1; fi

shopt -s nullglob
inputs=("$RAW_DIR"/*.mp4 "$RAW_DIR"/*.mkv "$RAW_DIR"/*.mov "$RAW_DIR"/*.avi "$RAW_DIR"/*.ts)

if [ ${#inputs[@]} -eq 0 ]; then
  echo "[ERROR] No input videos found in: $RAW_DIR"
  exit 1
fi

echo "[INFO] RAW_DIR=$RAW_DIR"
echo "[INFO] OUT_DIR=$OUT_DIR"
echo "[INFO] FPS=$FPS"
echo "[INFO] GOP_SEC=$GOP_SEC  => GOP_FRAMES=$GOP_FRAMES"
echo "[INFO] CRF=$CRF PRESET=$PRESET"
echo "[INFO] Forcing keyframes by time with -force_key_frames expr:gte(t,n_forced*GOP_SEC)"

for in_file in "${inputs[@]}"; do
  base="$(basename "$in_file")"
  name="${base%.*}"
  out_file="$OUT_DIR/${name}.mp4"

  echo "[INFO] Processing: $in_file -> $out_file"

  ffmpeg -y -hide_banner -loglevel warning \
    -fflags +genpts \
    -i "$in_file" \
    -an -sn -dn \
    -vf "fps=${FPS},format=yuv420p" \
    -c:v libx264 -preset "$PRESET" -tune zerolatency \
    -profile:v baseline -level 4.1 \
    -crf "$CRF" \
    -g "$GOP_FRAMES" -keyint_min "$GOP_FRAMES" -sc_threshold 0 \
    -bf 0 \
    -x264-params "repeat-headers=1:open-gop=0" \
    -force_key_frames "expr:gte(t,n_forced*${GOP_SEC})" \
    -movflags +faststart \
    "$out_file"
done

echo "[INFO] Done."
