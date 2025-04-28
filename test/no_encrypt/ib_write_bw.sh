#!/bin/bash

# 共通設定ファイルを読み込む
source ../../config/common.conf

# 共通ログディレクトリ
LOG_DIR="../../log/no_encrypt/ib_write_bw"
mkdir -p ${LOG_DIR}

# ib_write_bw 実行関数
run_ib_write_bw() {
    echo "ib_write_bw を実行中..."

    # サーバーを起動
    server_cmd="numactl --physcpubind=$CPU ib_write_bw -d ${R_MLX_NIC} --report_gbits"
    sshpass -p "$R_PASS" ssh -o StrictHostKeyChecking=no $R_USER@$R_MGMT_IP "${server_cmd}" &
    sleep 5

    # クライアントを起動
    output_file="${LOG_DIR}/ib_write_bw.log"
    client_cmd="numactl --physcpubind=$CPU ib_write_bw ${CLIENT_IP} -d ${L_MLX_NIC} --report_gbits"
    echo "${client_cmd}" > ${output_file}
    ${client_cmd} >> ${output_file}

    # ethtool のログを取得
    /opt/mellanox/ethtool/sbin/ethtool -S ${L_VF_NIC} | grep ipsec > ${LOG_DIR}/ethtool_after.log
}

# Check if CLIENT_IP is provided as an argument
if [[ -n "$1" ]]; then
    CLIENT_IP="$1"
else
    echo "使用方法: $0 <CLIENT_IP>"
    exit 1
fi

# ethtool の事前ログを取得
/opt/mellanox/ethtool/sbin/ethtool -S enp22s0v0 | grep ipsec > ${LOG_DIR}/ethtool_before.log

# ib_write_bw を実行
run_ib_write_bw

# 実行完了メッセージ
echo "ib_write_bw テストが完了しました。ログは ${LOG_DIR} に保存されています。"