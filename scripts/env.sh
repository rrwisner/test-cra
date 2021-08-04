#!/bin/sh
# line endings must be \n, not \r\n !
echo "window._env_ = {" > ./build/config.js
awk -F '=' '{ print "  " $1 ": \"" (ENVIRON[$1] ? ENVIRON[$1] : $2) "\"," }' ./.env >> ./build/config.js
echo "}" >> ./build/config.js
