#!/bin/bash

vagrant up --provider virtualbox
vagrant destroy -f
vagrant ssh <name>
vagrant global-status
