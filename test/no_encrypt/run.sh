#!/bin/bash

# 共通設定ファイルを読み込む
source ../../config/common.conf

# 共通ログディレクトリの作成
mkdir -p ${LOG_DIR}

# リモート側のスクリプト実行時にすべての環境変数を渡す
execute_task() {
    local MODE=$1
    local COMMAND=$2

    if [[ "$MODE" == "local" ]]; then
        echo "ローカル側の${COMMAND}を実行中..."
        ./${COMMAND}.sh local
    elif [[ "$MODE" == "remote" ]]; then
        echo "リモート側の${COMMAND}を実行中..."
        sshpass -p "$R_PASS" ssh -o StrictHostKeyChecking=no $R_USER@$R_MGMT_IP \
            "$(env | grep -E '^(L_|R_|DEFAULT_CLIENT_IP)' | xargs) bash -s" < ./${COMMAND}.sh remote
    else
        echo "無効なモード: $MODE"
        exit 1
    fi

    if [[ $? -ne 0 ]]; then
        echo "${MODE}側の${COMMAND}に失敗しました。"
        exit 1
    fi
}

# ログ出力用の関数
log() {
    local MESSAGE=$1
    local TYPE=$2
    local TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

    case $TYPE in
        INFO)
            echo -e "\033[1;34m[INFO] [$TIMESTAMP] $MESSAGE\033[0m" | tee -a ${LOG_DIR}/run.log
            ;;
        SUCCESS)
            echo -e "\033[1;32m[SUCCESS] [$TIMESTAMP] $MESSAGE\033[0m" | tee -a ${LOG_DIR}/run.log
            ;;
        ERROR)
            echo -e "\033[1;31m[ERROR] [$TIMESTAMP] $MESSAGE\033[0m" | tee -a ${LOG_DIR}/run.log
            ;;
        *)
            echo "[UNKNOWN] [$TIMESTAMP] $MESSAGE" | tee -a ${LOG_DIR}/run.log
            ;;
    esac
}

# 実行フロー
log "ローカルおよびリモートのセットアップを開始します。" INFO
execute_task local setup  # ローカル環境の初期設定を実行
log "ローカルのセットアップが完了しました。" SUCCESS
execute_task remote setup  # リモート環境の初期設定を実行
log "リモートのセットアップが完了しました。" SUCCESS

# iperf.sh を実行
log "iperf.sh を実行します。" INFO
./iperf.sh ${CLIENT_IP} local
log "iperf.sh の実行が完了しました。" SUCCESS

# netperf.sh を実行
log "netperf.sh を実行します。" INFO
./netperf.sh ${CLIENT_IP}
log "netperf.sh の実行が完了しました。" SUCCESS

# ib_write_bw.sh を実行
log "ib_write_bw.sh を実行します。" INFO
./ib_write_bw.sh ${CLIENT_IP}
log "ib_write_bw.sh の実行が完了しました。" SUCCESS

# ローカルおよびリモートのティアダウンを実行
log "ローカルおよびリモートのティアダウンを開始します。" INFO
execute_task local teardown  # ローカル環境の後処理を実行
log "ローカルのティアダウンが完了しました。" SUCCESS
execute_task remote teardown  # リモート環境の後処理を実行
log "リモートのティアダウンが完了しました。" SUCCESS

log "全ての処理が完了しました。" SUCCESS
