##########################################################################################
#
# MMT Extended Utility Functions
#
##########################################################################################
require_new_ksu() {
  ui_print "**********************************"
  ui_print " Please install KernelSU v0.6.6+! "
  ui_print "**********************************"
  exit 1
}
umount_mirrors() {
  [ -d "$ORIGDIR" ] || return 0
  for i in "$ORIGDIR"/*; do
    umount -l "$i" 2>/dev/null
  done
  rm -rf "$ORIGDIR" 2>/dev/null
  $KSU && mount -o ro,remount "$MAGISKTMP"
}
cleanup() {
  if $KSU || [ "$MAGISK_VER_CODE" -ge 27000 ]; then umount_mirrors; fi
  rm -rf "$MODPATH"/common "$MODPATH"/install.zip 2>/dev/null
}
abort() {
  ui_print "$1"
  rm -rf "$MODPATH" 2>/dev/null
  cleanup
  rm -rf "$TMPDIR" 2>/dev/null
  exit 1
}
device_check() {
  local opt type
  opt=$(getopt -o dm -- "$@")
  type=device
  eval set -- "$opt"
  while true; do
    case "$1" in
      -d) type=device; shift;;
      -m) type=manufacturer; shift;;
      --) shift; break;;
      *) abort "Invalid device_check argument $1! Aborting!";;
    esac
  done
  local prop
  prop=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  for i in /system /vendor /odm /product; do
    if [ -f "$i/build.prop" ]; then
      for j in "ro.product.$type" "ro.build.$type" "ro.product.vendor.$type" "ro.vendor.product.$type"; do
        [ "$(sed -n "s/^$j=//p" "$i/build.prop" 2>/dev/null | head -n 1 | tr '[:upper:]' '[:lower:]')" == "$prop" ] && return 0
      done
      [ "$type" == "device" ] && [ "$(sed -n "s/^ro.build.product=//p" "$i/build.prop" 2>/dev/null | head -n 1 | tr '[:upper:]' '[:lower:]')" == "$prop" ] && return 0
    fi
  done
  return 1
}
cp_ch() {
  local opt BAK UBAK FOL
  opt=$(getopt -o nr -- "$@")
  BAK=true
  UBAK=true
  FOL=false
  eval set -- "$opt"
  while true; do
    case "$1" in
      -n) UBAK=false; shift;;
      -r) FOL=true; shift;;
      --) shift; break;;
      *) abort "Invalid cp_ch argument $1! Aborting!";;
    esac
  done
  local SRC DEST OFILES
  SRC="$1"
  DEST="$2"
  OFILES="$1"
  $FOL && OFILES=$(find "$SRC" -type f 2>/dev/null)
  [ -z "$3" ] && PERM=0644 || PERM=$3
  case "$DEST" in
    $TMPDIR/*|$MODULEROOT/*|$NVBASE/modules/$MODID/*) BAK=false;;
  esac
  for OFILE in ${OFILES}; do
    local FILE
    if $FOL; then
      if [ "$(basename "$SRC")" == "$(basename "$DEST")" ]; then
        FILE="${OFILE//$SRC/$DEST}"
      else
        FILE="${OFILE//|$SRC|$DEST/$(basename "$SRC")|/$DEST/$(basename "$SRC")}"
      fi
    else
      if [ -d "$DEST" ]; then
        FILE="$DEST/$(basename "$SRC")"
      else
        FILE="$DEST"
      fi
    fi
    if $BAK && $UBAK; then
      if ! grep -q "$FILE$" "$INFO"; then
        echo "$FILE" >> "$INFO"
      fi
      [ -f "$FILE" ] && [ ! -f "$FILE~" ] && { mv -f "$FILE" "$FILE"~; echo "$FILE~" >> "$INFO"; }
    elif $BAK; then
      if ! grep -q "$FILE$" "$INFO"; then
        echo "$FILE" >> "$INFO"
      fi
    fi
    [[ ! "$OFILE" =~ \.sh$ && ! "$OFILE" =~ \.prop$ ]] && install -D -m "$PERM" "$OFILE" "$FILE".stock
    install -D -m "$PERM" "$OFILE" "$FILE"
  done
}
install_script() {
  local INPATH
  case "$1" in
    -b) shift
        if $KSU; then
          INPATH=$NVBASE/boot-completed.d
        else
          INPATH=$SERVICED
          sed -i -e '1i (\nwhile [ "$(getprop sys.boot_completed)" != "1" ]; do\n  sleep 1\ndone\nsleep 3\n' -e '$a)&' "$1"
        fi ;;
    -l) shift; INPATH=$SERVICED ;;
    -p) shift; INPATH=$POSTFSDATAD ;;
    *) INPATH=$SERVICED ;;
  esac
  grep -q "#!/system/bin/sh" "$1" || sed -i "1i #!/system/bin/sh" "$1"
  local i 
  for i in "MODPATH" "LIBDIR" "MODID" "INFO" "MODDIR"; do
    case $i in
      "MODPATH") sed -i "1a $i=$NVBASE/modules/$MODID" "$1" ;;
      "MODDIR") sed -i "1a $i=\${0%/*}" "$1" ;;
      *) sed -i "1a $i=$(eval echo \$$i)" "$1" ;;
    esac
  done
  case $1 in
    "$MODPATH/post-fs-data.sh"|"$MODPATH/service.sh"|"$MODPATH/uninstall.sh") sed -i "s|^MODPATH=.*|MODPATH=\$MODDIR|" "$1";; 
    "$MODPATH/boot-completed.sh") $KSU && sed -i "s|^MODPATH=.*|MODPATH=\$MODDIR|" "$1" || { cp_ch -n "$1" "$INPATH"/"$MODID"-"$(basename "$1")" 0755; rm -f "$MODPATH"/boot-completed.sh; };;
    *) cp_ch -n "$1" "$INPATH"/"$(basename "$1")" 0755;;
  esac
}
prop_process() {
  sed -i -e "/^#/d" -e "/^ *$/d" "$1"
  [ -f "$MODPATH"/system.prop ] || mktouch "$MODPATH"/system.prop
  while read -r LINE; do
    echo "$LINE" >> "$MODPATH"/system.prop
  done < "$1"
}
mount_mirrors() {
  $KSU && mount -o rw,remount "$MAGISKTMP"
  mkdir -p "$ORIGDIR"/system
  if $SYSTEM_ROOT; then
    mkdir -p "$ORIGDIR"/system_root
    mount -o ro / "$ORIGDIR"/system_root
    mount -o bind "$ORIGDIR"/system_root/system "$ORIGDIR"/system
  else
    mount -o ro /system "$ORIGDIR"/system
  fi
  for i in /vendor $PARTITIONS; do
    [ ! -d "$i" ] || [ -d "$ORIGDIR""$i" ] && continue
    mkdir -p "$ORIGDIR""$i"
    mount -o ro "$i" "$ORIGDIR""$i"
  done
}
ui_print "**************************************"
ui_print "*   MMT Extended by Zackptg5 @ XDA   *"
ui_print "**************************************"
ui_print " "
[ -z "$MINAPI" ] || { [ "$API" -lt "$MINAPI" ] && abort "! Your system API of $API is less than the minimum api of $MINAPI! Aborting!"; }
[ -z "$MAXAPI" ] || { [ "$API" -gt "$MAXAPI" ] && abort "! Your system API of $API is greater than the maximum api of $MAXAPI! Aborting!"; }
[ -z "$KSU" ] && KSU=false
$KSU && { [ "$KSU_VER_CODE" -lt 11184 ] && require_new_ksu; }
[ -z "$APATCH" ] && APATCH=false
[ "$APATCH" == "true" ] && KSU=true
set -x
[ -z "$NVBASE" ] && NVBASE=/data/adb
[ -z "$ARCH32" ] && ARCH32="$(echo "$ABI32" | cut -c-3)"
[ "$API" -lt 26 ] && DYNLIB=false
[ -z "$DYNLIB" ] && DYNLIB=false
[ -z "$PARTOVER" ] && PARTOVER=false
[ -z "$SYSTEM_ROOT" ] && SYSTEM_ROOT=$SYSTEM_AS_ROOT # renamed in magisk v26.3
[ -z "$SERVICED" ] && SERVICED=$NVBASE/service.d # removed in magisk v26.2
[ -z "$POSTFSDATAD" ] && POSTFSDATAD=$NVBASE/post-fs-data.d # removed in magisk v26.2
INFO=$NVBASE/modules/.$MODID-files
if $KSU; then
  MAGISKTMP="/mnt"
  ORIGDIR="$MAGISKTMP/mirror"
  mount_mirrors
elif [ "$(magisk --path 2>/dev/null)" ]; then
  if [ "$MAGISK_VER_CODE" -ge 27000 ]; then # Atomic Mount
    if [ -z "$MAGISKTMP" ]; then
      [ -d /sbin ] && MAGISKTMP=/sbin || MAGISKTMP=/debug_ramdisk
    fi
    ORIGDIR="$MAGISKTMP/mirror"
    mount_mirrors
  else
    ORIGDIR="$(magisk --path 2>/dev/null)/.magisk/mirror"
  fi
elif [ "$(echo "$MAGISKTMP" | awk -F/ '{ print $NF}')" == ".magisk" ]; then
  ORIGDIR="$MAGISKTMP/mirror"
else
  ORIGDIR="$MAGISKTMP/.magisk/mirror"
fi
EXTRAPART=false
if $KSU || [ "$(echo "$MAGISK_VER" | awk -F- '{ print $NF}')" == "delta" ] || [ "$(echo "$MAGISK_VER" | awk -F- '{ print $NF}')" == "kitsune" ]; then
  EXTRAPART=true
elif ! $PARTOVER; then
  unset PARTITIONS
fi
if ! $BOOTMODE; then
  ui_print "- Only uninstall is supported in recovery"
  ui_print "  Uninstalling!"
  touch "$MODPATH"/remove
  if [ -s "$INFO" ]; then
    install_script "$MODPATH"/uninstall.sh
  else
    rm -f "$INFO" "$MODPATH"/uninstall.sh
  fi
  recovery_cleanup
  cleanup
  rm -rf "$NVBASE"/modules_update/"$MODID" "$TMPDIR" 2>/dev/null
  exit 0
fi
ui_print "- Extracting module files"
unzip -o "$ZIPFILE" -x 'META-INF/*' 'common/functions.sh' -d "$MODPATH" >&2
[ -f "$MODPATH/common/addon.tar.xz" ] && tar -xf "$MODPATH"/common/addon.tar.xz -C "$MODPATH"/common 2>/dev/null
if [ "$(ls -A "$MODPATH"/common/addon/*/install.sh 2>/dev/null)" ]; then
  ui_print " "; ui_print "- Running Addons -"
  for i in "$MODPATH"/common/addon/*/install.sh; do
    ui_print "  Running $(echo "$i" | sed -r "s|$MODPATH/common/addon/(.*)/install.sh|\1|")..."
    . "$i"
  done
fi
if [ -f "$INFO" ]; then
  while read -r LINE; do
    if [ "$(echo -n "$LINE" | tail -c 1)" == "~" ]; then
      continue
    elif [ -f "$LINE~" ]; then
      mv -f "$LINE"~ "$LINE"
    else
      rm -f "$LINE"
      while true; do
        LINE=$(dirname "$LINE")
        if [ "$(ls -A "$LINE" 2>/dev/null)" ]; then
          break 1
        else
          rm -rf "$LINE"
        fi
      done
    fi
  done < "$INFO"
  rm -f "$INFO"
fi
[ -f "$MODPATH/common/install.sh" ] && . "$MODPATH"/common/install.sh
find "$MODPATH" -type f \( -name "*.sh" -o -name "*.prop" -o -name "*.rule" \) | while read -r i; do
  if [ -f "$i" ]; then
    sed -i -e "/^#/d" -e "/^ *$/d" "$i"
    [ "$(tail -1 "$i")" ] && echo "" >> "$i"
  else
    continue
  fi
  case $i in
    "$MODPATH/boot-completed.sh") install_script -b "$i" ;;
    "$MODPATH/service.sh") install_script -l "$i" ;;
    "$MODPATH/post-fs-data.sh") install_script -p "$i" ;;
    "$MODPATH/uninstall.sh") if [ -s "$INFO" ] || [ "$(head -n1 "$MODPATH"/uninstall.sh)" != "# Don't modify anything after this" ]; then                          
                               cp -f "$MODPATH"/uninstall.sh "$MODPATH"/"$MODID"-uninstall.sh # Fallback script in case module manually deleted
                               sed -i "1i[ -d \"\$MODPATH\" ] && exit 0" "$MODPATH"/"$MODID"-uninstall.sh
                               echo "rm -f $0" >> "$MODPATH"/"$MODID"-uninstall.sh
                               install_script -l "$MODPATH"/"$MODID"-uninstall.sh
                               rm -f "$MODPATH"/"$MODID"-uninstall.sh
                               install_script "$MODPATH"/uninstall.sh
                             else
                               rm -f "$INFO" "$MODPATH"/uninstall.sh
                             fi ;;
  esac
done
$IS64BIT || find "$MODPATH"/system -type d -name "lib64" | while read -r i; do rm -rf "$i" 2>/dev/null; done  
[ -d "/system/priv-app" ] || mv -f "$MODPATH"/system/priv-app "$MODPATH"/system/app 2>/dev/null
[ -d "/system/xbin" ] || mv -f "$MODPATH"/system/xbin "$MODPATH"/system/bin 2>/dev/null
if $DYNLIB; then
  for FILE in $(find "$MODPATH"/system/lib* -type f 2>/dev/null | sed "s|$MODPATH/system/||"); do
    [ -s "$MODPATH"/system/"$FILE" ] || continue
    case $FILE in
      lib*/modules/*) continue ;;
    esac
    mkdir -p "$(dirname "$MODPATH"/system/vendor/"$FILE")"
    mv -f "$MODPATH"/system/"$FILE" "$MODPATH"/system/vendor/"$FILE"
    [ "$(ls -A "$(dirname "$MODPATH/system/$FILE")")" ] || rm -rf "$(dirname "$MODPATH/system/$FILE")"
  done
  toybox find "$MODPATH"/system/lib* -type d -empty -delete >/dev/null 2>&1
fi
ui_print " "
ui_print "- Setting Permissions"
set_perm_recursive "$MODPATH" 0 0 0755 0644
for i in /data /product /system_ext /system/vendor /vendor /system/vendor/app /vendor/app /system/vendor/etc /vendor/etc /system/odm/etc /odm/lib64 /odm/etc /system/vendor/odm/etc /vendor/odm/etc; do
  if [ -d "$MODPATH$i" ] && [ ! -L "$MODPATH$i" ]; then
    case $i in
      *"/data") set_perm_recursive "$MODPATH$i" 1000 1000 0755 0400 u:object_r:os_data_file:s0 ;;
      *"/odm"|*"/vendor") set_perm_recursive "$MODPATH$i" 0 0 0755 0644 u:object_r:vendor_file:s0 ;;
      *"/app") set_perm_recursive "$MODPATH$i" 0 0 0755 0644 u:object_r:vendor_app_file:s0 ;;
      *"/overlay") set_perm_recursive "$MODPATH$i" 0 0 0755 0644 u:object_r:vendor_overlay_file:s0 ;;
      *"/etc") set_perm_recursive "$MODPATH$i" 0 2000 0755 0644 u:object_r:vendor_configs_file:s0 ;;
      *"/lib64") set_perm_recursive "$MODPATH$i" 0 0 0755 0644 u:object_r:same_process_hal_file:s0 ;;
    esac
  fi
done
find "$MODPATH"/system/vendor "$MODPATH"/vendor -type f -name '*.apk' | while read -r i; do
  chcon u:object_r:vendor_app_file:s0 "$i"
done
set_permissions
cleanup
