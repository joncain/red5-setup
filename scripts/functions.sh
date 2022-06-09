#!/bin/bash

function prompt_key() {
  keys=(
    "api.accessToken" "cloud.do_api_token" "cloud.do_ssh_key_name" "config.dbHost" "config.dbPort" "config.dbUser" "config.dbPass"
    "instancecontroller.instanceNamePrefix" "cluster.password" "#terra.regionNames" "#terra.instanceName" "#terra.host" "#terra.port"
    "#terra.token" "serverapi.accessToken" "rest.administratorToken" "proxy.enabled" 
    "services" "ffmpeg.path" "do.access.key" "do.secret.access.key" "do.bucket.name" "do.bucket.location"
  )
  for k in "${keys[@]}"; do
    if [[ "${1}" = "${k}" ]]; then
      echo "true"
      break
    fi
  done
}

function edit_config() {
  file="$1"

  properties=()
  echo "Enter new value for each key, or press enter to use the (default)"

  # Read all the properties and prompt for specific known keys
  # (Over)Write the results to the properties file.
  while IFS='=' read -r key val <&3; do
    # Only prompt for specific keys.
    if [[ $(prompt_key "${key}") = "true" ]]; then
      echo -n "${key} (${val}):"

      read -r newval
      if [[ ! -z $newval ]]; then
        # User entered a value, use it.
        val="${newval}"
      fi  

      if [[ "${key}" =~ ^#.*$ ]]; then
        # This is a know key that is commented. Remove the Preceeding # to uncomment
        key="${key//#/}"
      fi
    fi

    if [[ -z "${key}" || "${key}" =~ ^#.*$ ]]; then
      # This is either a blank line or a comment
      properties=("${properties[@]}" "${key}")
    else
      properties=("${properties[@]}" "${key}=${val}")
    fi
  done 3< $file

  echo "RESULTS----------------"

  for prop in "${properties[@]}"; do
    printf '%s\n' "${prop}"
  done > $file
}