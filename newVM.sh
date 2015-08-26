#!/bin/bash

# Ecrit par Valentin OUVRARD pour Nautile.NC 2015

# Ce script permet de créer ou cloner une VM sous Ganeti avec Xen.

# Actuellement ce script supporte 3 modes, Debian 8, Ubuntu 14.04 et clonage d'une VM existante.

###############################################################
#################### Paramètres de Ganeti #####################
###############################################################
# Le master correspont au node par défaut à la création
GNT_MASTER="a2.nautile.in"

# Ce node correspond au deuxième node par défaut
GNT_NODE="a3.nautile.in"

DEFAULT_VLAN=""

VG_MASTER="vgganeti"
###############################################################

## --help function
Help () {
	echo
	tput bold; echo "NewVM.sh v0.1`tput sgr0` - Create a Ganeti Virtual Machine"
	echo "Author: Valentin OUVRARD"
	echo "Usage: newVM.sh --name <NAME> --disk <DISK> --ram <RAM> "
	echo
	echo "Options:"
	echo
	echo "	--name    <VM_NAME>		New virtual machine hostname"
	echo "	--disk    <DISK>		Disk size in gigabytes (G|g)"
	echo "	--ram 	  <RAM>			Memory size in gigabytes (G|g)"
	echo "	--vcpu    <VCPU>		Virtual CPU number"
	echo "	--nodes   <NODES>		First node and second node(1st:2nd) "
	echo "	--clone   <CLONE>		Name of a VM to clone"
	echo "	--variant <OS>			Choose between trusty and jessie (by default)"
	echo "	--no-confirm			Disable VM creation's confirmation"
	echo
	echo "Networking options:"
	echo
	echo "	--ipv4 	  <IPV4>		Virtual machine IPV4 Address "
	echo "	--gw      <GW>			Virtual machine IPV4 Gateway"
	echo "	--netmask <MASK>		Virtual machine IPV4 Netmask (CIDR)"
	echo "	--ipv6 	  <IPV6>		Virtual machine IPV6 Address "
	echo "	--vlan 	  <VLAN>		Specify a VLAN for eth0 (none by default) "	
	echo
	echo "Advanced Disk options:	(in gigabytes)"
	echo
	echo "	--root    <ROOT>		Give the / partition size"
	echo "	--boot    <BOOT>		Give the /boot partition size (in megabytes)"
	echo "	--swap	  <SWAP>		Give the SWAP partition size"
	echo "	--tmp	  <TMP>			Give the /tmp partition size (in megabytes)"
	echo "	--usr	  <USR>			Give the /usr partition size"
	echo "	--var  	  <VAR>			Give the /var partition size"
	echo "	--vlog 	  <VARLOG>		Give the /var/log partition size"	
	echo "	--plain				Create the VM with plain disk (no drbd)"
	echo
	echo "Examples:"
	echo
	echo "	./newVM.sh --name vm1 --disk 15G --ram 2G"
	echo "	./newVM.sh --name vm2 --disk 15G --ram 2G --var 4G --ipv4 192.168.1.42"
	echo
}

## Min - Max variables  #### MODIFIABLE !
MIN_RAM_SIZE=1
MAX_RAM_SIZE=30

MIN_DISK_SIZE=9
MAX_DISK_SIZE=100

MIN_ROOT_SIZE=3
MAX_ROOT_SIZE=90

MIN_BOOT_SIZE=200
MAX_BOOT_SIZE=800

MIN_VAR_SIZE=1
MAX_VAR_SIZE=90

MIN_VLOG_SIZE=1
MAX_VLOG_SIZE=90

MIN_USR_SIZE=2
MAX_USR_SIZE=90

MIN_TMP_SIZE=100
MAX_TMP_SIZE=1024

MIN_SWAP_SIZE=1
MAX_SWAP_SIZE=10

MIN_VCPU=1
MAX_VCPU=2

###############################################################
## Nothing to modify downstair !! 							 ##
###############################################################


## Is IPV4 ?
function isIPv4 {
if [ $# = 1 ]
	then
 		printf $1 | grep -Eq '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-4]|2[0-4][0-9]|[01]?[1-9][0-9]?)$'
 		return $?
	else
 		return 2
fi
}

## CIDR 2 NetMASK
cdr2mask ()
{
	      set -- $(( 5 - ($1 / 8) )) 255 255 255 255 $(( (255 << (8 - ($1 % 8))) & 255 )) 0 0 0
	         [ $1 -gt 1 ] && shift $1 || shift
		    echo ${1-0}.${2-0}.${3-0}.${4-0}
		}

function trap_ctrlc ()
{

    	echo "  Vous avez taper CTRL+C,"
    	tput bold; tput setaf 4;
 		read -r -p "Voulez-vous vraiment quitter ? [o/N] " response
 		tput sgr0
		case $response in
    		[oO][eE][sS]|[oO]) 
				echo
     		  	tput bold ; tput setaf 1
     		   	echo "Vous avez quitté.." ; tput sgr0; echo ; exit 1
        		;;
    		*)  echo
    	    	;;
		esac
}

## Catchons les arguments !
while [ "$1" != "" ]; do
	case $1 in
# obligatoires
		--name ) shift
			VM_NAME=$1 
		;;
		--disk ) shift
			DISK=$1 
		;;
		--ram ) shift
			RAM=$1 
		;;
# facultatifs
 		--vcpu ) shift
			VCPU=$1 
		;;
		--nodes ) shift
			NODES=$1
		;;
 		--clone ) shift
			CLONE=True ; CLONE_FROM=$1
		;;
		--variant ) shift
			OS=$1
		;;
 		--no-confirm ) 
			CONFIRM=False
		;;
# network
 		--ipv4 ) shift
			IPV4=$1
		;;
		 --netmask ) shift
			NETMASK=$1
		;;
		--gw ) shift
			GW=$1
		;;
 		--ipv6 ) shift
			IPV6=$1
		;;
		--vlan ) shift
			DEFAULT_VLAN=$1
		;;

# Disks
		--root ) shift
			ROOT=$1
		;;
		--boot ) shift
			BOOT=$1
		;;
		--var ) shift
			VAR=$1
		;;
		--vlog ) shift
			VLOG=$1
		;;
		--usr ) shift
			USR=$1
		;;
		--tmp ) shift
			TMP=$1
		;;
		--swap ) shift
			SWAP=$1
		;;
		--plain ) 
			DISK_METHOD=plain

		;;

	    * | -h | --help) 
		    if [ "$1" != "-h" ] && [ "$1" != "--help" ] 
		    	then
				tput bold ; tput setaf 1; echo ; echo $1 est incorrect ! ; tput sgr0 ; echo ; Help; exit 1
		    	else   Help ; exit 1
		    fi
		
	esac
	shift
done
###############################################################
## Vérification des arguments !								 ##
###############################################################

## VM NAME
if [ -z $VM_NAME ]
	then
		echo
		echo "Vous n'avez pas précisé la nom de la VM (--name)"
		exit 1
fi

VM_NAME=`echo "${VM_NAME,,}"`

if [ "$VM_NAME" == "$CLONE_FROM" ]
	then 
		echo
		echo "Vous ne pouvez pas cloner une VM avec le même nom !"
		exit 1
fi

## OS NAME

if [ -z $OS ]
	then
		OS=jessie
fi

## DISK
if [ -z $DISK ]
	then
		echo
		echo "Vous n'avez pas précisé la taille du Disque (--disk)"
		exit 1
fi
try_disk=`echo "${DISK: -1}"`
if [ "$try_disk" == "G" ] || [ "$try_disk" == "g" ]
	then :
	else
		echo
		echo "Vous n'avez pas rentré une taille de disque en Giga (G|g)"
		exit 1
fi
DISK_SIZE=`echo $DISK | sed 's/[g|G]//' `
re='^[0-9]+$'
if ! [[ $DISK_SIZE =~ $re ]]
	then
		echo
		echo "Vous n'avez pas rentré un nombre pour la taille du disque"
		exit 1
fi
if [ "$DISK_SIZE" -gt $MAX_DISK_SIZE ]
	then
		echo
		echo "Vous avez spécifié une taille de disque trop élevée ! (limite "$MAX_DISK_SIZE"G)"
		exit 1
fi
if [ "$DISK_SIZE" -lt $MIN_DISK_SIZE ]
	then
		echo
		echo "Vous avez spécifié une taille de disque trop petite ! (limite "$MIN_DISK_SIZE"G)"
		exit 1
fi

## RAM
if [ -z $RAM ]
	then
		echo
		echo "Vous n'avez pas précisé la taille de la RAM (--ram)"
		exit 1
	fi
try_gram=`echo "${RAM: -1}"`
if [ "$try_gram" == "G" ] || [ "$try_gram" == "g" ]
	then :
	else
		echo
		echo "Vous n'avez pas rentré une taille de RAM en Giga (G|g)"
		exit 1
fi

RAM_SIZE=`echo $RAM | sed 's/[g|G]//' `
re='^[0-9]+$'
if ! [[ $RAM_SIZE =~ $re ]]
	then
		echo
		echo "Vous n'avez pas rentré un nombre pour la RAM"
		exit 1
fi
if [ "$RAM_SIZE" -gt $MAX_RAM_SIZE ]
	then
		echo
		echo "Vous avez spécifié un nombre de RAM trop élevé ! (limite "$MAX_RAM_SIZE"G)"
		exit 1
fi
if [ "$RAM_SIZE" -lt $MIN_RAM_SIZE ]
	then
		echo
		echo "Vous avez spécifié un nombre de RAM trop petit ! (limite "$MIN_RAM_SIZE"G)"
		exit 1
fi
###############################################################
## VCPU
if [ -z $VCPU ]
	then VCPU=$MIN_VCPU
	else 
		if [ $VCPU -gt $MAX_VCPU ]
			then 
				echo
				echo "Vous avez spécifié un nombre de VCPU trop élevé ! (limite "$MAX_VCPU")"
				exit 1
		fi
		if [ $VCPU -lt $MIN_VCPU ]
			then 
				echo
				echo "Vous avez spécifié un nombre de VCPU trop petit ! (limite "$MIN_VCPU")"
				exit 1
		fi
fi

## IPV4
if [ -z $IPV4 ]
	then :
	else
		isIPv4 $IPV4 
		verif_ipv4=`echo $?`
		if [ $verif_ipv4 -eq 1 ]
			then
				echo
				echo "Il ne s'agit pas d'une adresse IPV4 valable"
				exit 1

		fi
		if [ -z $NETMASK ]
		then NETMASK="/24"
		fi
fi

if [ -z $IPV4 ] && [ ! -z $GW ] 
	then 
				echo
				echo "Si vous précisez une Gateway, il faut précisez une ipv4."
				exit 1		
fi

if [ -z $IPV4 ] && [ ! -z $NETMASK ] 
	then 
				echo
				echo "Si vous précisez un Netmask, il faut précisez une ipv4."
				exit 1		
fi

if [ -z $IPV4 ] && [ ! -z $DEFAULT_VLAN ] 
	then 
				echo
				echo "Si vous précisez un Vlan, il faut précisez une ipv4 et/ou ipv6."
				exit 1		
fi

## GW
if [ -z $GW ]
	then :
	else
		isIPv4 $GW 
		verif_gw=`echo $?`
		if [ $verif_gw -eq 1 ]
			then
				echo
				echo "Il ne s'agit pas d'une adresse de Gateway (--gw) valable"
				exit 1

		fi
fi

## Netmask
if [ -z $NETMASK ]
	then :
	else
		if [ "${NETMASK::1}" != "/" ]
			then 				
				echo
				echo "Il ne s'agit pas d'un Netmask en CIDR (ex : /24)"
				exit 1
		fi
		NETMASK_CIDR=`echo $NETMASK	|cut -d '/' -f2`
		if [[ $NETMASK_CIDR =~ ^[-+]?[0-9]+$  ]]
			then :
			else
				echo
				echo "Il ne s'agit pas d'un Netmask en CIDR (ex : /24)"
				exit 1
		fi
		if [ $NETMASK_CIDR -gt 32 ]
			then 
				echo
				echo "Il ne s'agit pas d'un Netmask en CIDR (ex : /24)"
				exit 1				
			else :

		fi			
		NETMASK_FULL=`cdr2mask $NETMASK_CIDR`
fi

## IPV6


## VLAN
if [ ! -z $DEFAULT_VLAN ]
	then		
		if [[ "${DEFAULT_VLAN}" =~ ^[-+]?[0-9]+$ ]]
			then :	
			else
		    echo
			echo "Il ne s'agit pas d'un numéro de VLAN valable ! (il faut saisir un nombre)"
			exit 1
		fi
		vlan_length=`echo ${#DEFAULT_VLAN}`
		if [ $vlan_length -gt 3 ]
			then
			echo
			echo "Il ne s'agit pas d'un numéro de VLAN valable ! max = 999"
			exit 1
		fi
		:
fi
###############################################################
## Root
if [ -z $ROOT ]
	then :
	else
		try_root=`echo "${ROOT: -1}"`
		if [ "$try_root" == "G" ] || [ "$try_root" == "g" ]
			then :
			else
				echo
				echo "Vous n'avez pas rentré une taille pour / en Giga (G|g)"
				exit 1
		fi
		ROOT_SIZE=`echo $ROOT | sed 's/[g|G]//' `
		re='^[0-9]+$'
		if ! [[ $ROOT_SIZE =~ $re ]]
			then
				echo
				echo "Vous n'avez pas rentré un nombre pour la taille de /"
				exit 1
		fi

		if [ "$ROOT_SIZE" -gt $MAX_ROOT_SIZE ]
			then
				echo
				echo "Vous avez spécifié une taille pour / trop élevée ! (limite "$MAX_ROOT_SIZE"G)"
				exit 1
		fi
		if [ "$ROOT_SIZE" -lt $MIN_ROOT_SIZE ]
			then
				echo
				echo "Vous avez spécifié une taille pour / trop petite ! (limite "$MIN_ROOT_SIZE"G)"
				exit 1
		fi
fi

## Boot
if [ -z $BOOT ]
	then :
	else
		try_boot=`echo "${BOOT: -1}"`
		if [ "$try_boot" == "m" ] || [ "$try_boot" == "M" ]
			then :
			else
				echo
				echo "Vous n'avez pas rentré une taille pour /boot en Méga (m|M)"
				exit 1
		fi
		BOOT_SIZE=`echo $BOOT | sed 's/[m|M]//' `
		re='^[0-9]+$'
		if ! [[ $BOOT_SIZE =~ $re ]]
			then
				echo
				echo "Vous n'avez pas rentré un nombre pour la taille de /boot"
				exit 1
		fi
		if [ "$BOOT_SIZE" -gt $MAX_BOOT_SIZE ]
			then
				echo
				echo "Vous avez spécifié une taille pour /boot trop élevée ! (limite "$MAX_BOOT_SIZE"M)"
				exit 1
		fi
		if [ "$BOOT_SIZE" -lt $MIN_BOOT_SIZE ]
			then
				echo
				echo "Vous avez spécifié une taille pour /boot trop petite ! (limite "$MIN_BOOT_SIZE"M)"
				exit 1
		fi
fi

## Usr
if [ -z $USR ]
	then :
	else
		try_usr=`echo "${USR: -1}"`
		if [ "$try_usr" == "g" ] || [ "$try_usr" == "G" ]
			then :
			else
				echo
				echo "Vous n'avez pas rentré une taille pour /usr en Giga (g|G)"
				exit 1
		fi
		USR_SIZE=`echo $USR | sed 's/[g|G]//' `
		re='^[0-9]+$'
		if ! [[ $USR_SIZE =~ $re ]]
			then
				echo
				echo "Vous n'avez pas rentré un nombre pour la taille de /usr"
				exit 1
		fi
		if [ "$USR_SIZE" -gt $MAX_USR_SIZE ]
			then
				echo
				echo "Vous avez spécifié une taille pour /usr trop élevée ! (limite "$MAX_USR_SIZE"G)"
				exit 1
		fi
		if [ "$USR_SIZE" -lt $MIN_USR_SIZE ]
			then
				echo
				echo "Vous avez spécifié une taille pour /usr trop petite ! (limite "$MIN_USR_SIZE"G)"
				exit 1
		fi
fi

## Var
if [ -z $VAR ]
	then :
	else
		try_var=`echo "${VAR: -1}"`
		if [ "$try_var" == "g" ] || [ "$try_var" == "G" ]
			then :
			else
				echo
				echo "Vous n'avez pas rentré une taille pour /var en Giga (g|G)"
				exit 1
		fi
		VAR_SIZE=`echo $VAR | sed 's/[g|G]//' `
		re='^[0-9]+$'
		if ! [[ $VAR_SIZE =~ $re ]]
			then
				echo
				echo "Vous n'avez pas rentré un nombre pour la taille de /var"
				exit 1
		fi
		if [ "$VAR_SIZE" -gt $MAX_VAR_SIZE ]
			then
				echo
				echo "Vous avez spécifié une taille pour /var trop élevée ! (limite "$MAX_VAR_SIZE"G)"
				exit 1
		fi
		if [ "$VAR_SIZE" -lt $MIN_VAR_SIZE ]
			then
				echo
				echo "Vous avez spécifié une taille pour /var trop petite ! (limite "$MIN_VAR_SIZE"G)"
				exit 1
		fi
fi

## Var/Log
if [ -z $VLOG ]
	then :
	else
		try_vlog=`echo "${VLOG: -1}"`
		if [ "$try_vlog" == "g" ] || [ "$try_vlog" == "G" ]
			then :
			else
				echo
				echo "Vous n'avez pas rentré une taille pour /var/log en Giga (g|G)"
				exit 1
		fi
		VLOG_SIZE=`echo $VLOG | sed 's/[g|G]//' `
		re='^[0-9]+$'
		if ! [[ $VLOG_SIZE =~ $re ]]
			then
				echo
				echo "Vous n'avez pas rentré un nombre pour la taille de /var/log"
				exit 1
		fi
		if [ "$VLOG_SIZE" -gt $MAX_VLOG_SIZE ]
			then
				echo
				echo "Vous avez spécifié une taille pour /var/log trop élevée ! (limite "$MAX_VLOG_SIZE"G)"
				exit 1
		fi
		if [ "$VLOG_SIZE" -lt $MIN_VLOG_SIZE ]
			then
				echo
				echo "Vous avez spécifié une taille pour /var/log trop petite ! (limite "$MIN_VLOG_SIZE"G)"
				exit 1
		fi
fi

## TMP
if [ -z $TMP ]
	then :
	else
		try_tmp=`echo "${TMP: -1}"`
		if [ "$try_tmp" == "m" ] || [ "$try_tmp" == "M" ]
			then :
			else
				echo
				echo "Vous n'avez pas rentré une taille pour /tmp en Méga (m|M)"
				exit 1
		fi
		TMP_SIZE=`echo $TMP | sed 's/[m|M]//' `
		re='^[0-9]+$'
		if ! [[ $TMP_SIZE =~ $re ]]
			then
				echo
				echo "Vous n'avez pas rentré un nombre pour la taille de /tmp"
				exit 1
		fi
		if [ "$TMP_SIZE" -gt $MAX_TMP_SIZE ]
			then
				echo
				echo "Vous avez spécifié une taille pour /tmp trop élevée ! (limite "$MAX_TMP_SIZE"M)"
				exit 1
		fi
		if [ "$TMP_SIZE" -lt $MIN_TMP_SIZE ]
			then
				echo
				echo "Vous avez spécifié une taille pour /tmp trop petite ! (limite "$MIN_TMP_SIZE"M)"
				exit 1
		fi
fi

## SWAP
if [ -z $SWAP ]
	then :
	else
		try_swap=`echo "${SWAP: -1}"`
		if [ "$try_swap" == "g" ] || [ "$try_swap" == "G" ]
			then :
			else
				echo
				echo "Vous n'avez pas rentré une taille de Swap en Giga (g|G)"
				exit 1
		fi
		SWAP_SIZE=`echo $SWAP | sed 's/[g|G]//' `
		re='^[0-9]+$'
		if ! [[ $SWAP_SIZE =~ $re ]]
			then
				echo
				echo "Vous n'avez pas rentré un nombre pour la taille de Swap"
				exit 1
		fi
		if [ "$SWAP_SIZE" -gt $MAX_SWAP_SIZE ]
			then
				echo
				echo "Vous avez spécifié une taille de Swap trop élevée ! (limite "$MAX_SWAP_SIZE"G)"
				exit 1
		fi
		if [ "$SWAP_SIZE" -lt $MIN_SWAP_SIZE ]
			then
				echo
				echo "Vous avez spécifié une taille de Swap trop petite ! (limite "$MIN_SWAP_SIZE"G)"
				exit 1
		fi
fi


###############################################################
## Valeurs par défaut :										 ##
###############################################################

## METHOD (Drbd / Plain)
if [ -z $DISK_METHOD ]
	then DISK_METHOD=drbd
fi


## Nodes
if [ -z $NODES ]
	then NODES="$GNT_MASTER:$GNT_NODE"
	else verif_nodes=`echo $NODES |grep ":" `
		 code_nodes=`echo $?`
         if [ "$code_nodes" == "0" ]
    		then :
    		else 
    			echo
    			echo "Vous avez mal saisi les nodes (hostname1:hostname2)"
    			exit 1
    	fi 
    	NODE1=`echo $NODES |cut -d ':' -f1`
    	NODE2=`echo $NODES |cut -d ':' -f2`
    	if [ -z "$NODE1" ] || [ -z "$NODE2" ]
    		then	echo
    				echo "Vous avez mal saisi les nodes (hostname1:hostname2)"
    				exit 1
    	fi
fi


## Default Disk Size
if [ -z $BOOT ]
	then BOOT=200M
	BOOT_SIZE=200
fi

if [ -z $ROOT ]
	then ROOT=3G
	ROOT_SIZE=3
fi

if [ -z $USR ]
	then USR=2G
	USR_SIZE=2
fi

if [ -z $TMP ]
	then TMP=512M
	TMP_SIZE=512
fi

if [ -z $VAR ]
	then VAR=1G
	VAR_SIZE=1
fi

if [ -z $VLOG ]
	then VLOG=1G
	VLOG_SIZE=1
fi

if [ -z $SWAP ]
	then SWAP=1G
	SWAP_SIZE=1
fi


## Vérification de taille entre les partitions.


num=$(( $ROOT_SIZE + $SWAP_SIZE + $USR_SIZE + $VAR_SIZE + $VLOG_SIZE + 1 ))
# Le +1 correspond à /tmp qui ne peut excéder 1go)


if [ $num -gt $DISK_SIZE ]
	then 
	echo
	echo "La taille de vos partitions est supérieur à la taille du disque." 
	exit 1
fi

## Ecriture OS propre 
if [ "$OS" == "jessie" ]
	then os_clean="Debian"
elif  [ "$OS" == "trusty" ]
	then os_clean="Ubuntu"
else
	echo
	echo "L'OS spécifié est incorrect (\"jessie\" pour Debian et \"trusty\" pour Ubuntu)"
	exit 1
fi

## Debootstrap ou NTLDEB (clonage)
if [ -z $CLONE ]
	then METHOD="debootstrap"
    else METHOD="ntldeb8"
fi

###############################################################
## Récapitulatif											 ##
###############################################################
echo
echo "---------------------------------------------------------"
tput bold
tput setaf 2
echo "Vous allez créer une VM nommée `tput setaf 4`\"$VM_NAME\""
tput sgr0
echo "---------------------------------------------------------"
echo "--- `tput bold`Memory`tput sgr0`   = $RAM"
echo "--- `tput bold`Disk`tput sgr0`     = $DISK"
echo "--- `tput bold`VCPU`tput sgr0`     = $VCPU"
if [ "$CLONE" == "True" ]
	then echo "--- `tput bold`OS`tput sgr0`      = OS from $CLONE_FROM"
else
echo "--- `tput bold`OS`tput sgr0`       = $os_clean"
fi
if  [ -z $NODES ]
	then :
else 
echo "--- `tput bold`Nodes`tput sgr0`    = $NODES"
fi
if  [ -z $CLONE_FROM ]
	then :
else 
echo "--- `tput bold`Clone`tput sgr0`    = $CLONE_FROM"
fi
if  [ -z $ROOT ]
	then :
else 
echo "---------------------------------------------------------"
echo "--- `tput bold`/`tput sgr0`	     = $ROOT"
fi
if  [ -z $BOOT ]
	then :
else 
echo "--- `tput bold`/boot`tput sgr0`    = $BOOT"
fi
if  [ -z $TMP ]
	then :
else 
echo "--- `tput bold`/tmp`tput sgr0`     = $TMP"
fi
if  [ -z $USR ]
	then :
else 
echo "--- `tput bold`/usr`tput sgr0`     = $USR"
fi
if  [ -z $VAR ]
	then :
else 
echo "--- `tput bold`/var`tput sgr0`     = $VAR"
fi
if  [ -z $VLOG ]
	then :
else 
echo "--- `tput bold`/v/log`tput sgr0`   = $VLOG"
fi
if  [ -z $SWAP ]
	then :
else 
echo "--- `tput bold`Swap`tput sgr0`     = $SWAP"
fi
echo "--- `tput bold`Method`tput sgr0`   = $DISK_METHOD"

if  [ -z $IPV4 ]
	then :
else 
echo "---------------------------------------------------------"
echo "--- `tput bold`IPV4`tput sgr0`     = $IPV4"
fi
if  [ -z $GW ]
	then :
else 
echo "--- `tput bold`Gateway`tput sgr0`  = $GW"
fi
if  [ -z $NETMASK ]
	then :
else 
echo "--- `tput bold`Netmask`tput sgr0`  = $NETMASK"
fi

if  [ -z $IPV6 ]
	then :
else 
echo "--- `tput bold`IPV6`tput sgr0`     = $IPV6"
fi
if  [ -z $DEFAULT_VLAN ]
	then :
else 
echo "--- `tput bold`VLAN`tput sgr0`     = $DEFAULT_VLAN"
fi
tput sgr0 
echo "---------------------------------------------------------"
echo

## Confirmation si pas d'argument --no-confirm
if [ "$CONFIRM" = "False" ] 
	then : 
	else
		tput bold; tput setaf 4;
		read -r -p "Lancement de la création ? [o/N] " response
		tput sgr0
		case $response in
    		[oO][eE][sS]|[oO]) 
				echo
        		;;
    		*)
				echo
     		  	tput bold ; tput setaf 1
     		   	echo "Annulation.." ; tput sgr0; echo ; exit 1
    	    	;;
		esac
fi	
tput bold ; tput setaf 2
echo "Création.." ; tput sgr0; echo

# Cela permet de catcher CTRL+C
trap "trap_ctrlc" 2

###############################################################
## Génération du fichier de configuration de la VM  	     ##
###############################################################

if [ -d /srv/ganeti/ ]
	then :
    else 
    	echo
    	echo "Le dossier /srv/ganeti n'existe pas!"
    	exit 1
fi

# Vérification du dossier VMCREATION
if [ -d /srv/ganeti/vmcreation ]
	then :
    else mkdir /srv/ganeti/vmcreation
fi

# Vérification do dossier VMINITLOG
if [ -d /srv/ganeti/vminitlog ]
	then :
    else mkdir /srv/ganeti/vminitlog
fi

cat > /srv/ganeti/vmcreation/$VM_NAME.conf <<EOF
disk;$DISK
boot;$BOOT
root;$ROOT
usr;$USR
var;$VAR
vlog;$VLOG
swap;$SWAP
tmp;$TMP
ipv4;$IPV4
netmask;$NETMASK_FULL
gw;$GW
ipv6;$IPV6
vlan;$DEFAULT_VLAN
method;$METHOD
clonefrom;$CLONE_FROM
EOF

LOG_FILE=/srv/ganeti/vminitlog/$VM_NAME.log


###############################################################
## Lancement des commandes Ganeti							 ##
###############################################################


# Sleep correspond au temps que la VM boot pour faire un update-grub !
SLEEP=40

###############################################################
## Vérification propre à la configuration de Ganeti :        ##
###############################################################

## Config du Cluster :
if [ ! -f /var/lib/ganeti/config.data ]
	then 	echo
			echo "Ganeti ne semble pas installé..."
			echo
			tput bold ; tput setaf 1
		   	echo "Sortie.." ; tput sgr0; echo ; exit 1
			exit 1
fi

## Vérification de la configuration LVM :
lvm_conf=`cat /etc/lvm/lvm.conf |grep drbd`
lvm_code=`echo $?`
if [ "$lvm_code" == "1" ]
	then 	echo
			echo "Le LVM du Master semble mal configuré (filter drbd) !"
			echo
			tput bold ; tput setaf 1
		   	echo "Sortie.." ; tput sgr0; echo ; exit 1
			exit 1
fi

vg_conf=`vgscan |grep $VG_MASTER`
vg_code=`echo $?`
if [ "$vg_code" == "1" ]
	then 	echo
			echo "Le VG $VG_MASTER ne semble pas exister !"
			echo
			tput bold ; tput setaf 1
		   	echo "Sortie.." ; tput sgr0; echo ; exit 1
			exit 1
fi

## Fichier de conf (deboostrap / ntldeb/ variants ...)
if [ ! -f /usr/share/ganeti/os/debootstrap/create ]
	then 	echo
			echo "La configuration de Ganeti (debootstrap) semble incorrecte..."
			echo
			tput bold ; tput setaf 1
		   	echo "Sortie.." ; tput sgr0; echo ; exit 1
			exit 1
fi
if [ ! -f /etc/ganeti/instance-debootstrap/variants/jessie.conf ]
	then 	echo
			echo "La configuration de Debootstrap pour Jessie semble incorrecte..."
			echo
			tput bold ; tput setaf 1
		   	echo "Sortie.." ; tput sgr0; echo ; exit 1
			exit 1
fi
if [ ! -f /etc/ganeti/instance-debootstrap/variants/trusty.conf ]
	then 	echo
			echo "La configuration de Debootstrap pour Trusty semble incorrecte..."
			echo
			tput bold ; tput setaf 1
		   	echo "Sortie.." ; tput sgr0; echo ; exit 1
			exit 1
fi
if [ ! -f /usr/share/ganeti/os/ntldeb8/create ]
	then 	echo
			echo "La configuration de Ganeti (ntldeb8) semble incorrecte..."
			echo
			tput bold ; tput setaf 1
		   	echo "Sortie.." ; tput sgr0; echo ; exit 1
			exit 1
fi

## On vérifie la compatibilité des nodes 
if [ "$DISK_METHOD" == "plain" ]
	then 
		verif_node1=`gnt-node info $NODE1 |grep "master_capable: True"`
		verif_node1_code=`echo $?`
		if [ "$verif_node1_code" == "0" ]
			then :
			else 	echo
    				echo "Le node $NODE1 semble incapable de recevoir la VM $VM_NAME"
    				echo
					tput bold ; tput setaf 1
		   			echo "Sortie.." ; tput sgr0; echo ; exit 1
    				exit 1
    	fi
    else
    	verif_node1=`gnt-node info $NODE1 |grep "master_capable: True"`
		verif_node1_code=`echo $?`
		if [ "$verif_node1_code" == "0" ]
			then :
			else 	echo
    				echo "Le node $NODE1 semble incapable de recevoir la VM $VM_NAME"
    				echo
					tput bold ; tput setaf 1
		   			echo "Sortie.." ; tput sgr0; echo ; exit 1
    				exit 1
    	fi
    	verif_node2=`gnt-node info $NODE2 |grep "master_capable: True"`
		verif_node2_code=`echo $?`
		if [ "$verif_node2_code" == "0" ]
			then :
			else 	echo
    				echo "Le node $NODE2 semble incapable de recevoir la VM $VM_NAME"
    				echo
					tput bold ; tput setaf 1
		   			echo "Sortie.." ; tput sgr0; echo ; exit 1
    				exit 1
    	fi
fi
###############################################################
## Debootstrap
###############################################################

if [ "$METHOD" == "debootstrap" ]
then
	tput bold; echo "Copie du fichier de conf ..." ; tput sgr0 
	echo
	echo "/srv/ganeti/vmcreation/$VM_NAME.conf"
	gnt-cluster copyfile /srv/ganeti/vmcreation/$VM_NAME.conf |tee $LOG_FILE
	echo
	tput bold; echo "Création de la VM ..." ; tput sgr0
	echo
	gnt-instance add -t $DISK_METHOD --disk 0:size=$DISK --disk 1:size=$BOOT -B memory=$RAM,vcpus=$VCPU -o $METHOD+$OS -n $NODES --no-ip-check --no-name-check --no-start $VM_NAME |tee -a $LOG_FILE
	echo

	## Vérification de la bonne création de la VM, sinon on quitte !
	is_deboot_error=`cat /srv/ganeti/vminitlog/$VM_NAME.log |grep Failure: `
	is_deboot_error_code=`echo $?`
	if [ "$is_deboot_error_code" == "1" ]
	then
		tput bold; echo "Modification du root_path ..."  ; tput sgr0 
		echo  
		gnt-instance modify --hypervisor-parameters=root_path=/dev/vg$VM_NAME/racine $VM_NAME |tee -a $LOG_FILE
		echo
		tput bold; echo "Mis à jours de Grub ..."  ; tput sgr0 
		echo 
		gnt-instance start $VM_NAME |tee -a $LOG_FILE
		echo
		sleep $SLEEP
		tput bold; echo "Modification du kernel_path ..." ; tput sgr0
		echo
		gnt-instance modify --hypervisor-parameters=kernel_path=/usr/lib/grub-xen/grub-x86_64-xen.bin $VM_NAME |tee -a $LOG_FILE
		echo
		tput bold; echo "Reboot de la VM ..."  ; tput sgr0
		echo
		gnt-instance reboot $VM_NAME |tee -a $LOG_FILE
	else
		echo	
		tput bold ; tput setaf 1 
		echo "La VM $VM_NAME semble avoir un problème de création !" |tee -a $LOG_FILE
		tput sgr0
		echo "Le fichier de log est $LOG_FILE"
		echo
	fi
else :
fi

###############################################################
## NtlDEB (Clonage)
###############################################################

if [ "$METHOD" == "ntldeb8" ]
then	

	tput bold; echo "Vérification de la VM à cloner ..." ; tput sgr0 
	echo

	## Vérification clonage sur la même nodes :
	CLONE_FROM_NODE=`gnt-instance info $CLONE_FROM |grep "primary:" |grep -v "on" |cut -d ':' -f2 |cut -d ' ' -f2`
	NODES_FIRST=`echo $NODES |cut -d ':' -f1`

	if [ "$CLONE_FROM_NODE" != "$NODES_FIRST" ]
		then
			echo
			echo "La VM à cloner n'est pas sur le même node ($CLONE_FROM_NODE) !"
			echo
			tput bold ; tput setaf 1
		   	echo "Sortie.." ; tput sgr0; echo ; exit 1
			exit 1
	fi
 
	## Comparaison de la taille des disque entre les vm :
	if [ "$CONFIRM" == "False" ]
		then :
		else
			CLONE_FROM_DISK=`gnt-instance info $CLONE_FROM  |grep disk/0 |cut -d 'e' -f2 |cut -d ' ' -f2 |cut -d '.' -f1 `
			if [ $CLONE_FROM_DISK -gt $DISK_SIZE ]
				then 
					echo
					echo "Le disque de la VM à cloner est supérieur à la nouvelle VM !"
					echo
					tput bold ; tput setaf 1
		     		echo "Sortie.." ; tput sgr0; echo ; exit 1
					exit 1
			fi

			if [ -f /srv/ganeti/vmcreation/$CLONE_FROM.conf ]
				then
					root_clone=`cat /srv/ganeti/vmcreation/$CLONE_FROM.conf |grep "root" |cut -d ';' -f2 | sed 's/[g|G]//'`
					swap_clone=`cat /srv/ganeti/vmcreation/$CLONE_FROM.conf |grep "swap" |cut -d ';' -f2 | sed 's/[g|G]//'`
					usr_clone=`cat /srv/ganeti/vmcreation/$CLONE_FROM.conf |grep "usr" |cut -d ';' -f2 | sed 's/[g|G]//'`
					var_clone=`cat /srv/ganeti/vmcreation/$CLONE_FROM.conf |grep "var" |cut -d ';' -f2 | sed 's/[g|G]//'`
					vlog_clone=`cat /srv/ganeti/vmcreation/$CLONE_FROM.conf |grep "vlog" |cut -d ';' -f2 | sed 's/[g|G]//'`
					if [ $root_clone -gt $ROOT_SIZE ]
					then 
					echo
					echo "Le / de la VM à cloner est supérieur au / de la nouvelle VM ("$root_clone"G) !"
					echo
					tput bold ; tput setaf 1
		     		echo "Sortie.." ; tput sgr0; echo ; exit 1
					exit 1
					fi
					if [ $swap_clone -gt $SWAP_SIZE ]
					then 
					echo
					echo "Le Swap de la VM à cloner est supérieur au Swap de la nouvelle VM ("$swap_clone"G) !"
					echo
					tput bold ; tput setaf 1
		     		echo "Sortie.." ; tput sgr0; echo ; exit 1
					exit 1
					fi
					if [ $usr_clone -gt $USR_SIZE ]
					then 
					echo
					echo "Le /usr de la VM à cloner est supérieur au /usr de la nouvelle VM ("$usr_clone"G) !"
					echo
					tput bold ; tput setaf 1
		     		echo "Sortie.." ; tput sgr0; echo ; exit 1
					exit 1
					fi
					if [ $var_clone -gt $VAR_SIZE ]
					then 
					echo
					echo "Le /var de la VM à cloner est supérieur au /var de la nouvelle VM  ("$var_clone"G)!"
					echo
					tput bold ; tput setaf 1
		     		echo "Sortie.." ; tput sgr0; echo ; exit 1
					exit 1
					fi
					if [ $vlog_clone -gt $VLOG_SIZE ]
					then 
					echo
					echo "Le /var/log de la VM à cloner est supérieur au /var/log de la nouvelle VM ("$vlog_clone"G) !"
					echo
					tput bold ; tput setaf 1
		     		echo "Sortie.." ; tput sgr0; echo ; exit 1
					exit 1
					fi
			fi
	fi
	## la VM est elle allumé ?
	clone_watch=`gnt-instance list |grep "$CLONE_FROM" |grep running`
	clone_status=`echo $?`
	if [ "$clone_status" == "0" ]
		then clone_status_verbose="running"
	fi
	clone_watch=`gnt-instance list |grep "$CLONE_FROM" |grep down`
	clone_status=`echo $?`
	if [ "$clone_status" == "0" ]
		then clone_status_verbose="down"
	fi
	# Vérification de l'état
	if [ "$clone_status_verbose" == "running" ]

		then echo "La VM que vous voulez cloner est allumée !"

			if [ "$CONFIRM" == "False" ]
			then echo ; tput bold; echo "Extinction de la VM à cloner ..." ; echo ;tput sgr0
				gnt-instance stop $CLONE_FROM
				CLONE_REUP=True
			else
					tput bold; tput setaf 4;
					echo
			 		read -r -p "Voulez-vous éteindre la VM $CLONE_FROM ? [o/N] " response
			 		tput sgr0
					case $response in
	    				[oO][eE][sS]|[oO]) 
							echo
							tput bold; echo "Extinction de la VM à cloner ..." ; tput sgr0
							echo
							gnt-instance stop $CLONE_FROM
							echo "La VM à éteindre est correctement éteinte."
	        				;;
	    				*)
							echo
	     		  			tput bold ; tput setaf 1
	     		   			echo "Annulation.." ; tput sgr0; echo ; exit 1
	    	    			;;
					esac
			fi
	fi
	if [ "$clone_status_verbose" == "down" ]
		then echo "La VM que vous souhaitez cloner est correctement stoppée."
		     CLONE_REUP=False
	fi
	echo
	tput bold; echo "Copie du fichier de conf ..." ; tput sgr0 
	echo
	echo "/srv/ganeti/vmcreation/$VM_NAME.conf"
	gnt-cluster copyfile /srv/ganeti/vmcreation/$VM_NAME.conf |tee $LOG_FILE
	echo
	tput bold; echo "Création de la VM ..." ; tput sgr0
	echo
	gnt-instance add -t $DISK_METHOD --disk 0:size=$DISK --disk 1:size=$BOOT -B memory=$RAM,vcpus=$VCPU -o $METHOD+$OS -n $NODES --no-ip-check --no-name-check --no-start $VM_NAME ; echo $? |tee -a $LOG_FILE
	echo
	# Vérification de bonne création de la VM :
	is_ntldeb_error=`cat /srv/ganeti/vminitlog/$VM_NAME.log |grep Failure: `
	is_ntldeb_error_code=`echo $?`
	if [ "$is_ntldeb_error_code" == "1" ]
		then 
			tput bold; echo "Modification du root_path ..."  ; tput sgr0 
			echo  
			gnt-instance modify --hypervisor-parameters=root_path=/dev/vg$VM_NAME/racine $VM_NAME |tee -a $LOG_FILE
			echo
			tput bold; echo "Modification du kernel_path ..." ; tput sgr0
			echo
			gnt-instance modify --hypervisor-parameters=kernel_path=/usr/lib/grub-xen/grub-x86_64-xen.bin $VM_NAME |tee -a $LOG_FILE
			echo
			tput bold; echo "Mis à jours de Grub ..."  ; tput sgr0 
			echo 
			gnt-instance start $VM_NAME |tee -a $LOG_FILE
			echo
			sleep $SLEEP
			tput bold; echo "Reboot de la VM ..."  ; tput sgr0
			echo
			gnt-instance reboot $VM_NAME |tee -a $LOG_FILE

			# Relance de la VM cloné
			if [ "$CLONE_REUP" == "True" ]  && [ "$CONFIRM" == "False" ]
			then 
				echo
				tput bold; echo "Allumage de la VM clonée ..." ; tput sgr0
				echo
				gnt-instance start $CLONE_FROM |tee -a $LOG_FILE
			else 
				if [ -z $CONFIRM ]
				then
					tput bold; tput setaf 4;
					echo
				 	read -r -p "Voulez-vous rallumer la VM $CLONE_FROM ? [o/N] " response
				 	tput sgr0
					case $response in
			    		[oO][eE][sS]|[oO]) 
							echo
							tput bold; echo "Allumage de la VM à cloner ..." ; tput sgr0
							echo
							gnt-instance start $CLONE_FROM
							echo "La VM à allumer est correctement allumée."
							echo
			        		;;
			    		*)
							echo
			     			tput bold ; tput setaf 1
			     			echo "La VM $CLONE_FROM reste éteinte.." ; tput sgr0 ; echo 
			    	    	;;
					esac
				else
					echo
			     	tput bold ; tput setaf 1
			     	echo "La VM $CLONE_FROM reste éteinte.. (--no-confirm)" ; tput sgr0 ; echo 
				fi
			fi	
		else
			echo	
			tput bold ; tput setaf 1 
			echo "La VM $VM_NAME semble avoir un problème de création !" |tee -a $LOG_FILE
			tput sgr0
			echo "Le fichier de log est $LOG_FILE"
			echo
	fi

fi

###############################################################
## Ouverture de console ?									 ##
###############################################################

echo
if  [ "$CONFIRM" == "False" ]
	then : 
    else
    	tput bold; tput setaf 4;
    	read -r -p "Voulez-vous ouvrir la console ? [o/N] " response
		tput sgr0
		case $response in
    		[oO][eE][sS]|[oO]) 
				echo
				gnt-instance console $VM_NAME
        		;;
    		*)
				echo
    	    	;;
		esac
fi

###############################################################
## Last verification										 ##
###############################################################

VM_CREATION=`cat $LOG_FILE |grep "Failure"`
VERIF_VM_CREATION=`echo $?`
if [ "$VERIF_VM_CREATION" == "1" ]
	then
		echo	
		tput bold ; tput setaf 2 
		echo "La VM $VM_NAME est correctement créée !" |tee -a $LOG_FILE
		tput sgr0
		echo
	else 
		echo	
		tput bold ; tput setaf 1 
		echo "La VM $VM_NAME semble avoir un problème de création !" |tee -a $LOG_FILE
		tput sgr0
		echo "Le fichier de log est $LOG_FILE"
		echo
fi
exit 0
