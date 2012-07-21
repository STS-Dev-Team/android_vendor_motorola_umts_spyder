#!/system/bin/sh
export PATH=/system/bin:$PATH

#This script is included in /system/bin folder only for multiconfig builds.
#This script has been added to ensure that, on a reflash with a new system
#image, the device gets correctly configured to the desired configuration
#that existed previously before re-flash.
#The script will run very early on boot-up and check if the device has been
#re-flashed, and if so, re-configures the system image to match the previous
#configuration (if needed).

CONFIG_FILE=/system/multiconfig/config-id
MASTER_CONFIG_ID_FILE=/system/multiconfig/master-config-id
DATA_CONFIG_FILE=/data/system/config-id
LOG_FILE=/data/system/mclog.txt

if [ -f $LOG_FILE ]; then
    rm $LOG_FILE
fi

echo "Running muticonfig consistency check script" >> $LOG_FILE

if [ ! -f $MASTER_CONFIG_ID_FILE ]; then
    echo "Non multiconfig device" >> $LOG_FILE
    return
fi

if [ -f $DATA_CONFIG_FILE ]; then
    data_config_id=`cat $DATA_CONFIG_FILE`
    echo "data_config_id : $data_config_id" >> $LOG_FILE
    config_id=`getconfig`
    echo "config_id : $config_id"
    if [ $config_id -eq $data_config_id ]; then
        echo "SAME CONFIG ID RETURN" >> $LOG_FILE
        return
    fi

    config_data_path=/system/multiconfig/ap/$data_config_id
    if [ -d $config_data_path ]; then
        echo "Call for setconfig without erase data" >> $LOG_FILE
        status=`setconfig -no_erase_data $data_config_id`
        if [ $status -eq "0" ]; then
            reboot recovery
        fi
    else
        echo "Non supported Multiconfig id" >> $LOG_FILE
            rm $DATA_CONFIG_FILE
        fi
else
    if [ -f $CONFIG_FILE ]; then
        cp $CONFIG_FILE $DATA_CONFIG_FILE
    else
        cp $MASTER_CONFIG_ID_FILE $DATA_CONFIG_FILE
    fi
fi
