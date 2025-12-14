#!/bin/bash

LOG_DIR="logs"
LOG="${LOG_DIR}/image_resize.log"

# You can set what the largest WIDTH or HEIGHT should be set at
# an image that is 1200x900 will get resized to 820x520
# an image that is 900x1200 will get resized to 520x820
# an image that is 1200x1200 will get resized to 820x820
MAX_WIDTH=1000;
MAX_HEIGHT=1000;

# 50 KB, Images over 50KB will be resized
MAX_SIZE=50000;

# WEBP Quality parameter allows you to set your image's quality when converting to WEBP.
# I reccomend 75 so that your images are not terribly pixelated with 820px being the largest dimension for your image.
WEBP_QUALITY=90

# Log Directory
if [ ! -d "$LOG_DIR" ]; then 
  mkdir -p "$LOG_DIR"
fi

# Create a backup
BACKUP_DIR="../BACKUP_DIR"
if [ -d "$BACKUP_DIR" ]; then 
  echo "Back up directory already exists";
  exit;
fi

mkdir -p "$BACKUP_DIR"
cp -r * "$BACKUP_DIR"

# Let's Log the total size of all the images
totalDirectorySize="$(du -sh)"
echo "Directory Size Before Compression: $totalDirectorySize" >> "${LOG}";

for file in *; do
  # Check if it's an image (including webp)
  if [[ "$file" =~ \.(jpg|jpeg|png|gif|bmp|tiff|webp)$ ]]; then

    # Get the dimensions of the image (width and height)
    dimensions=$(identify -format "%w %h" "$file" 2>/dev/null)
    file_name="${file%.*}"

    # Check if dimensions are retrieved successfully
    if [[ -n "$dimensions" ]]; then
      width=$(echo $dimensions | cut -d' ' -f1)
      height=$(echo $dimensions | cut -d' ' -f2)

      # Check if the image dimensions are smaller than max_width || max_height in either width or height
      if [ "$width" -gt $MAX_WIDTH ] || [ "$height" -gt $MAX_HEIGHT ]; then
        # Resize the image to 50% of its original size using magick
        echo "Resizing $file..."

        if [ "$width" -gt "$height" ]; then
          magick "$file" -resize "${MAX_WIDTH}"x "$file"
        fi;

        if [ "$height" -gt "$width" ]; then
          magick "$file" -resize x"${MAX_HEIGHT}" "$file"
        fi;

        if [ "$width" -eq "$height" ]; then
          magick "$file" -resize "${MAX_WIDTH}"x"${MAX_HEIGHT}" "$file"
        fi;

        echo "$file was resized successfully."

      else
        echo "$file is not resized because its dimensions are below ${MAX_WIDTH}w X ${MAX_HEIGHT}h"
      fi
    else
      echo "Error: Could not retrieve dimensions for $file. Skipping..."
    fi

    # Convert to webp if it isn't already in WEBP format.
    if ! [[ "$file" =~ \.(webp)$ ]]; then
      magick "${file}" -quality 100 -define webp:lossless=false "${file_name}.webp"

      # let's trash the original image
      rm -rf "$file"
    fi

    webpFile="${file_name}.webp"

    # Get the size of the new image in bytes
    file_size=$(stat -f %z "$webpFile")

    # Only proceed if the file is over MAX_SIZE.
    if [ "$file_size" -gt $MAX_SIZE ]; then
      # compress the image
      magick "${webpFile}" -quality "${WEBP_QUALITY}" -define webp:lossless=false "${file_name}.webp"
    else
      echo "$file is smaller than ${MAX_SIZE} bytes and will not be compressed."
    fi
  else
    echo "$file is not an image file."
  fi
done

# Let's log the total size of all the images after we compress & resize them
totalDirectorySize="$(du -sh)"
echo "Directory Size After Compression: $totalDirectorySize" >> "${LOG}";