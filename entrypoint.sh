#!/bin/bash

function install(){
    echo "install"
    rm -rf /home/gpdb/.bashrc
    echo "source ${GPHOME}/greenplum_path.sh" >> /home/gpdb/.bashrc
    echo "export MASTER_DATA_DIRECTORY=/srv/gpmaster/gpsne-1" >> /home/gpdb/.bashrc
    echo "" >> /home/gpdb/.bashrc
    rm -rf /home/gpdb/.bash_profile
    echo "if [ -f ~/.bashrc ]; then" >> /home/gpdb/.bash_profile
    echo "    source ~/.bashrc" >> /home/gpdb/.bash_profile
    echo "fi" >> /home/gpdb/.bash_profile
    echo "" >> /home/gpdb/.bash_profile
    chown -R gpdb:gpdb /home/gpdb
}

function start_singlenode(){
    echo "start_singlenode"
    service ssh start
    exec sudo -i --preserve-env=MALLOC_ARENA_MAX,TZ,GP_DB,GP_USER,GP_PASSWORD,GPHOME -u gpdb /entrypoint.sh start_singlenode_gpdb
}

function start_singlenode_gpdb(){
    echo "start_singlenode_gpdb"
    sleep infinity & PID=$!
    trap "kill $PID" INT TERM
    export HOME="/home/gpdb"
    cd $HOME
    source "/home/gpdb/.bashrc"
    export MASTER_HOSTNAME="$(hostname)"
    echo "$MASTER_HOSTNAME" > ./hostlist_singlenode
    if [ -f "/srv/gpmaster/gpsne-1/pg_hba.conf" ]; then
        echo "Skipping setup because we already have master files."
        gpssh-exkeys -f hostlist_singlenode
        gpstart -a
    else
        rm -rf ./gpinitsystem_singlenode
        echo "MASTER_MAX_CONNECT=16" >> ./gpinitsystem_singlenode
        echo "BATCH_DEFAULT=4" >> ./gpinitsystem_singlenode
        echo "ARRAY_NAME=\"GPDB SINGLENODE\"" >> ./gpinitsystem_singlenode
        echo "MACHINE_LIST_FILE=./hostlist_singlenode" >> ./gpinitsystem_singlenode
        echo "SEG_PREFIX=gpsne" >> ./gpinitsystem_singlenode
        echo "PORT_BASE=6000"  >> ./gpinitsystem_singlenode
        echo "declare -a DATA_DIRECTORY=(/srv/gpdata)" >> ./gpinitsystem_singlenode
        echo "MASTER_HOSTNAME=\"$MASTER_HOSTNAME\""  >> ./gpinitsystem_singlenode
        echo "MASTER_DIRECTORY=/srv/gpmaster" >> ./gpinitsystem_singlenode
        echo "MASTER_PORT=5432"  >> ./gpinitsystem_singlenode
        echo "TRUSTED_SHELL=ssh"   >> ./gpinitsystem_singlenode
        echo "CHECK_POINT_SEGMENTS=1" >> ./gpinitsystem_singlenode
        echo "ENCODING=UNICODE" >> ./gpinitsystem_singlenode
        echo "DATABASE_NAME=\"$GP_DB\"" >> ./gpinitsystem_singlenode
        echo "" >> ./gpinitsystem_singlenode
        gpssh-exkeys -f hostlist_singlenode
        gpinitsystem -c gpinitsystem_singlenode -a
        echo 'host     all         all           0.0.0.0/0  md5' >> /srv/gpmaster/gpsne-1/pg_hba.conf
        gpstop -u -a
        echo "Will create db user $GP_USER for $GP_DB"
        psql -c "create user $GP_USER with password '$GP_PASSWORD';" "$GP_DB"
    fi
    echo "Waiting for sigint or sigterm"
    wait
    gpstop -a -M fast
}
   
if [ "${USER}" == "gpdb" ]; then
    start_singlenode_gpdb
else
    install
    start_singlenode
fi
