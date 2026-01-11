# 缶蹴りゲーム タスク一覧

> 詳細な情報は [CLAUDE.md](./CLAUDE.md) を参照

## 完了済みタスク

### ステージ準備
- [x] 建物の高さ調整（8個の建物を地面Y=0に合わせた）
- [x] モンスター無効化（HorrorGameManager を Disabled = true）
- [x] 軽量化実施（ライト、エフェクト、スクリプト削減）
- [x] パトカーライト点滅実装

### エクスプローラー構造リファクタリング（2024/1/11）
- [x] Workspace整理（Map/Buildings, Props, Vehicles）
- [x] 「Model」の名前を識別可能な名前に変更
- [x] ServerScriptServiceの整理（Legacy分離）
- [x] ReplicatedStorageの整理（空フォルダ削除、Legacy分離）
- [x] OniAIリファクタリング（v5、構造ガイド追加）

### バグ修正（2024/1/11）
- [x] 攻撃エフェクト消失問題（静的/インスタンス名前衝突）
- [x] 無限ループ / Path failedスパム
- [x] HPゲージ→エフェクトの順序問題
- [x] 警告UI「鬼が戻ってくるぞ！」が出ない問題

### 基盤システム
- [x] フォルダ構造作成
- [x] GameConfig（設定モジュール）作成
- [x] RoundManager（ラウンド管理）作成
- [x] GameController（メインスクリプト）作成
- [x] RemoteEvents作成（14個）

### コアオブジェクト
- [x] HP地点（缶の代替）実装
  - HPPointManager モジュール
  - 道路上にランダム配置
  - ProximityPromptで攻撃可能
  - 10秒クールダウン
  - 魂の炎ビジュアル
- [x] 安全ゾーン実装
  - SafeZoneManager モジュール
  - HP地点から30スタッド以上離れた場所に出現
  - 10秒滞在で消滅→別位置へ再出現

### 武器・攻撃システム
- [x] 剣（Sword）実装
  - Grip設定修正（柄を持ち、剣先が上向き）
  - クリックで攻撃アニメーション
- [x] HP地点攻撃エフェクト実装
  - 素手攻撃：オレンジ系エフェクト + パンチアニメーション
  - 剣攻撃：青白系エフェクト + 回転斬りアニメーション
  - R15対応
- [x] エフェクトコード整理
  - EffectLibrary（共通エフェクト関数）
  - AttackConfig（攻撃エフェクト設定）

### レベル・ダメージシステム
- [x] GameConfigにレベルシステム追加
  - Player Lv1-5: 攻撃力 50/75/100/130/165
  - Enemy Lv1-5: HP 100/200/350/550/800
- [x] OniHPManager作成（鬼HP管理）
- [x] HPPointManager → OniHPManager統合
- [x] GameController → OniHPManager初期化追加

### UI
- [x] 鬼HPゲージ（OniHPGui）
  - 画面上部中央に表示
  - HP減少アニメーション
  - 色変化（緑→黄→赤）
  - ダメージ時シェイク
- [x] 勝利演出（VictoryGui）
  - "VICTORY!" テキスト
  - フェードイン/アウトアニメーション

---

## 残りタスク

### フェーズ3: 鬼AI ✅ 完了（修正済み）
- [x] OniAIモジュール作成（状態管理: PATROL/CHASE/STUNNED/RETURNING/DEFEATED）
- [x] 巡回システム（PatrolPoints 10箇所、道路上）
- [x] **PathfindingService導入（建物を避けて移動）**
- [x] 索敵システム（距離50+視野角120+Raycast遮蔽）
- [x] 追跡システム（ChaseSpeed=32、見失い猶予3秒）
- [x] 発見演出（！マーク）
- [x] プレイヤー捕捉時の即死攻撃（Humanoid.Health=0）
- [x] 怯み演出（灰色化+震え+黄色パーティクル）
- [x] 「鬼が戻ってくるぞ！」UI警告（赤点滅+揺れるテキスト）
- [x] 撃破演出（少し飛んで倒れる、暗くなって残る）
- [x] 速度設定の確実な更新（各状態でWalkSpeed明示設定）
- [x] RETURNING状態の帰還ロジック修正（HP地点へ高速移動）

### フェーズ4: プレイヤーシステム
- [ ] プレイヤーHP
  - 初期HP: 3
  - 鬼に捕まると-1
  - HP0で行動不能
- [ ] 復帰システム
  - ダイヤ1個消費で復帰
  - 復帰時HP: 1
  - 安全な位置にスポーン

### フェーズ5: UI追加
- [ ] プレイヤーUI
  - プレイヤーHP表示
  - HP地点クールダウン表示
  - 復帰ボタン（ダイヤ消費）

### フェーズ6: マルチプレイ対応
- [ ] 鬼HPスケーリング
  - 人数に応じた鬼HP調整
  - 途中参加・離脱対応

### その他（優先度低）
- [ ] サウンド調整
- [ ] エフェクト微調整
- [ ] バランス調整（攻撃力、HP、クールダウン等）

---

## 要確認事項

- [ ] 鬼がHP地点に戻らない問題の調査（RETURNING状態）
- [ ] GameConfig Levelシステムの動作確認
  - Roblox Studioでプレイモード実行後にテスト
  - HP地点2回攻撃で敵撃破確認
  - HPゲージとVICTORY演出の確認

---

## 構造評価スコア

| 項目 | Before | After |
|------|--------|-------|
| Workspace構造 | 30点 | 75点 |
| ServerScriptService | 60点 | 85点 |
| ReplicatedStorage | 55点 | 80点 |
| 命名規則 | 40点 | 80点 |
| モジュール設計 | 55点 | 75点 |
| **総合** | **52点** | **79点** |
