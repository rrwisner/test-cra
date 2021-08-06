#!/bin/bash

export CONFIG_FILENAME=./build/config.js

# Recreate config file
rm -rf $CONFIG_FILENAME
touch $CONFIG_FILENAME

# Add assignment 
echo "window._env_ = window._env_ || {};" >> $CONFIG_FILENAME

# Read each line in .env file
# Each line represents key=value pairs
while read -r line || [[ -n "$line" ]];
do
  # Split env variables by character `=`
  if printf '%s\n' "$line" | grep -q -e '='; then
    varname=$(printf '%s\n' "$line" | sed -e 's/=.*//')
    varvalue=$(printf '%s\n' "$line" | sed -e 's/^[^=]*=//')
  fi

  # Read value of current variable if exists as Environment variable
  value=$(printf '%s\n' "${!varname}")
  # Otherwise use value from .env file
  [[ -z $value ]] && value=${varvalue}

  # Append configuration property to JS file
  echo "window._env_.$varname = '$value';" >> $CONFIG_FILENAME
done < .env
