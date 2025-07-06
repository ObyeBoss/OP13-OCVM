#!/system/bin/sh
#setenforce 0

# chown -R root:root $MODPATH/odm/etc
# find $MODPATH/odm/etc -type d -exec chmod 755 {} +
# find $MODPATH/odm/etc -type f -exec chmod 644 {} +
# chcon -R u:object_r:vendor_configs_file:s0 $MODPATH/odm/etc

# chown -R root:root $MODPATH/odm/lib64
# find $MODPATH/odm/lib64 -type d -exec chmod 755 {} +
# find $MODPATH/odm/lib64 -type f -exec chmod 644 {} +
# chcon -R u:object_r:same_process_hal_file:s0 $MODPATH/odm/lib64

# chown -R root:root $MODPATH/odm/lib64/camera
# find $MODPATH/odm/lib64/camera -type d -exec chmod 755 {} +
# find $MODPATH/odm/lib64/camera -type f -exec chmod 644 {} +
# chcon -R u:object_r:vendor_file:s0 $MODPATH/odm/lib64/camera

# chown -R root:root $MODPATH/vendor/lib64
# find $MODPATH/vendor/lib64 -type d -exec chmod 755 {} +
# find $MODPATH/vendor/lib64 -type f -exec chmod 644 {} +
# chcon -R u:object_r:vendor_file:s0 $MODPATH/vendor/lib64

# mf() {
#   local src="$1"
#   local dest="$2"
#   [ ! -d "$src" ] && return
#   find "$src" -type f | while read -r file; do
#     rel_path="${file#$src}"; target_file="$dest$rel_path"; mount -o ro,bind "$file" "$target_file"
#   done
# }

# for partition in /my_product; do
#   partition_name="${partition#/}"; src="$MODPATH/$partition_name"; dest="/$partition_name"; mf "$src" "$dest"
# done

#OVERLAYFS (a10+ only)
mfo() {
  local src="$1"         # e.g., $MODPATH/my_product
  local dest="$2"      # e.g., /my_product
  local work_base="/dev/overlay_work"  # or use $MODPATH/tmp/...

  [ ! -d "$src" ] && return
  mkdir -p "$dest" "$work_base"

  local upper="$work_base/upper${dest}"
  local work="$work_base/work${dest}"

  mkdir -p "$upper" "$work"

  # Copy overlay files into upperdir to apply them
  cp -a "$src/." "$upper/"

  # Perform OverlayFS mount
  mount -t overlay overlay -o lowerdir="$dest",upperdir="$upper",workdir="$work" "$dest"
}

for partition in /my_product; do
  partition_name="${partition#/}"
  src="$MODPATH/$partition_name"
  dest="/$partition_name"
  mfo "$src" "$dest"
done
