#!/bin/bash

shopt -s expand_aliases

alias RCMD="ssh -o StrictHostKeyChecking=no -p 2222 -t localhost"
alias RCP="scp -P 2222"

RCMD echo "testdev ready to go!!!"
RCMD echo "testdev ready to go!!!"
RCMD echo "testdev ready to go!!!"

