#!/bin/bash

# パスワード付きPFXファイル作成スクリプト
# Usage: ./create-password-protected-pfx.sh

set -e

# 設定
ORIGINAL_PFX=""
NEW_PFX=""
TEMP_CERT="temp_cert.pem"
TEMP_KEY="temp_key.pem"

echo "=== パスワード付きPFXファイル作成開始 ==="

# パスワード入力
echo ""
read -s -p "PFXファイルに設定するパスワードを入力してください: " PFX_PASSWORD
echo ""
read -s -p "パスワードを再入力してください（確認）: " PFX_PASSWORD_CONFIRM
echo ""

# パスワード確認
if [ "$PFX_PASSWORD" != "$PFX_PASSWORD_CONFIRM" ]; then
    echo "❌ パスワードが一致しません。スクリプトを終了します。"
    exit 1
fi

# パスワードの長さ確認
if [ ${#PFX_PASSWORD} -lt 8 ]; then
    echo "❌ パスワードは8文字以上で設定してください。"
    exit 1
fi

echo "✅ パスワードが設定されました。"
echo ""

# 1. 元のPFXファイルの存在確認
if [ ! -f "$ORIGINAL_PFX" ]; then
    echo "エラー: 元のPFXファイルが見つかりません: $ORIGINAL_PFX"
    exit 1
fi

echo "1. 元のPFXファイルを確認しました: $ORIGINAL_PFX"

# 2. 既存のPFXから証明書と秘密鍵を抽出（パスワードなしと仮定）
echo "2. PFXファイルから証明書と秘密鍵を抽出中..."
openssl pkcs12 -in "$ORIGINAL_PFX" -out "$TEMP_CERT" -nodes -passin pass:

# 3. 証明書のみを抽出
echo "3. 証明書のみを抽出中..."
openssl pkcs12 -in "$ORIGINAL_PFX" -out temp_cert_only.pem -nokeys -passin pass:

# 4. 秘密鍵のみを抽出
echo "4. 秘密鍵のみを抽出中..."
openssl pkcs12 -in "$ORIGINAL_PFX" -out "$TEMP_KEY" -nocerts -nodes -passin pass:

# 5. パスワード付きPFXファイルを作成
echo "5. パスワード付きPFXファイルを作成中..."
echo "   パスワード: [設定済み]"
openssl pkcs12 -export -out "$NEW_PFX" -inkey "$TEMP_KEY" -in temp_cert_only.pem -password pass:"$PFX_PASSWORD"

# 6. 一時ファイルを削除
echo "6. 一時ファイルをクリーンアップ中..."
rm -f "$TEMP_CERT" "$TEMP_KEY" temp_cert_only.pem

# 7. 結果確認
if [ -f "$NEW_PFX" ]; then
    echo "✅ パスワード付きPFXファイルが正常に作成されました: $NEW_PFX"
    echo "   ファイルサイズ: $(ls -lh "$NEW_PFX" | awk '{print $5}')"
else
    echo "❌ PFXファイルの作成に失敗しました"
    exit 1
fi
