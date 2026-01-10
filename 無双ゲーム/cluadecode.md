コーディングする際のルール

## 基本方針
・RobloxStudio MCPを使用して直接エクスプローラ内にコーディングすること
・シニアエンジニアのようなプロフェッショナルな実装をすること
・他機能に影響を与えないいいコーディングをすること
・拡張性、可読性、保守性を上げるために１機能１ファイルのように細かく分けてコーディングすること

## Robloxアーキテクチャ
・サービスの適切な配置を守ること
  - ServerScriptService: サーバー専用スクリプト
  - ReplicatedStorage: クライアント・サーバー共有モジュール
  - StarterPlayerScripts: クライアント専用スクリプト
  - StarterGui: UI関連スクリプト
・クライアント/サーバーの責務を明確に分離すること
・共通処理はModuleScriptとしてReplicatedStorageに配置すること

## セキュリティ
・RemoteEvent/RemoteFunctionの入力は必ずサーバー側で検証すること
・クライアントからのデータは信用せず、サーバーで正当性を確認すること
・重要なゲームロジックは必ずサーバー側で処理すること

## パフォーマンス
・大量オブジェクト生成時はオブジェクトプールを使用すること
・不要になったConnectionは必ず:Disconnect()すること
・ループ処理ではwait()よりtask.wait()を使用すること
・頻繁なInstance生成/破棄を避け、再利用を優先すること

## 命名規則
・ModuleScript: PascalCase（例：PlayerManager, ItemSystem）
・関数: camelCase（例：spawnEnemy, calculateDamage）
・定数: UPPER_SNAKE_CASE（例：MAX_HEALTH, SPAWN_INTERVAL）
・プライベート関数/変数: _camelCase（例：_internalUpdate）

## MCP連携時の作業手順
・コード実行前にget_scene_infoまたはrun_codeで現状を確認すること
・大きな変更は小さなステップに分けて実行すること
・各ステップ実行後に動作確認を行うこと
・エラー発生時はprintデバッグで原因特定してから修正すること

## エラーハンドリング
・pcall/xpcallを適切に使用し、エラーをハンドリングすること
・エラー発生時はwarnでログを出力すること
・ユーザーに影響するエラーは適切にフォールバック処理すること

## コメント・ドキュメント
・複雑なロジックには日本語でコメントを記載すること
・ModuleScriptの先頭にはモジュールの役割を記載すること
・公開関数には引数と戻り値の説明を記載すること
