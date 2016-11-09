#!/bin/bash

MKIP=$1
BASEURL="$MKIP/mk_agents"
XINEDMKFILE=/etc/xinetd.d/check_mk
XINEDMKFILEREMOTE=xined_check_mk_config
USERWEB=agents
PASSWEB=4g3nt5
GIT=https://raw.githubusercontent.com/lplinux/scripts/master

function pfsense22() {
        
        DISTRO=pfsense22
        FILE=check_mk_agent_pfsense22_sh
        
        echo -e "inetd_enable=\"YES\"\ninetd_flags=\"-wW\"" >> /etc/rc.conf.local
        echo "check_mk        6556/tcp   #check_mk agent" >> /etc/services
        echo "check_mk        stream  tcp     nowait          root    /usr/local/bin/check_mk_agent check_mk" >> /etc/inetd.conf
        echo -e "# Allow nagios server to access us\ncheck_mk_agent : $MKIP : allow\ncheck_mk_agent : ALL : deny" >> /etc/hosts.allow
        echo -e "#\!/bin/sh\n#\n# $FreeBSD$\n#\n\n# PROVIDE: inetd\n# REQUIRE: DAEMON LOGIN cleanvar\n# KEYWORD: shutdown\n\n. /etc/rc.subr\n\nname=\"inetd\"\nrcvar=\"inetd_enable\"\ncommand=\"/usr/sbin/${name}\"\npidfile=\"/var/run/${name}.pid\"\nrequired_files=\"/etc/${name}.conf\"\nextra_commands=\"reload\"\n\nload_rc_config $name\nrun_rc_command \"$1\"" >> /etc/rc.d/inetd

        chmod +x /etc/rc.d/inetd
        fetch -q $GIT/$FILE -o /usr/local/bin/check_mk_agent
        chmod +x /usr/local/bin/check_mk_agent
        
        service inetd restart

}

function debianf() {

        DISTRO=Debian
        FILE=check-mk-agent_latest.deb

        wget -P /tmp/ http://$USERWEB:$PASSWEB@$BASEURL/$FILE
        apt-get install -y xinetd

        if [ `dpkg -l | grep xinetd | wc -l ` -eq 1 ];
        then   

                if [ -f /tmp/$FILE ];
                then   
                        dpkg -i /tmp/$FILE
                else   
                        echo "The .deb file is not in the /tmp directory"
                        exit
                fi

                if [ `dpkg -l | grep check-mk-agent | wc -l ` -eq 1 ];
                then   
                        if [ -f $XINEDMKFILE ];
                        then   
                                sed -i.bak "s/#only_from      = 127.0.0.1 10.0.20.1 10.0.20.2/only_from = $MKIP/g" $XINEDMKFILE
                        else   
                                wget -P /tmp/ http://$USERWEB:$PASSWEB@$BASEURL/$XINEDMKFILEREMOTE
                                mv /tmp/$XINEDMKFILEREMOTE $XINEDMKFILE
                                sed -i.bak "s/#only_from      = 127.0.0.1 10.0.20.1 10.0.20.2/only_from = $MKIP/g" $XINEDMKFILE
                        fi
                fi

                /etc/init.d/xinetd restart
        else   
                echo "Error al instalar Xined."
                exit
        fi


}

function redhatf() {

        DISTRO=RedHat
        FILE=check-mk-agent-latest.rpm

        wget -P /tmp/ http://$USERWEB:$PASSWEB@$BASEURL/$FILE
        yum install -y xinetd

        if [ `yum list installed |grep xinetd | wc -l` -eq 1 ];
        then   

                if [ -f /tmp/$FILE ];
                then   
                        rpm -Uvh /tmp/$FILE
                else   
                        echo "The .rpm file is not in the /tmp directory"
                        exit
                fi

                if [ `yum list installed |grep check-mk-agent | wc -l` -eq 1 ];
                then
                        if [ -f $XINEDMKFILE ];
                        then
                                sed -i.bak "s/#only_from      = 127.0.0.1 10.0.20.1 10.0.20.2/only_from = $MKIP/g" $XINEDMKFILE
                        else
                                wget -P /tmp/ http://$USERWEB:$PASSWEB@$BASEURL/$XINEDMKFILEREMOTE
                                mv /tmp/$XINEDMKFILEREMOTE $XINEDMKFILE
                                sed -i.bak "s/#only_from      = 127.0.0.1 10.0.20.1 10.0.20.2/only_from = $MKIP/g" $XINEDMKFILE
                        fi
                fi

                /etc/init.d/xinetd restart
        else
                echo "Error al instalar Xined."
                exit

        fi


}



if [ -f /etc/debian_version ]; then
        debianf
elif [ -f /etc/redhat-release ]; then
        redhatf
elif [ -f /etc/version ]; then
        if [ `cat /etc/version | cut -d '.' -f 1,2` == "2.2" ]; then
            pfsense22
        fi
elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        DISTRO=$DISTRIB_ID
        if [[ $DISTRO == "Ubuntu" ]]; then
                debianf
        fi
else   
        DISTRO=$(uname -s)
fi
