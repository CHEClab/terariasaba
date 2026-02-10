#!/bin/bash

echo "--- Ubuntu Terraria Server Environment Setup (x86_64) ---"
date

# 1. 必須ツールのインストール
echo "[1/6] 必須ツールの確認..."
# Ubuntu 22.04では mono-complete を入れるのが最も確実です
PACKAGES="curl wget unzip mono-complete"
sudo apt update
sudo apt install -y $PACKAGES

# 2. .NET 6.0 のインストール (成功率の高いスクリプト方式)
echo "[2/6] .NET 6.0 のインストール確認..."
if command -v dotnet >/dev/null 2>&1; then
    echo "  -> .NET はインストール済みです (Skip)"
else
    echo "  -> Microsoft公式スクリプトで .NET 6.0 をインストールします..."
    wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
    chmod +x dotnet-install.sh
    ./dotnet-install.sh --channel 6.0
    rm dotnet-install.sh
fi

# 3. 環境変数(PATH)の設定
echo "[3/6] 環境変数(PATH)の確認..."
if grep -q "DOTNET_ROOT" ~/.bashrc; then
    echo "  -> .bashrc 設定済みです (Skip)"
else
    echo "  -> .bashrc に .NET のパスを追記します..."
    echo 'export DOTNET_ROOT=$HOME/.dotnet' >> ~/.bashrc
    echo 'export PATH=$PATH:$HOME/.dotnet:$HOME/.dotnet/tools' >> ~/.bashrc
    source ~/.bashrc
fi

# 4. サーバーディレクトリの作成
echo "[4/6] サーバーディレクトリの準備..."
mkdir -p "$HOME/teraria"

# 5. 自動起動設定(Systemd) 【選択式】
echo ""
echo "[5/6] 自動起動設定(Systemd)のセットアップ"
echo "  説明: サーバー起動時に自動でテラリアを立ち上げます。"
echo -n "  -> 有効にしますか？ (y/n): "
read -r ANSWER_SYSTEMD

if [[ "$ANSWER_SYSTEMD" =~ ^[Yy]$ ]]; then
    SERVICE_FILE="/etc/systemd/system/terraria.service"
    sudo bash -c "cat << EOL > $SERVICE_FILE
[Unit]
Description=Terraria Official Server Auto Launcher
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME
ExecStart=/bin/bash $HOME/terakidou.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOL"
    sudo systemctl daemon-reload
    sudo systemctl enable terraria.service
    echo "  -> 設定完了。"
fi

# 6. 朝5時の自動更新(Cron) 【選択式】
echo ""
echo "[6/6] 定期再起動(Cron)のセットアップ"
echo "  説明: 毎朝5時に再起動し、自動更新をチェックします。"
echo -n "  -> 有効にしますか？ (y/n): "
read -r ANSWER_CRON

if [[ "$ANSWER_CRON" =~ ^[Yy]$ ]]; then
    CRON_CMD="0 5 * * * pkill -f TerrariaServer.exe"
    (crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -
    echo "  -> 設定完了。"
fi

echo ""
echo "--- Setup Completed! ---"
echo "設定反映のため、一度 'source ~/.bashrc' を実行するか、再ログインしてください。"
