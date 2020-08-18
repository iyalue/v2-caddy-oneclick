#!/bin/bash
port1="80"
//端口port2为连接端口，可更改
port2="443"


alterId="64"
#随机生成websocket端口
let port3=$RANDOM+10000


#判断是否正确执行
judge(){
	if [[ $? -eq 0 ]];then
		echo "$1 sucess!"
		sleep 1
	else
		echo "$1fail"
		exit 1
	fi
}


#install v2ray using official script
v2ray_install(){
	bash <(curl -L -s https://install.direct/go.sh)
	judge "安装v2ray"
}


#设定域名,path
domain_set(){
	echo "请输入你的域名，并正确解析"
	read -e -p "请输入：" domain
	[[ -z ${domain} ]] && domain="none"
	if [ "${domain}" = "none" ];then
		domin_set
	else
		echo "你设置的域名为: ${domain}"
		cat <<EOF >domain.txt
${domain}
EOF
	v2ray_path=`cat /dev/urandom | head -n 10 | md5sum | head -c 8`
	touch v2ray_path.txt
	cat <<EOF >v2ray_path.txt
${v2ray_path}
	fi
}


#安装caddy，仅支持debian
caddy_install(){
	curl -L -o caddy.deb https://github.com/caddyserver/caddy/releases/download/v2.1.1/caddy_2.1.1_linux_amd64.deb
	judge "安装caddy"
}


# 生成caddy配置文件
caddy_conf_add(){
	if [ -e /etc/caddy/Caddyfile ];then
	cat <<EOF >/etc/caddy/Caddyfile
${domain} {
    log {
        output file /etc/caddy/caddy.log
    }
    tls {
        protocols tls1.2 tls1.3
        ciphers TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256
        curves x25519
    }
    @v2ray_websocket {
        path ${v2ray_path}
        header Connection *Upgrade*
        header Upgrade websocket
    }
    reverse_proxy @v2ray_websocket localhost:${port3}
}
EOF
	judge "caddy配置"
else
    echo "there is no this file"
    exit 1
fi	
}


#生成v2ray配置文件
v2ray_conf_add(){
	if [ -e /etc/v2ray/config.json ];then
		cp /etc/v2ray/config.json /etc/v2ray/config.json.bakup
		UUID=$(cat /proc/sys/kernel/random/uuid)
		cat <<EOF >/etc/v2ray/config.json
{
  "inbounds": [
    {
      "port": ${port3},
      "listen":"127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${UUID}",
            "alterId":${alterId} 
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
        "path": "${v2ray_path}"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF
	judge "添加v2ray配置"
else
	echo "请检查v2ray安装"
	exit 1
fi
}


#程序执行过程
main(){
	domian_set
	v2ray_install
	caddy_install
	v2ray_conf_add
	caddy_conf_add
}

main
