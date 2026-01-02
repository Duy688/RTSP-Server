#!/usr/bin/env bash
set -euo pipefail

# Raw input videos (cam0.mp4, cam1.mp4, ...). You can mount this into container.
RAW_DIR="${RAW_DIR:-/videos_raw}"
OUT_DIR="${OUT_DIR:-/videos_clean}"

# Target output format (optimize for Jetson HW decode stability):
# - CFR 25fps
# - No B-frames (avoid reordering / timestamp surprises)
# - repeat-headers=1 (SPS/PPS on every keyframe)
# - aud=1 (Access Unit Delimiters)
FPS="${FPS:-25}"
WIDTH="${WIDTH:-1920}"
HEIGHT="${HEIGHT:-1080}"

echo "[INFO] RAW_DIR=${RAW_DIR}"
echo "[INFO] OUT_DIR=${OUT_DIR}"
mkdir -p "${OUT_DIR}"

shopt -s nullglob
inputs=("${RAW_DIR}"/*.mp4)
if [ ${#inputs[@]} -eq 0 ]; then
  echo "[ERROR] No .mp4 files found in ${RAW_DIR}"
  exit 1
fi

for in_file in "${inputs[@]}"; do
  bn="$(basename "$in_file")"
  name="${bn%.mp4}"
  out_file="${OUT_DIR}/${name}_clean.mp4"

  echo "[INFO] Preprocess ${in_file} -> ${out_file}"

  ffmpeg -hide_banner -y \
    -i "$in_file" \
    -an \
    -vf "scale=${WIDTH}:${HEIGHT}:flags=bicubic,fps=${FPS},format=yuv420p" \
    -c:v libx264 \
    -preset veryfast -tune zerolatency \
    -profile:v high -level 4.1 \
    -g "${FPS}" -keyint_min "${FPS}" -sc_threshold 0 \
    -bf 0 \
    -x264-params "repeat-headers=1:aud=1" \
    -movflags +faststart \
    "$out_file"
done

echo "[OK] Done. Output in ${OUT_DIR}"
