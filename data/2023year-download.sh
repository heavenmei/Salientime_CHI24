#!/bin/bash

GREP_OPTIONS=''

cookiejar=$(mktemp cookies.XXXXXXXXXX)
netrc=$(mktemp netrc.XXXXXXXXXX)
chmod 0600 "$cookiejar" "$netrc"
function finish {
  rm -rf "$cookiejar" "$netrc"
}

trap finish EXIT
WGETRC="$wgetrc"

prompt_credentials() {
    echo "Enter your Earthdata Login or other provider supplied credentials"
    read -p "Username (heavenmei): " username
    username=${username:-heavenmei}
    read -s -p "Password: " password
    echo "machine urs.earthdata.nasa.gov login $username password $password" >> $netrc
    echo
}

exit_with_error() {
    echo
    echo "Unable to Retrieve Data"
    echo
    echo $1
    echo
    echo "https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/07/MERRA2_400.tavg1_2d_slv_Nx.20230701.nc4"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/07/MERRA2_400.tavg1_2d_slv_Nx.20230701.nc4 -w '\n%{http_code}' | tail  -1`
    if [ "$approved" -ne "200" ] && [ "$approved" -ne "301" ] && [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w '\n%{http_code}' https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/07/MERRA2_400.tavg1_2d_slv_Nx.20230701.nc4 | tail -1)
    if [[ "$status" -ne "200" && "$status" -ne "304" ]]; then
        # URS authentication is required. Now further check if the application/remote service is approved.
        detect_app_approval
    fi
}

setup_auth_wget() {
    # The safest way to auth via curl is netrc. Note: there's no checking or feedback
    # if login is unsuccessful
    touch ~/.netrc
    chmod 0600 ~/.netrc
    credentials=$(grep 'machine urs.earthdata.nasa.gov' ~/.netrc)
    if [ -z "$credentials" ]; then
        cat "$netrc" >> ~/.netrc
    fi
}

fetch_urls() {
  if command -v curl >/dev/null 2>&1; then
      setup_auth_curl
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        curl -f -b "$cookiejar" -c "$cookiejar" -L --netrc-file "$netrc" -g -o $stripped_query_params -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  elif command -v wget >/dev/null 2>&1; then
      # We can't use wget to poke provider server to get info whether or not URS was integrated without download at least one of the files.
      echo
      echo "WARNING: Can't find curl, use wget instead."
      echo "WARNING: Script may not correctly identify Earthdata Login integrations."
      echo
      setup_auth_wget
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        wget --load-cookies "$cookiejar" --save-cookies "$cookiejar" --output-document $stripped_query_params --keep-session-cookies -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  else
      exit_with_error "Error: Could not find a command-line downloader.  Please install curl or wget"
  fi
}

fetch_urls <<'EDSCEOF'
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/07/MERRA2_400.tavg1_2d_slv_Nx.20230701.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230630.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230629.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230628.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230627.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230626.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230625.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230624.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230623.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230622.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230621.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230620.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230619.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230618.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230617.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230616.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230615.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230614.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230613.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230612.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230611.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230610.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230609.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230608.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230607.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230606.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230605.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230604.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230603.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230602.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/06/MERRA2_400.tavg1_2d_slv_Nx.20230601.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230531.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230530.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230529.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230528.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230527.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230526.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230525.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230524.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230523.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230522.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230521.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230520.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230519.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230518.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230517.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230516.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230515.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230514.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230513.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230512.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230511.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230510.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230509.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230508.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230507.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230506.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230505.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230504.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230503.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230502.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/05/MERRA2_400.tavg1_2d_slv_Nx.20230501.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230430.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230429.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230428.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230427.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230426.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230425.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230424.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230423.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230422.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230421.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230420.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230419.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230418.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230417.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230416.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230415.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230414.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230413.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230412.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230411.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230410.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230409.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230408.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230407.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230406.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230405.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230404.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230403.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230402.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/04/MERRA2_400.tavg1_2d_slv_Nx.20230401.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230331.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230330.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230329.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230328.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230327.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230326.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230325.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230324.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230323.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230322.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230321.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230320.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230319.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230318.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230317.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230316.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230315.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230314.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230313.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230312.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230311.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230310.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230309.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230308.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230307.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230306.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230305.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230304.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230303.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230302.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/03/MERRA2_400.tavg1_2d_slv_Nx.20230301.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230228.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230227.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230226.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230225.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230224.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230223.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230222.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230221.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230220.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230219.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230218.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230217.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230216.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230215.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230214.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230213.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230212.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230211.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230210.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230209.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230208.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230207.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230206.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230205.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230204.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230203.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230202.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/02/MERRA2_400.tavg1_2d_slv_Nx.20230201.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230131.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230130.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230129.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230128.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230127.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230126.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230125.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230124.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230123.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230122.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230121.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230120.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230119.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230118.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230117.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230116.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230115.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230114.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230113.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230112.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230111.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230110.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230109.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230108.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230107.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230106.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230105.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230104.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230103.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230102.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXSLV.5.12.4/2023/01/MERRA2_400.tavg1_2d_slv_Nx.20230101.nc4
EDSCEOF