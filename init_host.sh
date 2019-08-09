#!/bin/bash

if [ ! -f key_rsa ]; then
	ssh-keygen -t rsa -f key_rsa -q -N ''
fi
