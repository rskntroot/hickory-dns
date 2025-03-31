#!/bin/sh

if [ -f /usr/local/bin/hickory-dns ]; then
  /usr/local/bin/hickory-dns --version;
else
  echo '[Entrypoint] Error: "hickory-dns" application was not found in "/root/.cargo/bin/"';
fi

if [ -z "${HICKORY_DIR}" ]; then
    HICKORY_DIR=/etc/hickory
fi

if [ ! -f ${HICKORY_DIR}/default.toml ]; then
  echo '[Entrypoint] Error: "default.toml" not found. Ensure volume is mounted properly.' >&2
  exit 1
fi

CONF=${HICKORY_DIR}/config.toml
ZONES_DIR=${HICKORY_DIR}/zones
UPSTREAM_TXT=${HICKORY_DIR}/upstream.txt
BLOCKLISTS_FILE=${HICKORY_DIR}/blocklists.txt

## Add Primary Zone Configuration Files
primary_zone_handler() {
  if [ -d "${ZONES_DIR}" ]; then
    for file in ${ZONES_DIR}/*; do
      [ -f "$file" ] || continue
      filename=$(basename "$file")
      if [ "${filename}" != "example.org" ]; then
        {
          echo ""
          echo [[zones]]
          echo zone = \"$filename\"
          echo zone_type = \"Primary\"
          echo file = \"${file}\"
        } >> ${CONF};
      fi;
    done;
  fi
}

# Import Blocklists
blocklist_handler() {
  if [ -f "$BLOCKLISTS_FILE" ]; then
    {
      echo ""
      echo [[zones.stores]]
      echo type = \"blocklist\"
      echo wildcard_match = true
      echo min_wildcard_depth = 2
      echo sinkhole_ipv4 = \"192.0.2.1\"
      echo sinkhole_ipv6 = \"::ffff:c0:0:2:1\"
      echo block_message = \"This query has been blocked by the DNS server\"
    } >> ${CONF};
    urls=$(cat ${BLOCKLISTS_FILE});
    blocklist_dir=${HICKORY_DIR}/blocklists;
    mkdir -p ${blocklist_dir};
    for line in ${urls}; do
        name=$(echo "${line}" | awk -F '=' '{print $1}')
        type=$(echo "${line}" | awk -F '=' '{print $2}')
        url=$(echo "${line}" | awk -F '=' '{print $3}')
        curl -sLo ${blocklist_dir}/temp ${url};
        if [ "${type}" == "hosts" ]; then
            awk '/# Start StevenBlack/ {found=1; next} found && !/^#/ {print $2}' ${blocklist_dir}/temp > ${blocklist_dir}/${name}
        else
            grep -E '^[^#][^$]' ${blocklist_dir}/temp > ${blocklist_dir}/${name};
        fi
        rm -f ${blocklist_dir}/temp
    done
    {
      for i in $(ls ${blocklist_dir}); do
      lists=$(echo ${lists} \"blocklists/${i}\",); done
      echo lists = [ $(echo ${lists} | sed 's/,$//') ]
    } >> ${CONF}
  fi
  mkdir -p /var/named && ln -s /etc/hickory/blocklists /var/named/blocklists
}

## Add Forwarder Configuration File
upstream_handler() {
  if [ -f ${UPSTREAM_TXT} ]; then
    {
      echo ""
      echo [[zones]]
      echo zone = \".\"
      echo zone_type = \"External\"
    } >> ${CONF};
    blocklist_handler
    {
      echo ""
      echo [[zones.stores]]
      echo type = \"forward\"
    } >> ${CONF};
    upstreams=$(cat ${UPSTREAM_TXT});
    for upstream in ${upstreams}; do
      echo "$upstream" | awk -F '/' '
      {
        print ""
        print "[[zones.stores.name_servers]]"
        print "socket_addr = \"" $1 "\""
        print "protocol = \"" $2 "\""
        print "trust_negative_responses = false"
      }' >> ${CONF};
    done;
  fi
}

## Create Configuration File

if [ ! -f ${HICKORY_DIR}/config.toml ]; then
    cp ${HICKORY_DIR}/default.toml ${CONF}
    primary_zone_handler
    upstream_handler
fi

## Run Hickory DNS

/usr/local/bin/hickory-dns --config ${HICKORY_DIR}/config.toml --debug;

#`lost`25
