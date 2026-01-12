# ゾンビシューティング 開発ドキュメント

> このファイルはClaude Codeとの作業の記録と、プロジェクトの全体像を把握するためのドキュメントです。

---

## 目次

1. [プロジェクト概要](#プロジェクト概要)
2. [現在の状態](#現在の状態)
3. [エクスプローラー構造](#エクスプローラー構造)
4. [修正履歴](#修正履歴)
5. [今後の開発予定](#今後の開発予定)

---

## プロジェクト概要

### ゲームコンセプト
99体のゾンビを倒すサバイバルシューティングゲーム

### 基本ルール
- **勝利条件**: 99体のゾンビを全滅させる
- **敗北条件**: プレイヤーが10回被弾するとゲームオーバー
- **武器**: 4種類の銃から選択可能（R15対応版）

---

## 現在の状態

### 完了済み機能
- [x] 99体のゾンビ配置
- [x] 敵AI（プレイヤー検出、追跡、攻撃）
- [x] 敵死亡処理
- [x] プレイヤーダメージ検出（10回被弾でゲームオーバー）
- [x] **被弾後無敵時間（1.5秒）** ← NEW
- [x] 残り敵数カウンター（UI）
- [x] ゲームオーバー/クリアイベント
- [x] 武器システム（R15対応4種）

### 武器一覧（2026/1/12更新）
| 武器名 | 状態 | 備考 |
|--------|------|------|
| Revolver | ✅ 使用可能 | R15対応 |
| 6 gold chain guns | ✅ 使用可能 | R15対応 |
| HexSpitter | ✅ 使用可能 | R15対応 |
| RocketLauncher | ✅ 使用可能 | R15対応 |
| ~~AKM~~ | ❌ 無効化 | R6専用のためServerStorageに移動 |
| ~~Shotgun~~ | ❌ 無効化 | R6専用のためServerStorageに移動 |
| ~~Super lazer gun~~ | ❌ 無効化 | R6専用のためServerStorageに移動 |

---

## エクスプローラー構造

```
Workspace/
├── Layout/ (レベルレイアウト)
├── Level_Art/ (レベルアート)
├── SpawnLocations/ (スポーン地点)
├── Forcefields/ (フォースフィールド)
├── Enemies/ (99体のゾンビ)
│   └── Zombie_1 ~ Zombie_99
│       ├── Zombie (Humanoid)
│       ├── Gun (Tool)
│       ├── EnemyType (StringValue)
│       └── [ボディパーツ]
├── Terrain
└── Baseplate

ServerScriptService/
├── ShootingGameController - ゲームメイン制御
├── EnemyAI - 敵AI（検出、追跡、攻撃）【調整済み】
├── EnemyDeathHandler - 敵死亡処理
├── PlayerDamageDetector - プレイヤー被弾検出【無敵時間追加】
├── Blaster/ - Blasterシステム（サーバー側）
└── Utility/

ServerStorage/
├── AKM (Tool) - R6専用のため無効化
├── Shotgun (Tool) - R6専用のため無効化
└── Super lazer gun (Tool) - R6専用のため無効化

ReplicatedStorage/
├── Blaster/ - Blasterシステム（共有）
├── Shared/
│   └── GameConfig (ModuleScript)
├── RemainingEnemies (IntValue) - 残り敵数
├── PlayerHitCount (IntValue) - プレイヤー被弾数
├── BossSpawned (BoolValue)
├── GameActive (BoolValue)
├── IsGameOver (BoolValue)
├── GameOverEvent (RemoteEvent)
├── GameClearEvent (RemoteEvent)
└── RestartGameEvent (RemoteEvent)

StarterPack/（R15対応武器のみ）
├── Revolver (Tool)
├── 6 gold chain guns (Tool)
├── HexSpitter (Tool)
└── RocketLauncher (Tool)

StarterGui/
└── EnemyCounterGui (ScreenGui)
```

---

## 修正履歴

### 2026年1月12日 修正

#### 1. R6専用武器の無効化
**問題**: AKM, Shotgun, Super lazer gunがR15アバターで動作しない
```
Infinite yield possible on 'Workspace.UroTanRen:WaitForChild("Torso")'
```
**解決**: R6専用武器をServerStorageに移動して無効化
- AKM → ServerStorage
- Shotgun → ServerStorage
- Super lazer gun → ServerStorage

#### 2. 被弾バランス調整（PlayerDamageDetector）
**問題**: 数秒で10回被弾してゲームオーバー
**解決**: 被弾後1.5秒の無敵時間を追加
- 無敵中は点滅エフェクト表示
- ダメージ無効化でHP回復

#### 3. 敵AI調整（EnemyAI）
**問題**: 敵の攻撃が激しすぎる
**解決**: バランス調整
| 設定 | 変更前 | 変更後 |
|------|--------|--------|
| 検出範囲 | 40 | 35 |
| 攻撃クールダウン | 2秒 | 3秒 |
| 攻撃範囲 | 5 | 4 |

---

## 主要スクリプト概要

### EnemyAI（調整済み）
```lua
-- 設定（バランス調整済み）
DETECTION_RANGE = 35  -- プレイヤー検出距離
WANDER_RANGE = 15     -- 徘徊範囲
ATTACK_COOLDOWN = 3   -- 攻撃クールダウン
ATTACK_RANGE = 4      -- 攻撃範囲
DAMAGE = 10           -- ダメージ
```

### PlayerDamageDetector（無敵時間追加）
```lua
INVINCIBILITY_TIME = 1.5  -- 被弾後の無敵時間（秒）
MAX_HITS = 10             -- 最大被弾数
-- 無敵中は点滅エフェクト + ダメージ無効化
```

---

## 今後の開発予定

### 優先度：高
1. [x] ~~R6専用武器の対応~~ → 無効化で対応
2. [x] ~~被弾バランス調整~~ → 無敵時間追加
3. [ ] 武器動作の確認テスト

### 優先度：中
4. [ ] 武器UI/UXの改善
5. [ ] 武器選択画面の追加
6. [ ] ゲーム開始/リスタートフローの改善

### 優先度：低
7. [ ] R6専用武器のR15対応（大規模改修）
8. [ ] ボスシステムの実装
9. [ ] BGM/効果音の追加
10. [ ] タイトル画面の追加

---

## GameConfig設定値

```lua
-- 敵設定（調整済み）
DETECTION_RANGE = 35
WANDER_RANGE = 15
ATTACK_RANGE = 4 (通常) / 6 (ボス)
ATTACK_COOLDOWN = 3 (通常) / 2 (ボス)
DAMAGE = 10

-- プレイヤー設定
MAX_HITS = 10           -- 最大被弾数
INVINCIBILITY_TIME = 1.5 -- 無敵時間（秒）

-- ゲーム設定
totalEnemies = 99
```

---

*最終更新: 2026年1月12日 13:50*
