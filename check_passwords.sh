#!/bin/bash

check_pwndb() {
	  hash="$(echo -n ${password} | openssl sha1 | cut -d' ' -f2)"
	  upperCase="$(echo ${hash} | tr '[a-z]' '[A-Z]')"
	  prefix="${upperCase:0:5}"
	  suffix="${upperCase:5}"
	  response=$(curl -s "https://api.pwnedpasswords.com/range/${prefix}")

	  if [ $? == "0" ]; then
	  	while read -r line; do
		# Only first 35 chars of response line is hash suffix
			if [ "${line:0:35}" == "${suffix}" ]; then
			# Password was found in pwndb... output password, hash as in pwnd and no. times it's been seen in breaches
				echo -e "${password}\t\t${prefix}${line}"
				return 0
			fi
			done <<< "${response}"
			[ "${successonly}" != "true" ] && echo -e "${password}\t\tnot found"
	               return 1
  else
    echo -e "${password}\t\tAPI call failed"
    return 1
  fi
}

main() {
  while getopts 'sf:' option
  do
    case ${option} in
      s) successonly="true" ;;
      f) passwordlist="${OPTARG}" ;;
      *) echo -e "Check PASSWORDS on haveibeenpwned.com (pwndb)\n"
         echo -e "Usage: $(basename ${0}) [-s] [-f <filename>]"
         echo -e "\t\t-s                Suppress reporting of unbreached passwords"
         echo -e "\t\t-f password list  Get passwords to test from file, one per line"
         exit 1 ;;
    esac
  done
  shift "$((OPTIND - 1))"

  # If one arg passed, use this as input
  if [ $# == "1" ]; then
    password=${1}
    check_pwndb
    exit $?
  # Or read input from file if '-f' used
  elif [ -n "${passwordlist}" ]; then
    if [ -s "${passwordlist}" ]; then
      while read -r password; do
        check_pwndb
      done < "${passwordlist}"
      exit 0
    else
      echo "File '${passwordlist}' not found or is empty"
      exit 1
    fi
  # Or just prompt for input if none was passed in
  else
    echo -n "Password: "
    read -s password
    echo
    check_pwndb
    exit $?
  fi
}

main "$@"
