# G's Academy Fukuoka Swift講座用 簡易マッチングアプリ

## Requirement
- pod install
- Firebaseコンソールからプロジェクト作成
- Firebase Authentication 設定(Eメール認証をOn)
- Firebase Firestore 設定
- Firebase Storage 設定

### 実装済み
- ログイン/会員登録
- ユーザー一覧表示
- いいね/いいねキャンセル

### 今後追加
- ユーザー一覧にはマッチしていないユーザーのみ表示
- MessageKit実装
- MessageコレクションにMessageを貯めていく

### 妥協ポイント
- マイページのレイアウトやデータ表示は宿題にする
- 性別項目を省略
- CustomTableViewCellは使用せずデフォルトのCellでなんとかやりくり(delegateの説明や画面作成の時間を省略するため)