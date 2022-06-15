#!/bin/bash

function prompt_key() {
  # These are known keys from all the configuration files. If the key exists in the file being edited,
  # the user will be prompted for a value. Some of them are prefixed with a # symbol, that is 
  # intentional as they are commented out in their current state and will be uncommented in their
  # final state.
  keys=(
    "api.accessToken" "cloud.do_api_token" "cloud.do_ssh_key_name" "config.dbHost" "config.dbPort"
    "config.dbUser" "config.dbPass" "instancecontroller.instanceNamePrefix" "cluster.password" "#terra.regionNames"
    "#terra.instanceName" "#terra.host" "#terra.port" "#terra.token" "serverapi.accessToken"
    "rest.administratorToken" "proxy.enabled"
  )
  for k in "${keys[@]}"; do
    if [[ "${1}" = "${k}" ]]; then
      echo "true"
      break
    fi
  done
}

function edit_config() {
  # Load the .env file
  export $(cat "$(current_dir)/.env" | xargs)
  file="$1"

  properties=()
  echo "Enter new value for each key, or press enter to use the (default)"

  # Read all the properties and prompt for specific known keys
  # (Over)Write the results to the properties file.
  while IFS='=' read -r key val <&3; do
    # Only prompt for specific keys.
    if [[ $(prompt_key "${key}") = "true" ]]; then
      # If we have a value from the environment, use it.
      envval=$(get_env_var "${key}")
      val=${envval:-$val}

      echo -n "${key} (${val}):"

      read -r newval
      if [[ ! -z $newval ]]; then
        # User entered a value, use it.
        val="${newval}"
      fi  

      if [[ "${key}" =~ ^#.*$ ]]; then
        # This is a known key that is commented. Remove the Preceeding # to uncomment
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

  for prop in "${properties[@]}"; do
    printf '%s\n' "${prop}"
  done > $file
}

function exec_sed() {
  file="$1"
  sed_command="$2"

  # 1. Format XML without indents
  # 2. strip out remaining tabs and new lines
  # 3. Comment bean
  # 4. Format with tab indentation
  # 5. Write out the file
  xmlstarlet format -n $file \
  | tr -d '\t\n' \
  | sed "$sed_command" \
  | xmlstarlet format -t \
  | sponge $file
}

function current_dir() {
  SCRIPT_PATH=`realpath "$0"`
  SCRIPT_DIR=`dirname "$SCRIPT_PATH"`
  echo $SCRIPT_DIR
}

function get_env_var() {
  key="$1"

  # Conform the key to the env format.
  # 1) Replace . with _
  # 2) Remove comment #
  # E.g.,
  # do.my.keyFoo -> do_my_keyFoo
  # some.commented.key -> some_commented_key
  envkey="${key//./_}"
  envkey="${envkey/\#/}"
  envval=$(printenv "r5_${envkey}")
  echo $envval
}