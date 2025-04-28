#!/bin/bash

# 共通設定ファイルを読み込む
source ../../config/common.conf

# 共通ログディレクトリ
LOG_DIR="../../log/no_encrypt"
mkdir -p ${LOG_DIR}

# ネットワーク設定を適用する関数
apply_network_config() {
    local MODE=$1
    local NIC=$2
    local IP=$3

    if [[ -n "${NIC}" && -n "${IP}" ]]; then
        echo "${MODE}のネットワーク設定を適用しています..."
        ip addr add ${IP}/24 dev ${NIC}
        ip link set ${NIC} mtu 2000
        echo "${MODE}のネットワーク設定が完了しました。"
    else
        echo "${MODE}のNICまたはIPが設定されていません。スキップします。"
    fi
}

# 実行環境に応じた設定を選択
if [[ "$1" == "local" ]]; then
    apply_network_config "ローカル" ${L_PF_NIC} ${L_PF_IP}
elif [[ "$1" == "remote" ]]; then
    apply_network_config "リモート" ${R_PF_NIC} ${R_PF_IP}
else
    echo "使用方法: $0 [local|remote]"
    exit 1
fi

echo "設定が完了しました。"