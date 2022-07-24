#!/bin/bash
if [ "$1" ]
then
    python -m http.server $1
fi