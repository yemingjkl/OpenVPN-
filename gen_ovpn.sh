#!/bin/sh

# 检查是否提供了客户端名称参数
if [ -z "$1" ]; then
    echo "使用方法: sh $0 <client_name>"
    echo "例如: sh $0 clientA"
    exit 1
fi

CLIENT_NAME="$1"

# 定义路径和文件名
EASYRSA_DIR="/etc/easy-rsa"
CA_FILE="$EASYRSA_DIR/pki/ca.crt"
CLIENT_CERT_FILE="$EASYRSA_DIR/pki/issued/$CLIENT_NAME.crt"
CLIENT_KEY_FILE="$EASYRSA_DIR/pki/private/$CLIENT_NAME.key"
OUTPUT_OVP_FILE="/etc/openvpn/$CLIENT_NAME.ovpn"

# 请根据你的实际情况修改以下参数
OPENVPN_SERVER_IP="**********"
PORT="1194"
PROTO="tcp-client"

# 检查客户端证书和密钥是否存在
check_and_generate_client_keys() {
    echo "检查客户端证书和密钥 '$CLIENT_NAME'..."

    # 切换到 easy-rsa 目录，确保命令正确执行
    cd "$EASYRSA_DIR" || { echo "错误：无法切换到 easy-rsa 目录。请检查路径是否正确。"; exit 1; }

    # 检查所需的证书和密钥文件是否存在
    if [ ! -f "$CLIENT_CERT_FILE" ] || [ ! -f "$CLIENT_KEY_FILE" ]; then
        echo "客户端证书或密钥文件不存在，正在使用 easy-rsa 生成..."
        
        # 确保 CA 证书存在，否则无法生成客户端证书
        if [ ! -f "$CA_FILE" ]; then
            echo "错误：CA 证书不存在。请先在 /etc/easy-rsa 目录下运行 'easyrsa build-ca nopass' 创建。"
            exit 1
        fi
        
        # 生成客户端证书和密钥
        easyrsa build-client-full "$CLIENT_NAME" nopass
        echo "客户端证书和密钥已成功生成。"
    else
        echo "客户端证书和密钥文件都已存在，跳过生成步骤。"
    fi
}

# 生成 OpenVPN 客户端配置文件
generate_ovpn() {
    echo "正在生成 .ovpn 配置文件 '$CLIENT_NAME'..."

    # 检查所有必需的文件是否存在
    if [ ! -f "$CA_FILE" ] || [ ! -f "$CLIENT_CERT_FILE" ] || [ ! -f "$CLIENT_KEY_FILE" ]; then
        echo "错误：缺少必需的 CA 证书或客户端文件。"
        exit 1
    fi

    # 读取证书和密钥内容
    CA_CONTENT=$(cat "$CA_FILE")
    CERT_CONTENT=$(cat "$CLIENT_CERT_FILE")
    KEY_CONTENT=$(cat "$CLIENT_KEY_FILE")

    # 将配置内容写入文件
    cat > "$OUTPUT_OVP_FILE" <<- EOF
client
dev tun
proto $PROTO
remote $OPENVPN_SERVER_IP $PORT
resolv-retry infinite
nobind
persist-key
persist-tun
verb 3
    
<ca>
$CA_CONTENT
</ca>
<cert>
$CERT_CONTENT
</cert>
<key>
$KEY_CONTENT
</key>
EOF

    echo "配置文件已成功生成到: $OUTPUT_OVP_FILE"
    echo "你可以将此文件下载到你的设备上使用。"
}

# 执行主函数
check_and_generate_client_keys
generate_ovpn
