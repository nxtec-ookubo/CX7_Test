#!/bin/bash

# 共通設定ファイルを読み込む
source ../../config/common.conf

# 共通ログディレクトリ
LOG_DIR="/tmp/no_encrypt_logs"
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

# 実行フロー
# ローカルおよびリモートのセットアップを実行
execute_task local setup  # ローカル環境の初期設定を実行
execute_task remote setup  # リモート環境の初期設定を実行

# iperf.sh を実行
# ネットワーク帯域幅を測定するためのテストを実行
CLIENT_IP=${CLIENT_IP:-$DEFAULT_CLIENT_IP}  # config/common.conf からデフォルト値を取得
./iperf.sh ${CLIENT_IP}

# netperf.sh を実行
# ネットワークの遅延やトランザクションレートを測定するためのテストを実行
./netperf.sh ${CLIENT_IP}

# ib_write_bw.sh を実行
# InfiniBand の帯域幅を測定するためのテストを実行
./ib_write_bw.sh ${CLIENT_IP}

# ローカルおよびリモートのティアダウンを実行
execute_task local teardown  # ローカル環境の後処理を実行
execute_task remote teardown  # リモート環境の後処理を実行

echo "全ての処理が完了しました。"  # 全てのタスクが正常に完了したことを通知
