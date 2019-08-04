#!/bin/bash

sleep 30

# get current date (time)
hour=`date +%k`

# if 6:00 <= current date < 9:00, autologin to salesforce
if [ $hour -ge 6 -a $hour -lt 9 ]; then
    ruby ./autologin_salesforce.rb regular_arrival
fi
