#!/bin/bash

BUILD='docker build -t base/sio/packages/scripts:1.7.3 .'

echo
echo "<Socket.io> $BUILD"
echo

$BUILD
