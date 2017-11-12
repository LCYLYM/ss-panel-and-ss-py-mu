#!/bin/bash

Install_the_front(){
	bash /root/node/front_end.sh
}

Shut_down_iptables(){
	yum -y install iptables iptables-services
	iptables -F;iptables -X
	iptables -I INPUT -p tcp -m tcp --dport 22:65535 -j ACCEPT
	iptables -I INPUT -p udp -m udp --dport 22:65535 -j ACCEPT
	iptables-save > /etc/sysconfig/iptables
	echo 'iptables-restore /etc/sysconfig/iptables' >> /etc/rc.local
}

Shut_down_firewall(){
	yum -y install firewalld;firewall_state=`firewall-cmd --state`
	if [ ${firewall_state} = 'running' ];then
		systemctl stop firewalld.service
		systemctl mask firewalld
		systemctl disable firewalld.service
	fi
}

Unfile_number_limit(){
	echo "root soft nofile 65535
root hard nofile 65535" >> /etc/security/limits.conf
	echo "session required pam_limits.so" >> /etc/pam.d/login
}

Add_swap_partition(){
	Memory_size=`cat /proc/meminfo | grep MemTotal | grep -E -o "[1-9][0-9]{4,}"`
	Swap_size=`expr ${Memory_size} \* 2`
	
	dd if=/dev/zero of=/var/swap bs=1024 count=${Swap_size}
	mkswap /var/swap;swapon /var/swap;free -m
	echo '/var/swap swap swap default 0 0' >> /etc/fstab
}

Install_BBR(){
	bash /root/tools/bbr.sh
}

Check_BBR_installation_status(){
	echo "[↓]查看内核版本,含有4.12或更高即可."
	uname -r;echo
	echo "[↓]返回：net.ipv4.tcp_available_congestion_control = bbr cubic reno 即可."
	sysctl net.ipv4.tcp_available_congestion_control;echo
	echo "[↓]返回：net.ipv4.tcp_congestion_control = bbr 即可."
	sysctl net.ipv4.tcp_congestion_control;echo
	echo "[↓]返回：net.core.default_qdisc = fq 即可."
	sysctl net.core.default_qdisc;echo
	echo "[↓]返回值有 tcp_bbr 模块即说明bbr已启动."
	lsmod | grep bbr
}

Install_fail2ban(){
	if [ ! -f /etc/fail2ban/jail.local ];then
		echo "检测到未安装fail2ban,将先进行安装...";sleep 2.5
		bash /root/tools/fail2ban.sh
	else
		fail2ban-client ping;echo -e "\033[31m[↑]正常返回值:Server replied: pong\033[0m"
		#iptables --list -n;echo -e "\033[31m#当前iptables禁止规则\033[0m"
		fail2ban-client status;echo -e "\033[31m[↑]当前封禁列表\033[0m"
		fail2ban-client status ssh-iptables;echo -e "\033[31m[↑]当前被封禁的IP列表\033[0m"
		sed -n '12,14p' /etc/fail2ban/jail.local;echo -e "\033[31m[↑]当前fail2ban配置\033[0m"
	fi
}

Install_Safe_Dog(){
	bash /root/tools/safe_dog.sh
}

Install_Serverspeeder(){
	read -p "请选择选项 [1]安装 [2]卸载 :" Install_Serverspeeder_Options
	
	case "${Install_Serverspeeder_Options}" in
		1)
		wget -N --no-check-certificate "https://github.com/91yun/serverspeeder/raw/master/serverspeeder.sh"
		bash serverspeeder.sh;;
		2)
		chattr -i /serverspeeder/etc/apx*
		/serverspeeder/bin/serverSpeeder.sh uninstall -f;;
		*)
		echo "选项不在范围!";exit 0;;
	esac
}

delete_file(){
	rm -rf /root/*.cfg /root/*.log /root/*.gz
}

Uninstall_ali_cloud_shield(){
	echo "请根据阿里云系统镜像安装环境,选项相应选项!"
	echo "选项: [1]系统自控制台重装 [2]系统自快照/镜像恢复 [3]更换内核并安装LotServer"
	read -p "请选择选项:" Uninstall_ali_cloud_shield_options
	
	case "${Uninstall_ali_cloud_shield_options}" in
		1)
		bash /root/alibabacloud/New_installation.sh;;
		2)
		bash /root/alibabacloud/Snapshot_image.sh;;
		3)
		bash /root/alibabacloud/install.sh;;
		*)
		echo "选项不在范围!";exit 0;;
	esac
}

Change_System_Source(){
	bash /root/tools/change_source.sh
}

Routing_track(){
	bash /root/tools/traceroute.sh
}

Run_Speedtest_And_Bench_sh(){
	speedtest(){
		if [ ! -f /root/speedtest.py ];then
			wget "https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py"
			chmod 777 speedtest.py
		fi
		./speedtest.py
	}
	
	bench_sh(){
		echo;read -p "执行bench.sh[y],还是退出[n]:" Execution_or_exit
		case "${Execution_or_exit}" in
			y)
			wget -qO- bench.sh | bash;;
			n)
			exit 0;;
			*)
			echo "选项不在范围!";exit 0;;
		esac
		
	}
	
	speedtest
	bench_sh
}

Install_ss_node(){
	Setup_time=`date +"%Y-%m-%d %H:%M:%S"`;Install_the_start_time_stamp=`date +%s`
	system_os=`bash /root/tools/check_os.sh`
	
	case "${system_os}" in
		centos)
		bash /root/node/centos.sh;;
		debian)
		bash /root/node/debian.sh;;
		*)
		echo "系统不受支持!请更换Centos/Debian镜像后重试!";exit 0;;
	esac
	
	Unfile_number_limit
	Add_swap_partition
	Shut_down_iptables
	Shut_down_firewall
	Install_fail2ban
	delete_file
	
	Installation_end_time=`date +"%Y-%m-%d %H:%M:%S"`;Install_end_time_stamp=`date +%s`
	The_installation_time=`expr ${Install_end_time_stamp} - ${Install_the_start_time_stamp}`
	clear;echo "安装开始时间:[${Setup_time}],安装结束时间:[${Installation_end_time}],耗时[${The_installation_time}]s."
	echo "安装已完成.但ssr服务尚未启动,请通过[shadowsocks]命令管理服务."
}

Edit_ss_node_info(){
	echo "旧设置如下:"
	sed -n '2p' /root/shadowsocks/userapiconfig.py
	sed -n '17,18p' /root/shadowsocks/userapiconfig.py
	
	echo;read -p "(1/3)请设置新的前端地址:" Front_end_address
	read -p "(2/3)请设置新的节点ID:" Node_ID
	read -p "(3/3)请设置新的Mukey:" Mukey
	
	if [[ ${Mukey} = '' ]];then
		Mukey='mupass';echo "emm,我们已将Mukey设置为:mupass"
	fi
	
	sed -i "17c WEBAPI_URL = \'${Front_end_address}\'" /root/shadowsocks/userapiconfig.py
	sed -i "2c NODE_ID = ${Node_ID}" /root/shadowsocks/userapiconfig.py
	sed -i "18c WEBAPI_TOKEN = \'${Mukey}\'" /root/shadowsocks/userapiconfig.py
	
	bash /root/shadowsocks/stop.sh
	bash /root/shadowsocks/run.sh
	echo "新设置已生效."
}

Nginx_Administration_Script(){
	wget "https://raw.githubusercontent.com/qinghuas/Nginx-administration-script/master/nginx.sh";bash nginx.sh
}

About_This_Shell_Script(){
	cat /root/tools/about.txt
}

Update_Shell_Script(){
	wget -O /usr/bin/ssr "https://file.52ll.win/ssr.sh";chmod 777 /usr/bin/ssr;ssr
}

echo "####################################################################
# GitHub  #  https://github.com/mmmwhy/ss-panel-and-ss-py-mu       #
# GitHub  #  https://github.com/qinghuas/ss-panel-and-ss-py-mu     #
# Edition #  V.3.0 2017-11-12                                      #
# From    #  @mmmwhy @qinghuas                                     #
####################################################################
# [ID]  [TYPE]  # [DESCRIBE]                                       #
####################################################################
# [1] [INSTALL] # [LNMP] AND [SS PANEL V3]                         #
# [2] [INSTALL] # [SS NODE] AND [BBR]                              #
# [3] [CHANGE]  # [SS NODE INOF]                                   #
# [4] [INSTALL] # [SS NODE]                                        #
# [5] [INSTALL] # [BBR]                                            #
####################################################################
# [a] [HELP]    # Check BBR Installation Status                    #
# [b] [TOOLS]   # Install / Run Routing Tracing                    #
# [c] [TOOLS]   # Run Speedtest And Bench.sh                       #
# [d] [CHANGE]  # Change System Source                             #
# [e] [INSTALL] # Install Fail2ban / Check Fail2ban Status         #
# [f] [INSTALL] # Install Safe Dog                                 #
# [g] [UNINSTALL] # Uninstall Ali Cloud Shield                     #
# [h] [INSTALL] # Install / UNINSTALL Serverspeeder                #
# [i] [TOOLS]   # Nginx Administration Script                      #
# [about]       # About This Shell Script                          #
####################################################################
# [x] REFRESH [y] UPDATE [z] EXIT                                  #
####################################################################"
read -p "Please select options:" SSR_OPTIONS

clear;case "${SSR_OPTIONS}" in
	1)
	Install_the_front;;
	2)
	Install_ss_node
	Install_BBR;;
	3)
	Edit_ss_node_info;;
	4)
	Install_ss_node;;
	5)
	Install_BBR;;
	a)
	Check_BBR_installation_status;;
	b)
	Routing_track;;
	c)
	Run_Speedtest_And_Bench_sh;;
	d)
	Change_System_Source;;
	e)
	Install_fail2ban;;
	f)
	Install_Safe_Dog;;
	g)
	Uninstall_ali_cloud_shield;;
	h)
	Install_Serverspeeder;;
	i)
	Nginx_Administration_Script;;
	x)
	/usr/bin/ssr;;
	y)
	Update_Shell_Script;;
	z)
	about)
	About_This_Shell_Script;;
	*)
	echo "选项不在范围!";exit 0;;
esac