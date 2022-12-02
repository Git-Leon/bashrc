#!/bin/bash
origin=$(git remote -v | grep fetch)
origin=$(echo ${origin/"upstream        "/""})
origin=$(echo ${origin/"upstream"/""})
origin=$(echo ${origin// (fetch)/})
origin=$(echo ${origin/"origin"/""})
start $origin