#!/bin/bash

shopt -s expand_aliases

alias RCMD="ssh -o StrictHostKeyChecking=no -p 2222 localhost"

RCMD reboot

