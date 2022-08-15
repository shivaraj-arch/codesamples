#!/bin/bash
# Script to install debian packages, check status, terminate services on nodes of cluster or clusters using amazon elastic compute cloud commands
# Copyright (C) 2015 Shivaraj - All Rights Reserved
# Permission to copy and modify is granted under the GPLv3 license
# Email shivrajsys@gmail.com

#set -x

function usage()
{
cat << EOF 
usage: $0 options

This script needs a config -c paramter followed by config file full path.

OPTIONS:
   -c      Config file (Mandatory)
   -v      Verbose
   -d      debian package file
   -a      apt file name
   -s	   services
EOF
}

##
# Function : This function checks the Input Parameters
#            given by the user.
# Supported Parameters are:
#       -c <config file> This parameter is a mandatory parameter and needs to be provided
#       -v  This parameter is used to control the script verbosity (Debugging Purpose)
#       -d  If we want to install a specific package on an existing cluster or all clusters
#       -a  If one doesn't have a debian package but wants to use the ubuntu apt repository
#       -s  If one wants to install/start/stop services
#  Dispalys usage information if any mandatary parameters are missing 
function _check_params() 
{
    while getopts ":c:v:d:a:s:" OPTION; do
        case $OPTION in
            c)
                CONFIG_FILE=$OPTARG
                ;;
            v)
                VERBOSE=1
                ;;
            d)
                DPKG_FILE=$OPTARG
                ;;
            a)
                APT_PKG_NAME=$OPTARG
                ;;
            s)
                SERVICES=$OPTARG
                ;;
            ?)
                usage
                #exit
                    ;;
        esac
    done
    if [[ -z $CONFIG_FILE ]]; then
        usage
        exit 1
    fi
}

function _install_pkgs()
{
    config_file=$1

    # Get the cluster specific config file, sets various environment variablesi
    # including namenode
    . $config_file 

    # Rewrite the name node as being passed
    dpkgs=$2
    apt_pkgs=$3

    # ssh to the specific namenode and retrieve all the datanode ips
    # For each datanode if in the namenode 
    for datanodeip in `ssh $SSH_OPTS $user@$namenode "cat /etc/hadoop/conf/slaves"`; do (
        if [ $datanodeip == 'localhost' ]; then
            datanodeip=$namenode
        fi
        echo $datanodeip
        if [ -a $dpkgs ]; then
            echo "installing" $dpkgs "on" $datanodeip
            #scp $dpkgs $SSH_OPTS $user@$datanodeip:$REMOTE_HOME  
            #ssh $SSH_OPTS $user@$datanodeip "sudo dpkg --install $dpkgs"
        fi
        if [ $apt_pkgs ]; then
            echo "installing" $apt_pkgs "on" $datanodeip
            ssh $SSH_OPTS $user@$datanodeip "sudo apt-get -y install $apt_pkgs"
        fi
    ) 
    done
    wait
}

##
# Function : This function installs debian package(s) given by the user.
#            It checks the parameters passed by the user and then installs
#            any debian packages, if provided 
# Supported Parameters are:
#       - arguments passed by the user
function install_main()
{
    # Initialize the config file variable
    CONFIG_FILE=
    
    # Check the Input parameters 
    _check_params $@
    
    # Set the environment variables 
    . $CONFIG_FILE
    
    echo $DPKG_FILE
    echo $APT_PKG_NAME

    # If the cluster is true(a specific cluster), we install the package on that 
    # cluster, else we install the same on all the specified clusters    
    if [ $cluster == true ]; then
        # Get the config file for the specific cluster 
        config_file=$HOME/$ec2_user/conf/${CONFIG_FILE}_${cluster_id}
        
        # Install dpkg and apt-pkt
        _install_pkgs $config_file $DPKG_FILE $APT_PKG_NAME  
    elif [ ${cluster} == 'all' ]; then
        # Iterate over config files for all the clusters and install packages 
        for config_file in `ls $HOME/$ec2_user/conf/${CONFIG_FILE}_*| egrep ".*_[0-9]+$"`; do
            echo $config_file
            # Install dpkg and apt-pkt
            _install_pkgs $config_file $DPKG_FILE $APT_PKG_NAME  
        done
        #bash $HOME/scripts/bigdata-deploy.sh add_cluster_or_node $@ ${cluster_id}_$( date +%F_%T )
    fi
}

##
# Function : This function checks status of process(s) for a given cluster 
function _check_process_status()
{
	config=$1
	. $config

	# Walk over the list of datanodes and get the list of processes and dump the process status
	echo -e "\n\ndatanodes of ${namenode} followed by their running processes"
	for datanodeip in `ssh $SSH_OPTS $user@$namenode "cat /etc/hadoop/conf/slaves"`; do (
		if [ $datanodeip == 'localhost' ]; then
			datanodeip=$namenode
		fi
		echo -e "\n$datanodeip"
		process_list='httpd,mysql,rabbitmq-server,gearman-job-server'
		ps_bigdata_list=`echo $ps_bigdata_list|tr ',' ' '`
		ps_service_list=`echo ${process_list}|tr ',' ' '`
		for process in $ps_bigdata_list $ps_service_list; do
			status=
			if [ $process != 'presto-server' ]; then
				status=$( ssh -q $SSH_OPTS $user@$datanodeip "sudo service $process status 2>/dev/null;echo \$?" | tee | tail -1 )
				if [ $status == 0 ]; then
					echo -n " $process"
				fi
			fi
		done
		wait
		if [[ $ps_bigdata_list == *"presto-server"* ]]; then
			status=
			status=$( ssh $SSH_OPTS $user@$datanodeip "sudo /usr/share/presto-server/bin/launcher status;echo \$?" | tee | tail -1 )
			if [ $status == 0 ]; then
				echo -n " presto-server"
			fi
		fi 
	)
	done
	wait
}

##
# Function : This function checks status of cluster(s) 
#            If a specific cluster is specified, it checks for that cluster status
#            and displays the same
#            If no cluster id is specified it displays the status of all clusters
#
function check_cluster_status()
{
    CONFIG_FILE=
    _check_params $@
    . $CONFIG_FILE

    if [ ${cluster} == 'true' ]; then
        config_file=$HOME/$ec2_user/conf/${CONFIG_FILE}_${cluster_id}
	_check_process_status $config_file
    elif [ ${cluster} == 'all' ]; then
        for config_file in `ls $HOME/$ec2_user/conf/${CONFIG_FILE}_*| egrep ".*_[0-9]+$"`; do
            #echo $config_file
	    _check_process_status $config_file
        done
        wait
    fi
}

##
# Function : This function creates cluster(s) if cluster is true
#            If cluster is false and specific cluster is specified of a user,
#	     it adds datanode for that cluster 

function clusters()
{
  CONFIG_FILE=
  check_pos_params $@
  . $CONFIG_FILE

    if [ $cluster == true ]; then
	for clust in `seq 1 $no_of_clusters`
	  do
	    (
	     echo "bash $HOME/scripts/bigdata-deploy.sh add_cluster_or_node $@ $clust"
	    ) & 
	      done
	      wait
    elif [ $cluster == false ]; then
      bash $HOME/scripts/bigdata-deploy.sh add_cluster_or_node $@ ${cluster_id}_$( date +%F_%T )
   fi
}

##
# Function : This function terminates cluster(s) or nodes as passed to them 
#            If a specific cluster is specified, it terminates that cluster
#	     If a specific terminable nodes are specified, it terminates only them
#            If no cluster id is specified it terminates all clusters of user
#

function _terminate_cluster_or_node()
{
	config_file=$1
	. $config_file
	if [[ $terminable_nodes ]]; then
		cluster_nodes=${terminable_nodes/,/ } 
	else
		cluster_nodes=`ssh $SSH_OPTS $user@$namenode "cat /etc/hadoop/conf/slaves"`
	fi
	#cluster_nodes=echo $cluster_nodes | tr '\n' ','
	for i in `echo "${cluster_nodes/localhost/$namenode}"`; do
		j=`ec2-describe-instances --filter "ip-address=*" --aws-access-key ${aws_access_key_id} --aws-secret-key ${aws_secret_access_key} --region ${region}  |grep INSTANCE | cut -f17,18 | tr -s ' '|grep $i`
		j=${j/$i/}
		j=`echo $j|tr -s ' '`
		node_id=`ec2-describe-instances --filter "ip-address=$j" --aws-access-key ${aws_access_key_id} --aws-secret-key ${aws_secret_access_key} --region ${region} | grep INSTANCE | cut -f2`

		cluster_nodes_id="$cluster_nodes_id $node_id"
		if [[ $node_id ]]; then
			echo  $i $node_id 
		else
			terminated_list="$terminated_list $i"
			echo "$i already terminated"
		fi
	done
	echo $cluster_nodes_id will be terminated
	python ec2boto.py '[' ${cluster_nodes_id} ']' $CONFIG_FILE
	for del_node in $terminated_list:
	do
	      ssh $SSH_OPTS $user@$namenode "sudo sed -i /^$del_node$/d /etc/hadoop/conf/slaves"
	      ssh $SSH_OPTS $user@$namenode "sudo sed -i s/\s*${del_node}\s*//g /etc/spark/conf/slaves"
	done
	wait
}


##
# Function : This function calls to terminates cluster(s) or node(s)
#            If a specific cluster is specified, it terminates that cluster
#	     If a specific terminable nodes are specified, it terminates only them
#            If no cluster id is specified it terminates all clusters of user
#

function ec2_terminate_cluster_or_node()
{
	CONFIG_FILE=
	_check_params $@
	. $CONFIG_FILE

	if [ ${cluster} == 'true' ]; then
		config_file=$HOME/$ec2_user/conf/${CONFIG_FILE}_${cluster_id}
		_terminate_cluster_or_node $config_file
	elif [ ${cluster} == 'all' ]; then
        	for config_file in `ls $HOME/$ec2_user/conf/${CONFIG_FILE}_*| egrep ".*_[0-9]+$"`; do
	    		_terminate_cluster_or_node $config
        	done
        	wait
	elif [ ${cluster} == 'false' ]; then
		_terminate_cluster_or_node $config_file
		
	fi
}
##
# Function : This function calls to install/start/stop services on cluster(s) or node(s)
#            If a specific cluster is specified, it services that cluster
#            If cluster is false, it services the namenode 
#            If no cluster id is specified it services all clusters of user
#
function _services()
{
	config_file=$1
	SERVICES=$2
	. $config_file
	if [ ${cluster} == 'false' ]; then
		cluster_nodes=${namenode} 
	else
		cluster_nodes=`ssh $SSH_OPTS $user@$namenode "cat /etc/hadoop/conf/slaves"`
	fi
	#cluster_nodes=echo $cluster_nodes | tr '\n' ','
	for i in `echo "${cluster_nodes/localhost/$namenode}"`; do
		nodeip=`echo $i|tr -s ' '`
		cat $config_file $HOME/scripts/puppet_${SERVICES}_services.sh | ssh $SSH_OPTS $user@$nodeip sudo bash
	done
}
##
# Function : This function calls to install/start/stop services on cluster(s) or node(s)
#            If a specific cluster is specified, it services that cluster
#            If no cluster id is specified it services all clusters of user
#
function  services_on_cluster_or_node()
{
	CONFIG_FILE=
	_check_params $@
	. $CONFIG_FILE

	if [ ${cluster} == 'true' ]; then
		config_file=$HOME/$ec2_user/conf/${CONFIG_FILE}_${cluster_id}
		_services $config_file $SERVICES

	elif [ ${cluster} == 'all' ]; then
        	for config_file in `ls $HOME/$ec2_user/conf/${CONFIG_FILE}_*| egrep ".*_[0-9]+$"`; do
			_services $config_file $SERVICES
        	done
        	wait
	elif [ ${cluster} == 'false' ]; then
		_services $config_file $SERVICES
		
	fi
}
$@
