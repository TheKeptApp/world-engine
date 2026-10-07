#!/bin/bash
# Copy design-pack images (PNG, JPG, ZIP, SVG) from R's local checkout into iCloud Drive, keeping folders.
# Copy only: never deletes on either side. Look-loop frames are not backed up (regenerable).
#   Tools/lookloop/backup_design_images.sh
set -euo pipefail
S="$HOME/Desktop/world-engine/docs/proposals/"
D="$HOME/Library/Mobile Documents/com~apple~CloudDocs/WorldEngine-Design-Backup/proposals/"
mkdir -p "$D"
rsync -a --include='*/' --include='*.png' --include='*.PNG' --include='*.jpg' --include='*.jpeg' --include='*.zip' --include='*.svg' \
  --exclude='*' --prune-empty-dirs "$S" "$D"
echo "backup: $(find "$D" -type f | wc -l | tr -d ' ') files, $(du -sh "$D" | cut -f1) in iCloud WorldEngine-Design-Backup/proposals"
