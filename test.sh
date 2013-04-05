#!/bin/bash

if [[ `id -u` != 0 ]]
then
  echo "Must be run as root"
  exit 1
fi

TARGET_NAME=hid-appleir
BLACKLIST_NAMES="apple hid-generic"

APPLE_VID=05AC
PIDS="8240 1440 8241 8242 8243"

WORKING_DIR=$(pwd)
TARGET=${TARGET_NAME}.ko

# check if the modules are compiled
if [[ ! -e $WORKING_DIR/${TARGET} ]]
then
  echo "please run make before test."
  echo "Aborting"
  exit 1
fi

rmmod ${TARGET_NAME} 2> /dev/null
insmod $WORKING_DIR/${TARGET}

# wait 1 seconds for the devices to be handled
sleep 1

DEVICES=""

for BLACKLIST in ${BLACKLIST_NAMES}
do
  PATH="/sys/bus/hid/drivers/${BLACKLIST}"
  if [[ -e ${PATH} ]]
  then
    cd $PATH
    for file in *
    do
      if [[ x${file:0:4} == x0003 ]]
      then
        VID=${file:5:4}
        PID=${file:10:4}
	if [[ x$VID == x$APPLE_VID ]]
	then
	  for REF_PID in $PIDS
	  do
            if [[ x$PID == x$REF_PID ]]
	    then
              DEVICES+=" ${file}"
	      echo ${file} > unbind
	    fi
	  done
	fi
      fi
    done
  fi
done

cd /sys/bus/hid/drivers/${TARGET_NAME/hid-/}
for dev in ${DEVICES}
do
  echo ${dev} > bind
done


