#!/bin/bash

# ネットワーク設定を削除する関数
remove_network_config() {
    local MODE=$1
    local NIC=$2
    local IP=$3

    if [[ -n "${NIC}" && -n "${IP}" ]]; then
        echo "${MODE}のネットワーク設定を削除しています..."
        ip addr del ${IP}/24 dev ${NIC}
        ip link set ${NIC} mtu 1500
        echo "${MODE}のネットワーク設定の削除が完了しました。"
    else
        echo "${MODE}のNICまたはIPが設定されていません。スキップします。"
    fi
}

# 実行環境に応じた設定を選択
if [[ "$1" == "local" ]]; then
    remove_network_config "ローカル" ${L_PF_NIC} ${L_PF_IP}
elif [[ "$1" == "remote" ]]; then
    remove_network_config "リモート" ${R_PF_NIC} ${R_PF_IP}
else
    echo "使用方法: $0 [local|remote]"
    exit 1
fi

echo "クリーンアップが完了しました。"