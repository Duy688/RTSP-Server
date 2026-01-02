#!/bin/bash
set -e

CAMS=("cam0" "cam1" "cam2" "cam3" "cam4" "cam5" "cam6" "cam7" "cam8" "cam9" "cam10" "cam11" "cam12" "cam13" "cam14" "cam15" "cam16" "cam17" "cam18" "cam19" "cam20" "cam21" "cam22" "cam23" "cam24" "cam25" "cam26" "cam27" "cam28" "cam29" "cam30" "cam31" "cam32" "cam33" "cam34" "cam35" "cam36" "cam37" "cam38" "cam39" "cam40" "cam41" "cam42" "cam43" "cam44" "cam45" "cam46" "cam47" "cam48" "cam49" "cam50" "cam51" "cam52" "cam53" "cam54" "cam55" "cam56" "cam57" "cam58" "cam59" "cam60" "cam61" "cam62" "cam63" "cam64" "cam65" "cam66" "cam67" "cam68" "cam69" "cam70" "cam71" "cam72" "cam73" "cam74" "cam75" "cam76" "cam77" "cam78" "cam79")

for CAM in "${CAMS[@]}"; do
  CLEAN="/videos_clean/${CAM}_clean.mp4"

  if [ -f "$CLEAN" ]; then
    echo ">>> Start stream $CAM from $CLEAN"
    ffmpeg -re -stream_loop -1 \
      -i "$CLEAN" \
      -c:v copy -an \
      -f rtsp -rtsp_transport tcp \
      "rtsp://mediamtx:8554/${CAM}" &
  else
    echo "!!! Bỏ qua $CAM, không thấy file $CLEAN"
  fi
done

echo ">>> Tất cả stream đã start, chờ các process ffmpeg..."
wait
