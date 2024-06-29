#!/bin/bash

# Get input video resolution
resolution=$(ffmpeg -i input.mp4 2>&1 | grep -oP 'Stream #0:0.*? (\d{2,5})x(\d{2,5})' | head -1 | grep -oP '\d{2,5}x\d{2,5}')
width=$(echo $resolution | cut -d'x' -f1)
height=$(echo $resolution | cut -d'x' -f2)

# Set target resolutions and bitrates
target_resolutions=("1920:1080:5000" "1280:720:3000" "854:480:1500" "640:360:800")

# Generate the filter_complex string dynamically
filter_complex=""
map=""

index=0

for res in "${target_resolutions[@]}"; do
    target_width=$(echo $res | cut -d':' -f1)
    target_height=$(echo $res | cut -d':' -f2)
    target_bitrate=$(echo $res | cut -d':' -f3)
    
    if (( $width >= $target_width )); then
        if [ -n "$filter_complex" ]; then
            filter_complex+=","
        fi
        filter_complex+="[0:v]scale=w=$target_width:h=trunc(ow/a/2)*2[v$index]"
        map+="-map [v$index] -map 0:a -c:v:$index libx264 -b:v:$index ${target_bitrate}k -maxrate:v:$index $(($target_bitrate * 107))k -bufsize:v:$index $(($target_bitrate * 150))k -preset fast -g 48 -sc_threshold 0 -c:a aac -b:a 128k -f hls -hls_time 4 -hls_playlist_type vod -hls_segment_filename \"${target_height}p_%03d.ts\" ${target_height}p.m3u8 "
        index=$((index + 1))
    fi
done

# Check if filter_complex is empty
if [ -z "$filter_complex" ]; then
    echo "No valid resolutions to scale down to."
    exit 1
fi

# Execute the ffmpeg command
eval "ffmpeg -i video_3.mp4 -filter_complex \"$filter_complex\" $map -master_pl_name master.m3u8"
