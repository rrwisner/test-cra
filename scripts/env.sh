#!/bin/bash

export CONFIG_FILENAME=./build/config.js
export ENV_FILENAME=.env
export ENV_TEMP=.env_clean

echo "" >> $ENV_FILENAME
sed '/^$/d' $ENV_FILENAME > $ENV_TEMP
cp $ENV_TEMP $ENV_FILENAME
rm -f $ENV_TEMP

echo "=============================="
echo "Printing $ENV_FILENAME:"
cat .env
echo ""

# Recreate config file
rm -rf $CONFIG_FILENAME
touch $CONFIG_FILENAME

# Add assignment 
echo "window._env_ = window._env_ || {};" >> $CONFIG_FILENAME

COUNTER=0

# Read each line in .env file
# Each line represents key=value pairs
while read -r line; do 

  COUNTER=$((COUNTER+1))

  echo "=============================="
  echo "Printing line $COUNTER:"
  echo $line
  echo ""

  # Split env variables by character `=`
  varname=$(printf "$line" | sed -e 's/=.*//')
  varvalue=$(printf "$line" | sed -e 's/^[^=]*=//')

  # # Read value of current variable if exists as Environment variable
  value="${!varname}"

  # # Otherwise use value from .env file
  [[ -z $value ]] && value=${varvalue}

  # Append configuration property to JS file
  echo "window._env_.$varname = '$value';" >> $CONFIG_FILENAME

done < $ENV_FILENAME

echo ""
echo "=============================="

echo ""
echo "Printing $CONFIG_FILENAME:"
cat $CONFIG_FILENAME
echo ""
