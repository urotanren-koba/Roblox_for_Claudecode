# 鬼狩リ -KILLER HUNT- 開発ドキュメント

> このファイルはClaude Codeとの作業の記録と、プロジェクトの全体像を把握するためのドキュメントです。

---

## 目次

1. [プロジェクト概要](#プロジェクト概要)
2. [現在の状態](#現在の状態)
3. [エクスプローラー構造](#エクスプローラー構造)
4. [モジュール設計](#モジュール設計)
5. [既知の問題と解決履歴](#既知の問題と解決履歴)
6. [今後の開発予定](#今後の開発予定)
7. [開発ルール・注意事項](#開発ルール注意事項)
8. [ゲームテキスト](#ゲームテキスト)

---

## プロジェクト概要

### ゲームタイトル
**鬼狩リ -KILLER HUNT-**

### ゲームコンセプト
缶蹴りの構造を現代化した「**高速鬼（NPC）から逃げつつ、HP地点を攻撃して鬼HPを0にする**」スリル型ホラーアクションゲーム。

### 基本ルール
- **勝利条件**: 鬼のHPを0にする
- **敗北条件**: プレイヤーHPが0になり復帰しない
- **HP地点**: 攻撃すると鬼にダメージ + 鬼がスタン
- **安全ゾーン**: 入ると鬼から見えなくなる（10秒制限）

### 主要な特徴
- 鬼は非常に高速（追跡速度32）で、発見されると基本不利
- HP地点攻撃で鬼の追跡を中断できる（チームプレイの核心）
- ソロ/マルチ対応

---

## 現在の状態

### 完了済み機能
- [x] ステージ準備（建物配置、軽量化）
- [x] 基盤システム（GameConfig, RoundManager, Events）
- [x] HP地点（魂の炎ビジュアル、10秒クールダウン、攻撃後移動）
- [x] 安全ゾーン（緑の円柱、10秒滞在制限）
- [x] 武器システム（素手/剣、エフェクト分離）
- [x] 鬼AI v7（PathfindingService、状態マシン、道路巡回、スタック検出）
- [x] UI（鬼HPゲージ、勝利演出、レスポンシブ対応）
- [x] 発見演出（！マーク）
- [x] 警告UI（「鬼が戻ってくるぞ！」）
- [x] **プレイヤーHP（初期3、被ダメージ処理、死亡演出）**
- [x] **復帰システム（ダイヤ消費）**
- [x] **プレイヤーUI（HP表示ハート、復帰ボタン）**
- [x] **リスポーン無敵（ダメージ後のリスポーン時のみ3秒）**
- [x] **鬼の建物内追跡（Pathfinding使用）**
- [x] **UI配置改善（PlayerHPGui右上、ReviveGui上寄り中央）**
- [x] **UIホラー風デザイン（ダーク背景、赤/紫グロー）**
- [x] **HP地点/安全ゾーンのラベル削除（遠距離視認防止）**
- [x] **BGM追加（Deadly Assault、ループ再生）**
- [x] **画面フローシステム（タイトル→ホーム→ステージ選択→ルール→ゲーム）**
- [x] **TitleGui（パーティクルアニメーション付き）**
- [x] **HomeGui（GAME STARTボタン）**
- [x] **StageSelectGui（ステージ1のみ選択可、2-3はCOMING SOON）**
- [x] **RuleGui（ストーリー風ルール説明、「今後表示しない」チェックボックス）**
- [x] **VictoryGui改修（ホームに戻るボタン追加）**
- [x] **ReviveGui改修（復活・諦めるボタン、LOSEテキスト）**
- [x] **GameControllerリセット機能（StartGame/ResetGameイベント対応）**

### 未実装機能
- [ ] マルチプレイ対応（HPスケーリング）
- [ ] HP地点クールダウン表示UI

### 現在のバグ・課題
| 状態 | 内容 |
|------|------|
| **🔴 未解決** | **ゲームリセットが完全に動作しない（ホーム→新規ゲームで前のゲーム状態が残る）** |
| 解決済み | 安全ゾーン内でも鬼に攻撃される |
| 解決済み | 初回スポーン時に無敵が適用される |
| 解決済み | 鬼の攻撃ループ（無敵中） |

### 🔴 現在作業中の問題：ゲームリセット

**問題:**
- 勝利/敗北後に「ホームに戻る」→「ゲーム開始」しても、完全な新規ゲームにならない
- 鬼のAI状態（スタック検出等）がリセットされない
- 前のゲームの状態が残ってしまう

**実装済みの修正（テストプレイ再起動後に有効）:**

1. **OniAI.ResetOni()** - 完全リセット関数
   - State → PATROL
   - Target、全タイマー → リセット
   - パスファインディング → クリア
   - スタック検出 → リセット
   - 位置 → PatrolPoints[1]に戻す
   - Velocity → 0

2. **GameController.ResetGame()** - フルリセット
   - ラウンド終了
   - OniAI.ResetOni()呼び出し
   - OniHPManager.Reset()
   - HPPointManager.Cleanup()
   - SafeZoneManager.Cleanup()
   - Workspace強制クリーンアップ

3. **GameController.StartRound()** - 開始時にもOniAI.ResetOni()を呼び出し

4. **UIの初期状態設定**
   - OniHPGui/PlayerHPGui → 初期非表示
   - ゲーム開始時に表示、ホーム戻り時に非表示

**⚠️ 重要:** スクリプト変更は実行中のゲームには反映されない。テストプレイを停止→再開する必要あり。

---

## エクスプローラー構造

### 2026年1月11日 更新

```
Workspace/
├── Map/
│   ├── Buildings/ (22 items)
│   ├── Props/ (5 items)
│   └── Vehicles/ (5 items)
├── Enemy/
│   └── Enemy NPC (鬼)
├── PatrolPoints/ (12 items) - 鬼の巡回ルート
├── GoalPositions/ (10 items) - HP地点/安全ゾーン候補
├── HPPoints/ (ランタイム生成)
└── SafeZones/ (ランタイム生成)

ServerScriptService/
├── KanKeri/
│   ├── Modules/
│   │   ├── OniAI (v7) - 鬼AI（状態マシン、道路巡回、スタック検出、建物追跡）
│   │   ├── OniHPManager - 鬼HP管理
│   │   ├── HPPointManager - HP地点管理（攻撃後移動機能）
│   │   ├── SafeZoneManager - 安全ゾーン管理
│   │   ├── PlayerHPManager (v5.1) - プレイヤーHP管理（NEW）
│   │   └── RoundManager - ラウンド管理
│   └── Controllers/
│       ├── GameController - メインスクリプト
│       └── PoliceLightFlash - パトカーライト演出
└── Legacy/
    └── HorrorGameManager - 未使用（旧システム）

ReplicatedStorage/
├── KanKeri/
│   ├── Config/
│   │   └── GameConfig - ゲーム設定値
│   ├── Modules/
│   │   ├── EffectLibrary - 共通エフェクト関数
│   │   ├── AttackConfig - 攻撃エフェクト設定
│   │   └── UIUtility - レスポンシブUI用ユーティリティ
│   └── Events/ (23 RemoteEvents)
│       ├── StartGame - ゲーム開始リクエスト
│       ├── ResetGame - ゲームリセットリクエスト
│       ├── PlayerHPChanged
│       ├── PlayerDied
│       ├── PlayerRevived
│       └── RequestRevive
└── Legacy/
    └── Monsters/ - 未使用（旧モンスター）

StarterPlayer/
└── StarterPlayerScripts/
    ├── AttackEffectHandler - HP地点攻撃エフェクト
    ├── DiscoveryEffectHandler - 発見演出（！マーク）
    ├── OniWarningHandler - 警告UI（レスポンシブ対応）
    ├── PlayerHPHandler (NEW) - プレイヤーHP表示・エフェクト
    └── ReviveHandler (NEW) - 復帰ボタン処理

StarterGui/
├── TitleGui - タイトル画面（パーティクルアニメーション）
├── HomeGui - ホーム画面（GAME STARTボタン）
├── StageSelectGui - ステージ選択画面
├── RuleGui - ルール説明画面（「今後表示しない」機能）
├── OniHPGui - 鬼HPゲージ（レスポンシブ対応）
├── VictoryGui - 勝利演出（ホームに戻るボタン）
├── PlayerHPGui - プレイヤーHP表示（ハート3つ）
└── ReviveGui - 敗北画面（復活・諦めるボタン）
```

---

## モジュール設計

### OniAI v7 構造ガイド

```lua
-- ============================================================
-- [モジュール構造ガイド]
-- 静的関数 (OniAI.xxx): GetActiveOni, HandleHPPointAttack,
--   NotifyHPPointAttacked, NotifyOniDefeated
-- インスタンスメソッド (self:xxx): OnHPPointAttacked, Update,
--   SetState, Defeat, CatchPlayer, IsPlayerInSafeZone, etc.
-- 重要: 静的(.)とインスタンス(:)を混同しないこと！
-- ============================================================
```

**v7の主な機能:**
- 道路ベース巡回（PatrolPointsを使用）
- スタック検出と自動復帰
- 椅子に座らない（Seated状態無効化）
- SafeZoneManagerへの委譲（IsPlayerInSafeZone）
- CatchPlayer前の安全ゾーンチェック
- **建物内追跡（Pathfinding使用、視線が切れても追跡継続）**
- **攻撃クールダウン（無敵中の連続攻撃防止）**

**状態マシン:**
```
PATROL → (プレイヤー発見) → CHASE
PATROL → (索敵タイマー) → SCOUT
SCOUT → (索敵完了) → PATROL
CHASE → (HP地点攻撃) → STUNNED
CHASE → (安全ゾーン内) → RETURNING
CHASE → (視線が切れても距離80以内) → CHASE継続（Pathfinding）
CHASE → (10秒見失う or 距離80超) → RETURNING
STUNNED → (3秒後) → RETURNING
RETURNING → (HP地点到着) → PATROL
CHASE → (プレイヤー捕捉) → PATROL
任意状態 → (HP=0) → DEFEATED
```

### PlayerHPManager v5.1 構造

```lua
-- ============================================================
-- PlayerHPManager v5.1
-- Roblox標準リスポーンシステムを使用
-- ダメージ時はHumanoid.Health = 0で死亡演出
-- リスポーン後に無敵時間を付与（初回スポーンは無敵なし）
-- ============================================================

-- 主要関数:
-- PlayerHPManager.SetupPlayer(player) - プレイヤー初期化
-- PlayerHPManager.TakeDamage(player, damage) - ダメージ処理
-- PlayerHPManager.IsInvincible(player) - 無敵判定
-- PlayerHPManager.RequestRevive(player) - 復帰リクエスト
-- PlayerHPManager.Init() - 初期化（GameControllerから呼ぶ）
```

**設計ポイント:**
- キャラクター単位の無敵管理（`respawnInvincible[character]`）
- `HasTakenDamage`フラグで初回スポーンと再スポーンを区別
- pcallでエラー保護
- 遅延ロード（lazy loading）でモジュール読み込み

### モジュール間の依存関係

```
GameController
    ├── RoundManager
    ├── HPPointManager ──→ OniHPManager
    │                  ──→ OniAI.HandleHPPointAttack()
    ├── SafeZoneManager
    ├── PlayerHPManager (NEW)
    └── OniAI ──→ OniHPManager (敗北時)
              ──→ SafeZoneManager.IsPlayerInSafeZone() (安全ゾーン判定)
              ──→ PlayerHPManager.TakeDamage() (プレイヤーダメージ)

イベントフロー:
HP地点攻撃 → HPPointManager.AttackHPPoint()
          → PlayAttackEffect:FireClient() [エフェクト]
          → OniHPManager.Damage() [ダメージ]
          → OniAI.HandleHPPointAttack() [スタン]
          → HPPointManager.MoveHPPoint() [HP地点移動]

プレイヤーダメージ → OniAI:CatchPlayer()
                 → PlayerHPManager.TakeDamage()
                 → PlayerHPChanged:FireClient() [UI更新]
                 → Humanoid.Health = 0 [死亡演出]
                 → CharacterAdded [リスポーン]
                 → 無敵時間開始（3秒）
```

---

## 既知の問題と解決履歴

### 2026年1月12日 修正（フェーズ5実装）

| # | 問題 | 原因 | 解決方法 |
|---|------|------|----------|
| 1 | Victory画面が表示されない | VictoryControllerがOniDefeatedイベント未接続 | イベント接続を追加 |
| 2 | Defeat画面が表示されない | ReviveControllerがPlayerDiedイベント未接続 | イベント接続を追加 |
| 3 | ゲームリセットが動作しない | GameControllerにStartGame/ResetGameハンドラがない | gameActiveフラグとResetGame関数を追加 |

### 2026年1月11日 修正（フェーズ4実装）

| # | 問題 | 原因 | 解決方法 |
|---|------|------|----------|
| 1 | 鬼がHP地点に戻らない | RETURNING状態の問題 | v7で道路ベース巡回に変更 |
| 2 | 鬼が椅子に座る | モデルのSeat効果 | Seated状態を無効化 |
| 3 | 鬼が建物にスタック | パス計算失敗 | スタック検出と自動復帰を追加 |
| 4 | HP地点のEキーが出ない | ProximityPromptがBase（地面）にあった | SoulCore（浮いている炎）に移動、RequiresLineOfSight=false |
| 5 | 安全ゾーン内でも攻撃される | OniAIがSafeZoneManagerと連携していなかった | IsPlayerInSafeZoneをSafeZoneManagerに委譲、CatchPlayer前にチェック追加 |
| 6 | PlayerHPManager読み込みエラー | `...`がネスト関数内で使用 | `local args = {...}` + `unpack(args)`に修正 |
| 7 | 初回スポーン時に無敵 | OnCharacterAddedが全スポーンで無敵付与 | `HasTakenDamage`フラグで初回/再スポーン判別 |
| 8 | 鬼の攻撃ループ | 無敵中に毎フレーム攻撃試行 | `AttackCooldown`（1秒）を追加 |
| 9 | 鬼が建物に入れない | 視線が切れると追跡中止 | UpdateChaseでPathfinding使用、距離ベース追跡継続 |

### 以前の修正

| # | 問題 | 原因 | 解決方法 |
|---|------|------|----------|
| 1 | 攻撃エフェクトが出ない | `OnHPPointAttacked`の名前衝突 | 静的関数を`HandleHPPointAttack`にリネーム |
| 2 | 無限ループ発生 | 同名関数による再帰呼び出し | 名前を分離 |
| 3 | Path failed:NoPath スパム | パス計算リトライが無制限 | `PathRetryTimer`で0.5秒間隔に制限 |

### 根本原因（重要）

```lua
-- Luaでは静的関数とインスタンスメソッドに同じ名前を使うと上書きされる
function OniAI:OnHPPointAttacked()  -- インスタンスメソッド
function OniAI.OnHPPointAttacked()  -- 静的関数（これが上書き）

-- 可変引数(...)はネスト関数内で直接使用できない
local function foo(...)
    pcall(function()
        bar(...)  -- ERROR!
    end)
end
-- 正しい方法:
local function foo(...)
    local args = {...}
    pcall(function()
        bar(unpack(args))  -- OK
    end)
end
```

---

## GameConfig設定値

### Oni設定
```lua
GameConfig.Oni = {
    PatrolSpeed = 16,
    ChaseSpeed = 32,
    StunDuration = 3,
    PreventSitting = true,
    ChaseMaxDistance = 80,    -- 追跡を続ける最大距離
    ChasePersistTime = 10,    -- 見失っても追跡を続ける時間（秒）
    Patrol = {
        Mode = "ROAD",
        NearbyRadius = 50,
        NearbyPointCount = 4,
        ScoutEnabled = true,
        ScoutInterval = 45,
        ScoutDuration = 15,
        PathRetryInterval = 0.5,
        MaxPathFailures = 3,
        ReturnTimeout = 10,
    },
    StuckDetection = {
        Enabled = true,
        CheckInterval = 1.0,
        MinMoveDistance = 2.0,
        StuckThreshold = 3,
        RecoveryAction = "NEXT",
    }
}
```

### Player設定（NEW）
```lua
GameConfig.Player = {
    MaxHP = 3,
    ReviveHP = 1,
    ReviveDiamondCost = 1,
    MoveSpeed = 16,
    RespawnInvincibilityTime = 3,
}
```

### HP地点設定
```lua
GameConfig.HPPoint = {
    CooldownDuration = 10,
    InteractionRange = 8,
    Movement = {
        Enabled = true,
        MoveAfterCooldown = true,
        TeleportDelay = 0.5,
        FadeOutDuration = 0.5,
        FadeInDuration = 0.5,
        MinDistanceFromCurrent = 30,
        AvoidRecentPositions = true,
        RecentPositionCount = 2,
    }
}
```

---

## 今後の開発予定

### フェーズ5: 画面フローシステム ✅完了

ゲーム全体の画面遷移を実装した。

#### 画面遷移フロー
```
[タイトル画面] ─ START ─→ [ホーム画面] ─ GAME START ─→ [ステージ選択]
                                                              │
                                                        ステージ1選択
                                                              ▼
                                                        [ルール画面]
                                                         （初回のみ表示、
                                                          「今後表示しない」で
                                                           スキップ可能）
                                                              │
                                                           閉じる
                                                              ▼
                                                        [ゲームプレイ]
                                                              │
                              ┌───────────────────────────────┴───────┐
                              ▼                                       ▼
                        [勝利画面]                              [敗北画面]
                              │                                       │
                              │                             ┌─────────┴─────────┐
                              │                             ▼                   ▼
                              │                          復活              諦める
                              │                             │                   │
                              │                             ▼                   │
                              │                       [ゲーム継続]               │
                              └─────────────────────────────┴───────────────────┘
                                                            ▼
                                                      [ホーム画面]
```

#### タスク一覧

| # | 画面 | 状態 | 内容 | 備考 |
|---|------|------|------|------|
| 1 | タイトル画面 | ✅完了 | STARTボタン | パーティクルアニメーション付き |
| 2 | ホーム画面 | ✅完了 | GAME STARTボタン | 将来：ガチャ、ショップ等追加予定 |
| 3 | ステージ選択画面 | ✅完了 | ステージ1のみ選択可能 | ステージ2-3はCOMING SOON |
| 4 | ルール画面 | ✅完了 | ゲームルール説明 | 「今後表示しない」チェックボックス |
| 5 | 勝利画面改修 | ✅完了 | 「ホームに戻る」ボタン追加 | ゴールド配色、ResetGame対応 |
| 6 | 敗北画面改修 | ✅完了 | 「諦める」ボタン追加 | LOSEテキスト、ResetGame対応 |
| 7 | GameController改修 | ✅完了 | StartGame/ResetGame対応 | gameActiveフラグ追加 |

#### デザイン方針
- ホラーアクション風の色合い（ダーク背景、赤/紫アクセント）
- 背景画像は将来対応（今は色ベース）
- レスポンシブ対応必須（スマホ考慮）
- ボタンは上寄り配置（スマホ操作しやすく）

---

### フェーズ6: UI改善（優先度：中）
1. HP地点クールダウン表示（画面UI）
2. ミニマップ

### フェーズ7: マルチ対応（優先度：低）
1. 鬼HPスケーリング（人数 × α）
2. 途中参加/離脱対応

### フェーズ8: 追加機能（優先度：低）
1. アイテムシステム
2. スキルシステム
3. ガチャシステム

---

## 開発ルール・注意事項

### コーディング規則

1. **静的関数 vs インスタンスメソッド**
   - 静的: `Module.FunctionName()` - シングルトン管理用
   - インスタンス: `Module:MethodName()` - オブジェクト操作用
   - **同じ名前を使わない**

2. **命名規則**
   - モジュール: PascalCase (例: `OniAI`, `HPPointManager`)
   - 関数/メソッド: PascalCase (例: `HandleHPPointAttack`)
   - 変数: camelCase (例: `activeOni`, `pathRetryTimer`)
   - 定数: UPPER_SNAKE_CASE (例: `AGENT_PARAMS`)

3. **モジュール間連携**
   - 循環参照を避けるため遅延ロード（lazy loading）を使用
   - 例: `local function getSafeZoneManager() ... end`

4. **可変引数の扱い**
   - ネスト関数内では`...`を直接使用しない
   - `local args = {...}` → `unpack(args)`を使用

### フォルダ構造ルール

1. **Workspace**
   - 全ての配置物は適切なフォルダに入れる
   - 「Model」という名前を使わない
   - 識別可能な名前をつける

2. **ServerScriptService**
   - KanKeri/Modules: モジュールスクリプト
   - KanKeri/Controllers: 実行スクリプト
   - Legacy: 未使用だが残すもの

3. **ReplicatedStorage**
   - KanKeri/Config: 設定
   - KanKeri/Modules: クライアント用モジュール
   - KanKeri/Events: RemoteEvents
   - Legacy: 未使用アセット

### 変更時の確認事項

- [ ] 関数名の重複がないか
- [ ] 依存するモジュールへの影響
- [ ] イベント名の一致
- [ ] デバッグログの削除
- [ ] 構文エラーチェック（loadstring）
- [ ] 既存機能への影響確認

---

## 参考リンク

- ゲーム概要: [ゲーム概要.md](./ゲーム概要.md)
- 開発記録: [開発記録.md](./開発記録.md)
- タスク一覧: [Task.md](./Task.md)

---

---

## ゲームテキスト

### ルール説明画面

```
━━━━━━━━━━━━━━━━━━━━━━━
   呪われた街からの脱出
━━━━━━━━━━━━━━━━━━━━━━━

深夜、あなたは謎の街に迷い込んだ。
街には"鬼"が徘徊している。
見つかれば、逃げ切ることは難しい。

唯一の希望は、街のどこかに浮かぶ「魂の炎」。
炎を攻撃すれば、鬼にダメージを与えられる。

ただし、炎も安全地帯も、
毎回違う場所に現れる。
自分の目で探し出せ。

━━━━━━ 生き残るために ━━━━━━

  🔥 魂の炎を探して攻撃せよ
     → 鬼のHPを0にすれば勝利
     → 攻撃後、炎は別の場所へ移動する

  🟢 緑の光を見つけて隠れろ
     → 安全ゾーン（10秒間だけ）
     → 長居すると消えて別の場所へ

  💀 鬼に捕まるな
     → 3回でゲームオーバー

━━━━━━━━━━━━━━━━━━━━━━━
```

---

*最終更新: 2026年1月12日 01:40（ゲームリセット問題対応中）*
