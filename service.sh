#!/system/bin/sh

resetprop -p --file "$MODPATH"/persist.prop

(
  while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
  done
  stop cameraserver; start cameraserver
)&

chown -R root:root $MODPATH/odm/etc
find $MODPATH/odm/etc -type d -exec chmod 755 {} +
find $MODPATH/odm/etc -type f -exec chmod 644 {} +
chcon -R u:object_r:vendor_configs_file:s0 $MODPATH/odm/etc

chown -R root:root $MODPATH/odm/lib64
find $MODPATH/odm/lib64 -type d -exec chmod 755 {} +
find $MODPATH/odm/lib64 -type f -exec chmod 644 {} +
chcon -R u:object_r:same_process_hal_file:s0 $MODPATH/odm/lib64

chown -R root:root $MODPATH/odm/lib64/camera
find $MODPATH/odm/lib64/camera -type d -exec chmod 755 {} +
find $MODPATH/odm/lib64/camera -type f -exec chmod 644 {} +
chcon -R u:object_r:vendor_file:s0 $MODPATH/odm/lib64/camera

chown -R root:root $MODPATH/vendor/lib64
find $MODPATH/vendor/lib64 -type d -exec chmod 755 {} +
find $MODPATH/vendor/lib64 -type f -exec chmod 644 {} +
chcon -R u:object_r:vendor_file:s0 $MODPATH/vendor/lib64