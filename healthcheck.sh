#!/bin/bash

if [ $(consul members | grep -c alive) -eq 0 ]; then
    exit 1
elif [ $(consul members -status=alive | grep -c server) -eq 0 ]; then
    exit 1
else
    exit 0
fi

