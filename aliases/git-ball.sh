#!/bin/bash
git branch -r | grep -v '\->' | \
while read remote; do
    echo ${remote#origin/}
done