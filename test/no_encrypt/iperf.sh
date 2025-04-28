#!/bin/bash

# 共通設定ファイルを読み込む
source ../../config/common.conf

# 共通ログディレクトリ
LOG_DIR="../../log/no_encrypt/iperf"
mkdir -p ${LOG_DIR}

# iperf 実行関数
run_iperf() {
    local PARALLEL=$1
    local CPU_SETTING=$2
    echo "${PARALLEL} 並列ストリームで iperf を開始します..."

    # サーバーを起動
    server_cmd="numactl --physcpubind=${CPU_SETTING} iperf -s -P ${PARALLEL}"
    sshpass -p "$R_PASS" ssh -o StrictHostKeyChecking=no $R_USER@$R_MGMT_IP "${server_cmd}" &
    sleep 5

    # クライアントを起動
    output_file="${LOG_DIR}/iperf_offload_P${PARALLEL}.log"
    client_cmd="numactl --physcpubind=${CPU_SETTING} iperf -c ${CLIENT_IP} -t 120 -P ${PARALLEL}"
    echo "${client_cmd}" > ${output_file}
    ${client_cmd} >> ${output_file}
}

# Check if CLIENT_IP is provided as an argument
if [[ -n "$1" ]]; then
    CLIENT_IP="$1"
else
    echo "使用方法: $0 <CLIENT_IP>"
    exit 1
fi

# CPU 設定を選択
if [[ "$2" == "local" ]]; then
    CPU=${L_CPU}
elif [[ "$2" == "remote" ]]; then
    CPU=${R_CPU}
else
    echo "使用方法: $0 <CLIENT_IP> [local|remote]"
    exit 1
fi

# 並列数のリスト
parallel_nums=(1 2 4 8)

# 各並列数で iperf を実行
for i in "${parallel_nums[@]}"; do
    run_iperf $i $CPU
done

# 実行完了メッセージ
echo "iperf テストが完了しました。ログは ${LOG_DIR} に保存されています。"