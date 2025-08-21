#!/bin/bash

# Processes videos from raw_videos/ to public/videos/ in multiple formats for web streaming.
# I have used LLMs to help me write that but heavily modified after.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${RED}Error: ffmpeg is not installed${NC}"
    echo "Install with: brew install ffmpeg (macOS) or apt install ffmpeg (Ubuntu)"
    exit 1
fi

# Create output directory if it doesn't exist.
mkdir -p public/videos

# Delete all content already there.
rm -f public/videos/*.mp4 public/videos/*.webm public/videos/*.jpg

echo -e "${GREEN}🎬 Starting video processing...${NC}"

# Process each video in raw_videos
for input_video in raw_videos/*.mp4; do
    if [ ! -f "$input_video" ]; then
        echo -e "${YELLOW}No .mp4 files found in raw_videos/${NC}"
        continue
    fi
    
    # Get filename without extension
    filename=$(basename "$input_video" .mp4)
    
    echo -e "${GREEN}📹 Processing: $filename${NC}"
    
    # 1. H.264 (MP4)
    echo -e "${YELLOW}  → Creating H.264 version...${NC}"
    ffmpeg -y -i "$input_video" \
        -c:v libx264 -profile:v high -level 4.1 -crf 23 -preset fast -pix_fmt yuv420p -movflags +faststart \
        -an \
        -r 30 -g 300 \
        "public/videos/${filename}.h264.mp4" \
        2>/dev/null

    # 2. WebM with AV1
    echo -e "${YELLOW}  → Creating WebM AV1 version...${NC}"
    ffmpeg -y -i "$input_video" \
        -c:v libsvtav1 -crf 30 -preset 6 -pix_fmt yuv420p \
        -row-mt 1 \
        -an \
        -r 30 -g 300 \
        "public/videos/${filename}.av1.webm" \
        2>/dev/null

    # 3. Generate poster image
    echo -e "${YELLOW}  → Generating poster image...${NC}"
    ffmpeg -y -ss 1 -i "$input_video" \
        -vframes 1 -q:v 2 \
        "public/videos/${filename}.poster.jpg" \
        2>/dev/null
    
    echo -e "${GREEN}✅ Completed: $filename${NC}"
    
    # Show file sizes
    echo -e "${YELLOW}📊 File sizes:${NC}"
    original_size=$(du -h "$input_video" | cut -f1)
    echo "  Original: $original_size"
    
    if [ -f "public/videos/${filename}.h264.mp4" ]; then
        h264_size=$(du -h "public/videos/${filename}.h264.mp4" | cut -f1)
        echo "  H.264:    $h264_size"
    fi
    
    if [ -f "public/videos/${filename}.av1.webm" ]; then
        webm_size=$(du -h "public/videos/${filename}.av1.webm" | cut -f1)
        echo "  AV1:     $webm_size"
    fi
    
    if [ -f "public/videos/${filename}.poster.jpg" ]; then
        poster_size=$(du -h "public/videos/${filename}.poster.jpg" | cut -f1)
        echo "  Poster:  $poster_size"
    fi
    
    echo ""
done

echo -e "${GREEN}🎉 Video processing complete!${NC}"