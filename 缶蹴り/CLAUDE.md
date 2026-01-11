# 缶蹴りゲーム - Claude Code 総合ドキュメント

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

---

## プロジェクト概要

### ゲームコンセプト
缶蹴りの構造を現代化した「**高速鬼（NPC）から逃げつつ、HP地点を攻撃して鬼HPを0にする**」スリル型ゲーム。

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
- [x] HP地点（魂の炎ビジュアル、10秒クールダウン）
- [x] 安全ゾーン（緑の円柱、10秒滞在制限）
- [x] 武器システム（素手/剣、エフェクト分離）
- [x] 鬼AI（PathfindingService、状態マシン）
- [x] UI（鬼HPゲージ、勝利演出）
- [x] 発見演出（！マーク）
- [x] 警告UI（「鬼が戻ってくるぞ！」）

### 未実装機能
- [ ] プレイヤーHP（初期3、被ダメージ処理）
- [ ] 復帰システム（ダイヤ消費）
- [ ] プレイヤーUI（HP表示、復帰ボタン）
- [ ] マルチプレイ対応（HPスケーリング）

### 現在のバグ・課題
| 状態 | 内容 |
|------|------|
| 調査中 | 鬼がHP地点に戻らない場合がある（RETURNING状態の問題） |

---

## エクスプローラー構造

### 2024年1月11日 リファクタリング後

```
Workspace/
├── Map/
│   ├── Buildings/ (22 items)
│   │   ├── AbandonedBuilding_01〜04
│   │   ├── AbandonedHouse_01〜08
│   │   ├── Building_01〜04
│   │   ├── OfficeBuilding_01〜03
│   │   └── LargeStructure_01〜03
│   ├── Props/ (5 items)
│   │   ├── Structure_01〜02
│   │   └── Prop_01〜03
│   └── Vehicles/ (5 items)
│       └── PoliceCar_01〜05
├── Enemy/
│   └── Enemy NPC (鬼)
├── PatrolPoints/ (12 items) - 鬼の巡回ルート
├── GoalPositions/ (10 items) - HP地点/安全ゾーン候補
└── HPPoints/ (ランタイム生成)

ServerScriptService/
├── KanKeri/
│   ├── Modules/
│   │   ├── OniAI (v5) - 鬼AI（状態マシン）
│   │   ├── OniHPManager - 鬼HP管理
│   │   ├── HPPointManager - HP地点管理
│   │   ├── SafeZoneManager - 安全ゾーン管理
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
│   │   └── AttackConfig - 攻撃エフェクト設定
│   └── Events/ (17 RemoteEvents)
│       ├── RoundStateChanged, RoundCountdown, RoundStarted, RoundEnded
│       ├── OniHPChanged, OniStateChanged, OniDiscoveredPlayer, OniWarning, OniDefeated
│       ├── PlayerHPChanged, PlayerDied, PlayerRevived
│       ├── HPPointCooldownUpdate, RequestAttackHPPoint
│       ├── RequestRevive, RequestStartRound
│       └── PlayAttackEffect
└── Legacy/
    └── Monsters/ - 未使用（旧モンスター）

StarterPlayer/
└── StarterPlayerScripts/
    ├── AttackEffectHandler - HP地点攻撃エフェクト
    ├── DiscoveryEffectHandler - 発見演出（！マーク）
    └── OniWarningHandler - 警告UI

StarterGui/
├── OniHPGui - 鬼HPゲージ
└── VictoryGui - 勝利演出
```

---

## モジュール設計

### OniAI v5 構造ガイド

```lua
-- ============================================================
-- [モジュール構造ガイド]
-- 静的関数 (OniAI.xxx): GetActiveOni, HandleHPPointAttack,
--   NotifyHPPointAttacked, NotifyOniDefeated
-- インスタンスメソッド (self:xxx): OnHPPointAttacked, Update,
--   SetState, Defeat, CatchPlayer, etc.
-- 重要: 静的(.)とインスタンス(:)を混同しないこと！
-- ============================================================
```

**シングルトン管理:**
- `activeOni` - 現在アクティブな鬼インスタンス
- `OniAI.GetActiveOni()` - インスタンス取得

**状態マシン:**
```
PATROL → (プレイヤー発見) → CHASE
CHASE → (HP地点攻撃/安全ゾーン) → STUNNED
STUNNED → (3秒後) → RETURNING
RETURNING → (HP地点到着) → PATROL
CHASE → (プレイヤー捕捉) → PATROL
任意状態 → (HP=0) → DEFEATED
```

### モジュール間の依存関係

```
GameController
    ├── RoundManager
    ├── HPPointManager ──→ OniHPManager
    │                  ──→ OniAI.HandleHPPointAttack()
    ├── SafeZoneManager
    └── OniAI ──→ OniHPManager (敗北時)

イベントフロー:
HP地点攻撃 → HPPointManager.AttackHPPoint()
          → PlayAttackEffect:FireClient() [エフェクト]
          → OniHPManager.Damage() [ダメージ]
          → OniAI.HandleHPPointAttack() [スタン]
```

---

## 既知の問題と解決履歴

### 2024年1月11日 修正

| # | 問題 | 原因 | 解決方法 |
|---|------|------|----------|
| 1 | 攻撃エフェクトが出ない | `OnHPPointAttacked`の名前衝突（静的/インスタンス） | 静的関数を`HandleHPPointAttack`にリネーム |
| 2 | 無限ループ発生 | 同名関数による再帰呼び出し | 名前を分離 |
| 3 | Path failed:NoPath スパム | パス計算リトライが無制限 | `PathRetryTimer`で0.5秒間隔に制限 |
| 4 | HPゲージ→エフェクトの順で表示 | 処理順序の問題 | `PlayAttackEffect`を`Damage`の前に移動 |
| 5 | 警告UIが出ない | 関数名衝突で`OnHPPointAttacked`が呼ばれない | 名前衝突を解消 |

### 根本原因（重要）

```lua
-- この2つは別物だが、Luaでは後者が前者を上書きする
function OniAI:OnHPPointAttacked()  -- インスタンスメソッド
function OniAI.OnHPPointAttacked()  -- 静的関数（これが上書き）
```

**教訓**: Luaでは静的関数(.)とインスタンスメソッド(:)に同じ名前を使うと上書きされる。命名規則で防ぐ必要がある。

---

## 今後の開発予定

### フェーズ4: プレイヤーシステム（優先度：高）
1. プレイヤーHP実装（初期3、被ダメージ処理）
2. 復帰システム（ダイヤ1消費でHP1で復活）
3. リスポーン位置の安全確保

### フェーズ5: UI追加（優先度：中）
1. プレイヤーHP表示
2. HP地点クールダウン表示
3. 復帰ボタン

### フェーズ6: マルチ対応（優先度：低）
1. 鬼HPスケーリング（人数 × α）
2. 途中参加/離脱対応

### 検討中の改善
- OniAIをOniManager（静的）とOniInstance（インスタンス）に分離
- エフェクトの調整
- バランス調整

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

3. **デバッグログ**
   - 開発中は`print("[ModuleName] message")`形式
   - リリース前に削除

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

---

## 参考リンク

- ゲーム概要: [ゲーム概要.md](./ゲーム概要.md)
- 開発記録: [開発記録.md](./開発記録.md)
- タスク一覧: [Task.md](./Task.md)

---

*最終更新: 2024年1月11日*
