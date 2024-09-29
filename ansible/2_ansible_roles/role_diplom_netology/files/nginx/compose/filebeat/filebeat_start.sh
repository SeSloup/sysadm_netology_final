#!/bin/bash
filebeat modules enable nginx
filebeat -e
rm /usr/share/filebeat/data/filebeat.lock
filebeat setup
filebeat --strict.perms=false


