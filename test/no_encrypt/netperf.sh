#!/bin/bash

# 共通設定ファイルを読み込む
source ../../config/common.conf

# 共通ログディレクトリ
LOG_DIR="../../log/no_encrypt/netperf"
mkdir -p ${LOG_DIR}

# netperf 実行関数
run_netperf() {
    local MODE=$1
    local ITERATION=$2
    echo "${MODE} モードの netperf を実行中 (試行 ${ITERATION})..."

    # クライアントコマンドを実行
    output_file="${LOG_DIR}/${MODE}_netperf_output${ITERATION}.log"
    client_cmd="sudo netperf -l 120 -H ${CLIENT_IP} -t ${MODE} -- -k MIN_LATENCY,MEAN_LATENCY,MAX_LATENCY,stddev_latency,p99_latency,transaction_rate"
    echo "${client_cmd}" > ${output_file}
    ${client_cmd} >> ${output_file}
}

# サーバーを起動
server_cmd="echo ${R_PASS} | sudo -S netserver"
sshpass -p "$R_PASS" ssh -o StrictHostKeyChecking=no $R_USER@$R_MGMT_IP "${server_cmd}"

# Check if CLIENT_IP is provided as an argument
if [[ -n "$1" ]]; then
    CLIENT_IP="$1"
else
    echo "使用方法: $0 <CLIENT_IP>"
    exit 1
fi

# 各モードと試行回数で netperf を実行
for mode in TCP_RR UDP_RR; do
    for i in {1..3}; do
        run_netperf $mode $i
    done
done

# サーバーを停止
stop_server_cmd="echo ${R_PASS} | sudo -S pkill netserver && pkill netperf"
sshpass -p "$R_PASS" ssh -o StrictHostKeyChecking=no $R_USER@$R_MGMT_IP "${stop_server_cmd}"

# 実行完了メッセージ
echo "netperf テストが完了しました。ログは ${LOG_DIR} に保存されています。"