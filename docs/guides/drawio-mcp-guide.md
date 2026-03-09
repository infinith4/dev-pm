# Draw.io MCP 利用ガイド

## 概要

Draw.io MCP は、Claude Code から draw.io（diagrams.net）形式の図を作成・編集できる MCP サーバーである。
自然言語の指示で `.drawio` / `.drawio.svg` ファイルを生成でき、設計書やドキュメントに添付する図の作成を効率化する。

## 設定

### MCP サーバー設定

`.claude/mcp.json` に以下の設定が定義済み：

```json
{
  "mcpServers": {
    "drawio": {
      "command": "npx",
      "args": ["-y", "drawio-mcp"]
    }
  }
}
```

### 事前キャッシュ

`.devcontainer/postCreate.sh` で初回起動を高速化するためにキャッシュ済み：

```bash
npx -y drawio-mcp --help 2>/dev/null || true
```

## 提供ツール

Draw.io MCP が接続されると、以下の `mcp__drawio__` プレフィックスのツールが利用可能になる。

| ツール | 説明 |
|--------|------|
| `new_diagram` | 新しい `.drawio.svg` ファイルを作成する |
| `add_nodes` | ダイアグラムにノードを追加する |
| `edit_nodes` | 既存ノードの位置・サイズ・ラベルを編集する |
| `link_nodes` | ノード間の接続線（エッジ）を作成する |
| `remove_nodes` | ノードを削除する |
| `get_diagram_info` | ダイアグラムの XML 表現を取得する |

### ツールの制約

`add_nodes` で指定できる `kind`（シェイプ）は **基本図形のみ**：

```
Rectangle, RoundedRectangle, Square, Ellipse, Circle,
Cloud, Cylinder, Step, Actor, Text
```

> **重要**: Azure / AWS / GCP などのクラウドアイコン（ステンシル）は `kind` パラメータでは指定できない。
> クラウドアイコンを使用する場合は、後述の「XML 直接編集方式」を使用する。

---

## 作成方式の選択

### 方式 1: MCP ツール方式（基本図形のみ）

**適用場面**: フロー図、ER 図、シーケンス図など、基本図形で十分な図

```
drawio MCP でシステム構成図を作成して。
```

- メリット: 手軽、MCP ツールで段階的に構築可能
- デメリット: クラウドアイコンを使用できない

### 方式 2: XML 直接編集方式（クラウドアイコン対応）

**適用場面**: Azure / AWS / GCP のアイコンを使用するインフラ構成図

```
drawio MCP で Azure のアイコンを利用してシステム構成図を作成して。
SVG ファイルの XML を直接編集して Azure のシェイプスタイルを埋め込んで。
```

- メリット: クラウド公式アイコンを含む高品質な図を作成可能
- デメリット: XML の知識が必要、Claude Code の Write ツールで `.drawio` ファイルを直接生成

---

## インプットの準備

### 作成しやすいインプット一覧

システム構成図を効率的に作成するには、以下の情報を事前に整理しておくと品質が向上する。

| 優先度 | インプット | 具体例 | 効果 |
|--------|-----------|--------|------|
| **必須** | 使用クラウドサービス一覧 | Azure Front Door, Container Apps, PostgreSQL, Service Bus | ノードの種類と数が確定する |
| **必須** | コンポーネント間の接続関係 | FastAPI → PostgreSQL（テナント別接続）、Batch → Service Bus（ポーリング） | エッジの方向とラベルが確定する |
| **推奨** | グループ/レイヤー構成 | Edge Network層、Application層、Data層、External層 | グループ枠の設計ができる |
| **推奨** | データフローの方向 | ユーザー → Front Door → App → DB（上から下）| レイアウト方針が決まる |
| **推奨** | 非機能要件 | DR 構成、リージョン情報、SLA 要件 | DR/監視ノードの追加判断ができる |
| **あると良い** | 既存の SRS / 基本設計書 | `docs/pm/example_multitenant_ec/SRS.md` | Claude が自動でサービス一覧を抽出する |
| **あると良い** | 線の種類の区別 | 実線=データフロー、破線=監視/シークレット | 凡例付きの見やすい図になる |

### 最小限のプロンプト例

```
docs/pm/example_multitenant_ec についてシステム構成図を Drawio MCP で作成して。
Azure のアイコンを利用してください。
```

> Claude が SRS や設計書を自動で読み取り、サービス構成を推定して図を生成する。
> ただし、事前に構成要素を明示した方が精度は高い。

### 詳細なプロンプト例

```
以下のシステム構成図を Draw.io で作成してください。Azure 公式アイコンを使用。

■ レイヤー構成（上から下）
1. Edge Network: Azure Front Door + WAF + DDoS Protection
2. Application: React EC Site, React Admin, FastAPI Backend, Azure Batch Worker
3. Messaging: Azure Service Bus (order-batch-queue, factory-transfer-queue)
4. Data: PostgreSQL Flexible Server (テナント別), Blob Storage
5. External: Stripe, SFTP Server, Factory Webhook

■ 右カラム（横並び）
- Identity: Microsoft Entra ID, External Identities (CIAM)
- Security: Azure Key Vault
- Monitoring: Azure Monitor, Application Insights
- DR: Azure Japan West

■ 接続ルール
- 実線: データフロー
- 破線: シークレット取得、監視、DR レプリケーション
- 色分け: Queue=紫、DB=青、認証=橙、決済=紫青

■ 注意事項
- 線が重ならないように waypoints を使用
- exitX/exitY/entryX/entryY で接続点を制御
```

---

## Azure 公式アイコンの使い方

### 仕組み

Draw.io は `img/lib/azure2/` 配下に Azure 公式アイコンの SVG を内蔵している。
ノードの `style` 属性に `image=img/lib/azure2/...` を指定することでアイコンが表示される。

### スタイル構文

```xml
<mxCell id="node-id"
  value="表示ラベル"
  style="aspect=fixed;html=1;points=[];align=center;image;fontSize=11;image=img/lib/azure2/{category}/{IconName}.svg;"
  vertex="1" parent="1">
  <mxGeometry x="100" y="100" width="48" height="48" as="geometry" />
</mxCell>
```

### Azure アイコンパス一覧

#### Networking

| サービス | パス |
|---------|------|
| Front Door | `img/lib/azure2/networking/Front_Doors.svg` |
| WAF | `img/lib/azure2/networking/Web_Application_Firewall_Policies_WAF.svg` |
| DDoS Protection | `img/lib/azure2/networking/DDoS_Protection_Plans.svg` |
| Application Gateway | `img/lib/azure2/networking/Application_Gateways.svg` |
| Load Balancer | `img/lib/azure2/networking/Load_Balancers.svg` |
| Virtual Network | `img/lib/azure2/networking/Virtual_Networks.svg` |
| DNS Zone | `img/lib/azure2/networking/DNS_Zones.svg` |

#### Compute

| サービス | パス |
|---------|------|
| Container Instances | `img/lib/azure2/compute/Container_Instances.svg` |
| Batch Accounts | `img/lib/azure2/compute/Batch_Accounts.svg` |
| Virtual Machine | `img/lib/azure2/compute/Virtual_Machine.svg` |
| App Service | `img/lib/azure2/app_services/App_Services.svg` |
| Function Apps | `img/lib/azure2/compute/Function_Apps.svg` |
| Kubernetes Service | `img/lib/azure2/compute/Kubernetes_Services.svg` |
| Container Registry | `img/lib/azure2/containers/Container_Registries.svg` |

#### Databases

| サービス | パス |
|---------|------|
| PostgreSQL Server | `img/lib/azure2/databases/Azure_Database_PostgreSQL_Server.svg` |
| MySQL Server | `img/lib/azure2/databases/Azure_Database_MySQL_Server.svg` |
| SQL Database | `img/lib/azure2/databases/SQL_Database.svg` |
| Cosmos DB | `img/lib/azure2/databases/Azure_Cosmos_DB.svg` |
| Cache for Redis | `img/lib/azure2/databases/Cache_Redis.svg` |

#### Storage

| サービス | パス |
|---------|------|
| Storage Accounts | `img/lib/azure2/storage/Storage_Accounts.svg` |
| Blob Block | `img/lib/azure2/storage/Blob_Block.svg` |
| Data Lake Storage | `img/lib/azure2/storage/Data_Lake_Storage.svg` |

#### Integration

| サービス | パス |
|---------|------|
| Service Bus | `img/lib/azure2/integration/Service_Bus.svg` |
| Event Grid | `img/lib/azure2/integration/Event_Grid_Domains.svg` |
| API Management | `img/lib/azure2/integration/API_Management_Services.svg` |
| Logic Apps | `img/lib/azure2/integration/Logic_Apps.svg` |

#### Identity

| サービス | パス |
|---------|------|
| Azure Active Directory | `img/lib/azure2/identity/Azure_Active_Directory.svg` |
| External Identities | `img/lib/azure2/identity/External_Identities.svg` |
| Managed Identities | `img/lib/azure2/identity/Managed_Identities.svg` |

#### Security

| サービス | パス |
|---------|------|
| Key Vault | `img/lib/azure2/security/Key_Vaults.svg` |
| Application Security Groups | `img/lib/azure2/security/Application_Security_Groups.svg` |

#### Management / Monitoring

| サービス | パス |
|---------|------|
| Monitor | `img/lib/azure2/management_governance/Monitor.svg` |
| Application Insights | `img/lib/azure2/devops/Application_Insights.svg` |
| Log Analytics | `img/lib/azure2/management_governance/Log_Analytics_Workspaces.svg` |

#### AI / Machine Learning

| サービス | パス |
|---------|------|
| Cognitive Services | `img/lib/azure2/ai_machine_learning/Cognitive_Services.svg` |
| Machine Learning | `img/lib/azure2/ai_machine_learning/Machine_Learning.svg` |

#### General

| サービス | パス |
|---------|------|
| User | `img/lib/azure2/general/User.svg` |
| Globe | `img/lib/azure2/general/Globe.svg` |
| Resource Group | `img/lib/azure2/general/Resource_Groups.svg` |

> **アイコンパスの命名規則**: カテゴリ名はスネークケース、アイコン名はパスカルケース + アンダースコア区切り。
> 例: `azure2/networking/Front_Doors.svg`

---

## 線の重なりを防ぐテクニック

### 問題

ノード数が多い図（10+ノード）では、orthogonal（直角）ルーティングの接続線が重なりやすい。
特に、1 つのノードから多数の接続が出る場合（例: FastAPI Backend → 10+ サービス）に顕著。

### 解決策 1: exitX / exitY / entryX / entryY で接続点を制御

ノードの上下左右の **どの位置** から線を出す/入れるかを制御する。

```xml
<!-- FastAPI の左辺中央から出て、Redis の上辺中央に入る -->
<mxCell style="...exitX=0;exitY=0.5;entryX=0.5;entryY=0;"
  source="fastapi" target="redis" edge="1" parent="1">
```

| 値 | 位置 |
|----|------|
| `exitX=0; exitY=0.5` | 左辺の中央 |
| `exitX=1; exitY=0.5` | 右辺の中央 |
| `exitX=0.5; exitY=0` | 上辺の中央 |
| `exitX=0.5; exitY=1` | 下辺の中央 |
| `exitX=0; exitY=0` | 左上角 |
| `exitX=1; exitY=1` | 右下角 |

同じノードから複数の線が出る場合、 **exit 位置をずらす**：

```xml
<!-- FastAPI → Redis: 左辺上部から出る -->
<mxCell style="...exitX=0;exitY=0.25;" source="fastapi" target="redis" ...>

<!-- FastAPI → Search: 左辺下部から出る -->
<mxCell style="...exitX=0;exitY=0.75;" source="fastapi" target="search" ...>
```

### 解決策 2: waypoints（中間点）で明示的にルーティング

`<Array as="points">` で中間点を指定し、線を迂回させる。

```xml
<!-- FastAPI(x=490) → Stripe(x=100): 左端(x=40)を迂回して下降 -->
<mxCell style="edgeStyle=orthogonalEdgeStyle;..."
  source="fastapi" target="stripe" edge="1" parent="1">
  <mxGeometry relative="1" as="geometry">
    <Array as="points">
      <mxPoint x="490" y="420" />  <!-- FastAPI の下で左に曲がる -->
      <mxPoint x="40" y="420" />   <!-- 図の左端を通過 -->
      <mxPoint x="40" y="838" />   <!-- 左端を下降 -->
      <mxPoint x="100" y="838" />  <!-- Stripe に到達 -->
    </Array>
  </mxGeometry>
</mxCell>
```

### 解決策 3: レイアウト設計のパターン

#### パターン A: 垂直レーン方式

接続が多いノードの下に、そのノードが主に接続する先を **縦に並べる**。

```
FastAPI(x=490)          Batch(x=790)
    |                       |
Redis(x=130) Search(x=330)  FactoryQ(x=790)  ← 同じ x 座標で縦直線
    |                       |
PG-T(x=130) PG-P(x=350)   Blob(x=570)
```

#### パターン B: 外縁迂回方式

遠いノード間の接続は **図の外縁（左端 x=30〜40 や右端）** を通して迂回する。
内部の線との交差を完全に回避できる。

```
FastAPI → Stripe : x=40 (左端) を経由
Batch → Stripe   : x=30 (さらに左) を経由 ← 2本が重ならない
Webhook → FastAPI: x=950 (右端) を経由
```

#### パターン C: 右カラム分離方式

認証・セキュリティ・監視など **横断的関心事** は右カラムにまとめ、
メインフロー（上から下）と分離する。

```
[メインフロー (x=60〜900)]    [横断的関心事 (x=1020〜1280)]
 Front Door                    Identity (Entra ID, CIAM)
 App Layer                     Security (Key Vault)
 Queue / Cache                 Monitoring (Monitor, App Insights)
 Data Layer                    DR (Japan West)
 External Systems
```

### 解決策 4: 同じノードへの複数接続を分離

**FastAPI → PG-Tenant** と **Batch → PG-Tenant** のように、
異なるソースから同じターゲットへの接続は **異なる x/y ルート** を使う。

```xml
<!-- FastAPI → PG-Tenant: 左端(x=80)経由 -->
<mxCell source="fastapi" target="pg-tenant" ...>
  <Array as="points">
    <mxPoint x="80" y="364" />
    <mxPoint x="80" y="684" />
  </Array>
</mxCell>

<!-- Batch → PG-Tenant: x=770 で下降後、y=600 で左に横断 -->
<mxCell source="batch-worker" target="pg-tenant" ...>
  <Array as="points">
    <mxPoint x="770" y="364" />
    <mxPoint x="770" y="600" />
    <mxPoint x="154" y="600" />
  </Array>
</mxCell>
```

---

## グループ枠（背景ボックス）の作り方

サービスを論理グループとしてまとめる枠は `fillColor` + `verticalAlign=top` で作成する。

```xml
<mxCell id="grp-app"
  value="Azure Container Apps (Shared Application Layer)"
  style="rounded=1;whiteSpace=wrap;html=1;
    fillColor=#E8F5E9;strokeColor=#4CAF50;
    fontStyle=1;fontSize=12;verticalAlign=top;
    arcSize=8;strokeWidth=2;"
  vertex="1" parent="1">
  <mxGeometry x="60" y="300" width="880" height="120" as="geometry" />
</mxCell>
```

### 推奨カラースキーム

| グループ | fillColor | strokeColor | 用途 |
|---------|-----------|-------------|------|
| Edge Network | `#E6F2FF` | `#0078D4` | CDN, WAF, DDoS |
| Application | `#E8F5E9` | `#4CAF50` | App Service, Container |
| Identity | `#FFF3E0` | `#FF9800` | Entra ID, CIAM |
| Cache / Search | `#FCE4EC` | `#E91E63` | Redis, Cognitive Search |
| Messaging | `#EDE7F6` | `#673AB7` | Service Bus, Event Grid |
| Data | `#E3F2FD` | `#1565C0` | PostgreSQL, Blob Storage |
| Security | `#FFF8E1` | `#F9A825` | Key Vault |
| Monitoring | `#E8EAF6` | `#3F51B5` | Monitor, App Insights |
| External | `#F3E5F5` | `#9C27B0` | Stripe, SFTP, Webhook |

---

## 接続線の色分け

接続線もグループに合わせて色分けすると可読性が向上する。

```xml
<!-- Queue パイプライン: 紫、太線 -->
<mxCell style="...strokeColor=#673AB7;strokeWidth=2;" ...>

<!-- Database アクセス: 濃青 -->
<mxCell style="...strokeColor=#1565C0;" ...>

<!-- 認証: 橙 -->
<mxCell style="...strokeColor=#FF9800;strokeWidth=1.5;" ...>

<!-- 決済 (Stripe): 紫青 -->
<mxCell style="...strokeColor=#635BFF;strokeWidth=1.5;" ...>

<!-- シークレット / 監視 / DR: 破線 -->
<mxCell style="...strokeColor=#F9A825;dashed=1;strokeWidth=1.5;" ...>
```

---

## 完全な XML テンプレート

Azure アイコン付きシステム構成図の最小テンプレート：

```xml
<mxfile>
  <diagram id="arch" name="System Architecture">
    <mxGraphModel dx="1600" dy="1200" grid="1" gridSize="10" guides="1"
      tooltips="1" connect="1" arrows="1" fold="1" page="0"
      pageScale="1" pageWidth="1600" pageHeight="1200" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />

        <!-- グループ枠 -->
        <mxCell id="grp-app" value="Application Layer"
          style="rounded=1;whiteSpace=wrap;html=1;fillColor=#E8F5E9;strokeColor=#4CAF50;fontStyle=1;fontSize=12;verticalAlign=top;arcSize=8;strokeWidth=2;"
          vertex="1" parent="1">
          <mxGeometry x="60" y="100" width="400" height="120" as="geometry" />
        </mxCell>

        <!-- Azure アイコンノード -->
        <mxCell id="webapp" value="Web App"
          style="aspect=fixed;html=1;points=[];align=center;image;fontSize=11;image=img/lib/azure2/app_services/App_Services.svg;"
          vertex="1" parent="1">
          <mxGeometry x="100" y="130" width="48" height="48" as="geometry" />
        </mxCell>

        <mxCell id="db" value="PostgreSQL"
          style="aspect=fixed;html=1;points=[];align=center;image;fontSize=11;image=img/lib/azure2/databases/Azure_Database_PostgreSQL_Server.svg;"
          vertex="1" parent="1">
          <mxGeometry x="100" y="300" width="48" height="48" as="geometry" />
        </mxCell>

        <!-- 接続線 (waypoints 付き) -->
        <mxCell style="edgeStyle=orthogonalEdgeStyle;rounded=1;orthogonalLoop=1;html=1;strokeColor=#1565C0;fontSize=10;exitX=0.5;exitY=1;entryX=0.5;entryY=0;"
          value="Query" edge="1" parent="1" source="webapp" target="db">
          <mxGeometry relative="1" as="geometry" />
        </mxCell>

      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

---

## プロンプト集

### Azure システム構成図の作成

```
docs/pm/{project} についてシステム構成図を Drawio MCP で作成して。
Azure のアイコンを利用してください。
```

### Azure アイコンの埋め込み指示

```
SVG ファイルの XML を直接編集して Azure のシェイプスタイルを埋め込んで。
```

### 線の重なり修正

```
線が重ならないようにして。
exitX/exitY/entryX/entryY で接続点を制御し、
waypoints で迂回ルートを設定して。
```

### 既存図へのノード追加

```
{file}.drawio にキャッシュサーバー（Redis）を追加して。
Azure Cache for Redis のアイコンを使用し、
API サーバーと DB の間に配置して。
```

### 色分けの指示

```
グループ枠ごとに色分けして。
接続線も役割ごとに色を変えて（DB=青、Queue=紫、認証=橙、監視=破線）。
凡例（Legend）も追加して。
```

---

## 推奨する保存先

| 図の種類 | 保存先 |
|---------|--------|
| システム構成図 | `docs/design/basic/` |
| シーケンス図・クラス図 | `docs/design/detailed/` |
| 画面遷移図・ワイヤーフレーム | `docs/ui-specs/` |
| 業務フロー図 | `docs/pm/` |
| API 構成図 | `docs/api/` |
| コンテキスト図 | `docs/requirements/` |

---

## トラブルシューティング

| 症状 | 原因 | 対処法 |
|------|------|--------|
| MCP ツールが表示されない | MCP サーバー未起動 | Claude Code を再起動する |
| `npx drawio-mcp` が失敗する | npm キャッシュ破損 | `npm cache clean --force` 後に再試行 |
| Azure アイコンが表示されない | MCP の `kind` で指定している | XML 直接編集方式に切り替える |
| 線が重なる | orthogonal ルーティングの自動配置 | waypoints と exit/entry 指定を追加 |
| 生成された図が期待と異なる | インプット不足 | 構成要素・接続関係・レイヤーを明示する |
| `.drawio.svg` でアイコンが出ない | SVG 埋め込み形式の制約 | `.drawio` 形式で作成し VS Code 拡張で開く |

## 関連ドキュメント

- [基本設計書の配置先](../design/basic/) — システム構成図等
- [詳細設計書の配置先](../design/detailed/) — シーケンス図、クラス図等
- [画面仕様書の配置先](../ui-specs/) — 画面遷移図等
- [実例: ShopHub SaaS 構成図](../pm/example_multitenant_ec/system-architecture-azure.drawio) — Azure アイコン付き構成図
