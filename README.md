# OpenVPN-
OpenVPN 配置教程

### 1. 安装必要软件
```bash
opkg update
opkg install openvpn-openssl openvpn-easy-rsa
```

### 2. 生成证书和密钥
```bash
cd /etc/easy-rsa
easyrsa init-pki
easyrsa build-ca nopass
easyrsa gen-dh
easyrsa build-server-full server nopass

```

证书/密钥文件会生成在 `pki` 目录下：
- CA: `pki/ca.crt`
- 服务端: `pki/issued/server.crt`, `pki/private/server.key`
- 客户端: `pki/issued/client1.crt`, `pki/private/client1.key`
- DH 参数: `pki/dh.pem`
- CRL: `pki/crl.pem`
将证书和密钥复制到 OpenVPN 目录下：
```
cp /etc/easy-rsa/pki/issued/server.crt /etc/openvpn/

cp /etc/easy-rsa/pki/private/server.key /etc/openvpn/

cp /etc/easy-rsa/pki/dh.pem /etc/openvpn/

cp /etc/easy-rsa/pki/ca.crt /etc/openvpn/
```

如果用的是 openvpn 服务器，将客户端证书和密钥复制到 openvpn目录下就可以一键下载配置：
```
cp pki/issued/client1.crt /etc/openvpn/

cp pki/private/client1.key /etc/openvpn/
```
### 3. 配置 OpenVPN 服务端
注意：将以下带有*号项目改成你自己的配置

###如果不配置ccd目录
请在以上配置文件中添加
```
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 114.114.114.114（或路由器 DNS 服务地址）"
```
或
```
iroute 192.168.*.0 255.255.255.0
```
编辑 `/etc/config/openvpn`：
```conf

config openvpn 'myvpn'
        option port '1194'
        option dev 'tun'
        option topology 'subnet'
        option server '10.8.0.0 255.255.255.0'
        option comp_lzo 'no'
        option ca '/etc/openvpn/ca.crt'
        option dh '/etc/openvpn/dh.pem'
        option key '/etc/openvpn/server.key'
        option cert '/etc/openvpn/server.crt'
        option persist_key '1'
        option persist_tun '1'
        option user 'nobody'
        option group 'nogroup'
        option max_clients '10'
        option keepalive '10 120'
        option verb '3'
        option status '/var/log/openvpn_status.log'
        option log '/tmp/openvpn.log'
        option duplicate_cn '1'
        option proto 'tcp-server'
        option enabled '1'
        option client_config_dir '/etc/openvpn/ccd'
        list push 'route 192.168.*.0 255.255.255.0'
```




 4. 配置 CCD 以下配置了解后再配置
```bash
mkdir -p /etc/openvpn/ccd
echo "ifconfig-push 10.8.0.10 255.255.255.0" > /etc/openvpn/ccd/client1
```
#全局走vpn
```
push "redirect-gateway def1 bypass-dhcp"
```
#DNS推送
```
push "dhcp-option DNS 192.168.6.1"
```
#指定路由
```
iroute 192.168.6.0 255.255.255.0
push "route 192.168.6.0 255.255.255.0
```
#指定网关
```
push "route 192.168.6.0 255.255.255.0 192.168.6.1"
```
###以下是我的 ccd配置
/etc/openvpn/ccd/clientMobile:
```

ifconfig-push 10.8.0.10 255.255.255.0

# 推送两边内网
iroute 192.168.6.0 255.255.255.0
iroute 192.168.2.0 255.255.255.0

# 全局走 VPN
push "redirect-gateway def1 bypass-dhcp"

# 推送 DNS
push "dhcp-option DNS 192.168.6.1"
```

/etc/openvpn/ccd/clientB
```
ifconfig-push 10.8.0.2 255.255.255.0
iroute 192.168.2.0 255.255.255.0
```



## 三、CCD 配置选项速查表

CCD（Client Config Directory）用于为不同客户端设置专属配置，文件名需与客户端证书的 **Common Name (CN)** 一致。

### 常用指令

| 指令 | 示例 | 说明 |
|------|------|------|
| ifconfig-push | `ifconfig-push 10.8.0.10 255.255.255.0` | 给客户端分配固定 IP |
| iroute | `iroute 192.168.10.0 255.255.255.0` | 指定客户端的内网路由（需配合服务端 route 使用） |
| push "route ..." | `push "route 192.168.20.0 255.255.255.0"` | 给该客户端推送额外路由 |
| push "redirect-gateway def1" | `push "redirect-gateway def1"` | 让客户端默认流量走 VPN |
| push "dhcp-option DNS ..." | `push "dhcp-option DNS 1.1.1.1"` | 指定客户端的 DNS |
| push "dhcp-option DOMAIN ..." | `push "dhcp-option DOMAIN example.com"` | 指定搜索域 |
| push "keepalive ..." | `push "keepalive 10 60"` | 维持客户端心跳 |
| push "comp-lzo" | `push "comp-lzo"` | 为客户端启用压缩 |
| push "cipher ..." | `push "cipher AES-256-CBC"` | 指定客户端加密算法 |

### 注意事项
- `iroute` 仅在 **CCD 文件**中生效，用于告诉 OpenVPN 哪个客户端负责某个子网。
- 服务端配置文件必须配合 `client-config-dir` 指令才能加载 CCD。
- 不能在 CCD 中使用服务端专用参数（如 `server`、`dev` 等）。

### CCD 示例

**固定 IP**
```conf
ifconfig-push 10.8.0.10 255.255.255.0
```

**访问客户端内网**
```conf
ifconfig-push 10.8.0.11 255.255.255.0
iroute 192.168.100.0 255.255.255.0
```

**为客户端设置专属 DNS**
```conf
ifconfig-push 10.8.0.12 255.255.255.0
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 1.1.1.1"
```

### 5. 启动 OpenVPN
```bash
/etc/init.d/openvpn enable
/etc/init.d/openvpn start
```


```
Ipv6防火墙 /::ffff:ffff:ffff:ffff
