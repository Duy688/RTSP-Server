# RTSP-Server

A small Docker-based setup that publishes multiple looping RTSP streams from local video files. It uses:

- **MediaMTX** as the RTSP server.
- **FFmpeg** for preprocessing video files and publishing the streams.

The workflow is:

1. (Optional, recommended) Preprocess raw videos into stream-friendly H.264 files.
2. Start MediaMTX + the streamer container.
3. Open the RTSP URLs (e.g. in VLC).

---

## Repository layout

- `docker-compose.yml` — Orchestrates the RTSP server, preprocessing, and streamer containers.
- `mediamtx.yml` — MediaMTX configuration (TCP RTSP, publisher mode).
- `scripts/preprocess_all.sh` — Cleans/transcodes raw videos to H.264 baseline with dense keyframes for quick joins.
- `scripts/run_cams.sh` — Publishes each cleaned file to a separate RTSP path.
- `videos_raw/` — (Create this) Raw input files.
- `videos_clean/` — (Created by preprocess) Output files used for streaming.

---

## Prerequisites

- Docker + Docker Compose
- VLC or another RTSP-capable client

---

## Quick start

### 1) Put source videos in `videos_raw/`

Supported extensions: `.mp4`, `.mkv`, `.mov`, `.avi`, `.ts`.

```
mkdir -p videos_raw
# copy your raw videos here
```

### 2) Preprocess videos (recommended)

This generates stream-friendly H.264 files inside `videos_clean/`.

```
docker compose run --rm preprocess
```

You should see a final line similar to:

```
[INFO] Done.
```

### 3) Start the RTSP server and stream publisher

```
docker compose up -d mediamtx streamer
```

### 4) Play the streams

Open VLC (or similar) and use URLs like:

```
rtsp://127.0.0.1:8554/cam0
rtsp://127.0.0.1:8554/cam1
rtsp://127.0.0.1:8554/cam2
```

> **Note:** If hosting on a public server, replace `127.0.0.1` with your server’s public IP.

---

## How stream paths are chosen

The streamer reads all files in `videos_clean/` in sorted order:

- If a filename is already `cam<number>` (e.g. `cam1.mp4`), that name is used.
- Otherwise, it assigns sequential names: `cam0`, `cam1`, `cam2`, etc.

---

## Configuration

### MediaMTX

The MediaMTX config is in `mediamtx.yml`:

- RTSP runs over TCP for stability.
- Any publish path is accepted (`paths: all` with `publisher`).

### Preprocess container (`scripts/preprocess_all.sh`)

You can override these environment variables when running `preprocess`:

| Variable | Default | Description |
| --- | --- | --- |
| `FPS` | `25` | Output FPS |
| `GOP_SEC` | `0.5` | Seconds between keyframes |
| `CRF` | `23` | H.264 quality (higher = lower bitrate) |
| `PRESET` | `veryfast` | x264 preset |

Example:

```
FPS=30 GOP_SEC=1 CRF=24 PRESET=fast \
  docker compose run --rm preprocess
```

### Streamer container (`scripts/run_cams.sh`)

You can override these environment variables when starting the streamer:

| Variable | Default | Description |
| --- | --- | --- |
| `VIDEO_DIR` | `/videos_clean` | Directory with cleaned videos |
| `RTSP_BASE` | `rtsp://mediamtx:8554` | RTSP base URL in docker network |
| `START_GAP_SEC` | `0.2` | Delay between starting each FFmpeg publisher |

Example:

```
VIDEO_DIR=/videos_clean START_GAP_SEC=0.1 \
  docker compose up -d streamer
```

---

## Troubleshooting

- **No videos found**: Ensure `videos_raw/` or `videos_clean/` contains supported files.
- **Cannot connect to stream**: Confirm containers are running (`docker compose ps`).
- **Black screen or choppy playback**: Re-run `preprocess` to normalize codecs and keyframes.

---

## Stop and clean up

```
docker compose down
```

---

## License

No license file is provided. Add one if you plan to distribute the project publicly.
