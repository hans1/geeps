#!/bin/sh
#Psync Time Synchroniser Autorun 
#Synchronises system and hardware clock to a public time server
#Robert Lane 2010 2011(tasmod)

function iswireless  {
      while [ -z "$ESSID" ]
        do
         ESSID=`iwconfig | grep 'ESSID'`
        continue
        done
        sleep 15  #Just to make sure connection is stable.
        exec /usr/local/psync/psyncfunc $TIMEPLACE
 }
 
 TIMEPLACE=`cat /usr/local/psync/setcountry | tail -n 1`
 
 iswifi=`iwconfig | grep 'wlan'`
 
 if [ -z "$iswifi" ]
  then
   exec /usr/local/psync/psyncfunc $TIMEPLACE
  else
   iswireless
  fi      