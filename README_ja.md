# UAMotionLinkLib
**UAMotionLinkLib**は、OMRON社のNX/NJコントローラにおいてモーション操作インターフェースを外部に提供するライブラリです。
モーションファンクションブロック(モーションFB)のラッパーをコントローラまたは、シミュレータのOPC UAサーバで公開し、OPC UAクライアントを介したモーション操作を可能にします。
**UAMotionLinkLib**は、[PseudoUAMethodExample](https://github.com/kmu2030/PseudoUAMethodExample)で示す疑似UA MethodとしてモーションFB操作を公開します。
また、[PwshOpcUaClient](https://github.com/kmu2030/PwshOpcUaClient)を使用したリファレンスクライアント(**SingleMCController**)とテストを含みます。

現在、公開するモーションFBは、基本的な位置決め動作に限定しています。
サーボ運転可否(`MC_Power`)、減速停止(`MC_Stop`)及び停止(`MC_ImmediateStop`)は提供していません。
また、継続動作、同期動作、多軸協調動作も提供していません。
ユーザーが機能を拡張することは容易です。不足があればユーザーの判断で拡張してください。
UAMotionLinkは、以下の操作を提供します。

*  **MoveAbsolute**   
   操作対象である軸について絶対座標による位置決めを行います。
   パラメータは、`MC_MoveAbsolute`に同じです。
*  **MoveRelative**   
   操作対象である軸について相対座標による位置決めを行います。
   パラメータは、`MC_MoveRelative`に同じです。
*  **MoveZeroPosition**   
   操作対象である軸を原点に戻します。
   パラメータは、`MC_MoveZeroPosition`に同じです。
*  **Home**   
   操作対象である軸について原点を決めます。
   パラメータは、`MC_Home`に同じです。
*  **SetPosition**   
   操作対象である軸の現在指令位置とフィードバック現在位置を任意の値に変更します。
   パラメータは、`MC_SetPosition`に同じです。
*  **ResetAxisError**   
   操作対象である軸の異常を解除します。
   `MC_Reset`のラッパーです。
*  **SetAxisIndex**   
   操作対象とする軸をインデックスで指定します。
*  **AxisIndex**   
   現在操作対象としている軸のインデックスを取得します。
*  **Axis**
   操作対象である軸の`_sAXIS_REF`構造体を取得します。

リファレンスクライアントは、上記を操作する機能を提供します。
ヒトも問題無く使用できますが、AI ShellとチャットAI、あるいは、AIエージェントが使用することを目的に開発しているため、冗長である可能性があります。
現在のところMCPサーバーを作成する予定はありません。

## 使用環境
ライブラリ(`UAMotionLinkLib`)の使用には、以下が必要です。

| Item          | Requirement |
| :------------ | :---------- |
| Controller    | NX1(Ver.1.64以降), NX5(Ver.1.64以降), NX7(Ver.1.35以降), NJ5(Ver.1.63以降) |
| Sysmac Studio | Ver.1.62以降 |

リファレンスクライアント(`SingleMCController`)の使用には、以下が必要です。

| Item          | Requirement |
| :------------ | :---------- |
| PowerShell    | 7.5以降 |

## 構築環境
UAMotionLinkLibとSingleMCControllerは、以下の環境で構築しています。

| Item            | Version              |
| :-------------- | :------------------- |
| Controller      | NX102-9000 Ver.1.64 HW Rev.A |
| Sysmac Studio   | Ver.1.63 |
| PowerShell      | 7.5.2 |
| Pester          | 5.7.1 |

## ライブラリの構成
UAMotionLinkLibは、以下で構成します。

* **UAMotionLinkLib.slr**   
   Sysmacプロジェクト用ライブラリです。
   プロジェクトで参照して使用します。

* **UAMotionLinkLib.smc2**   
  UAMotionLinkLib開発用のSysmacプロジェクトです。   
  リファレンスクライアントのテストプログラムを含みます。

## ライブラリの使用手順
ライブラリは、以下の手順で使用します。

1. **UAMotionLinkLib.slrをプロジェクトで参照する**

2. **プロジェクトをビルドしてエラーが無いことを確認する**   
   プロジェクト内の識別子と衝突が生じていないことを確認します。

3. **BasicMCControllerModel FB(モデルFB)を適当なプログラムPOUで実行する**   
   モーションFBを含むため、プログラムPOUはプライマリタスクでの実行が必要です。

4. **OPC UA設定でモデルFBを公開**   
   FBインスタンスの公開設定は、メーカーのマニュアルを参照してください。
   各メソッドに適切なユーザーロールを指定してください。

## リファレンスクライアントの構成
リファレンスクライアントの主な構成物は以下です。

* **BasicMCController.ps1**   
  リファレンスクライアント本体です。

* **BasicMCController.Tests.ps1**   
  `Pester`と`UAMotionLinkLib.smc2`を使用するリファレンスクラアインとモデルのテストです。   

* **ModelTestController.ps1**   
  `UAMotionLinkLib.smc2`で動作するテストプログラムを操作します。

* **SingleMCController.ps1**   
  AIエージェントに参照させることを目的にしたBasicMCControllerの派生クラスを定義しています。

* **SingleMCController.psm1**   
  リファレンスクライアントのモジュールです。
  リファレンスクライアントを使用する場合、このファイルをインポートします。

* **PwshOpcUaClient/**   
   PwshOpcUaClientです。
   使用方法は、[PwshOpcUaClient](https://github.com/kmu2030/PwshOpcUaClient)を参照します。

## リファレンスクライアントの使用手順
リファレンスクライアントは、テスト及び例示で使用しています。
リファレンスクライアントの使用手順の概略は、以下です。

1. **SingleMCController.psm1のインポート**

2. **リファレンスクライアントを使用するコードの実行**

セキュリティ機能を有効にしたOPC UAサーバへの初回接続時は、コネクションの確立に失敗する場合があります。
これは、PwshOpcUaClientのクライアント証明書をOPC UAサーバが拒否するためです。
拒否された場合、OPC UAサーバでクライアント証明書を許可することで次回から拒否されなくなります。

## 例示について
例示は、`examples\`にあります。
詳細は、各ディレクトリを確認してください。

* **ControlWithAIShell**   
   [AI Shell](https://learn.microsoft.com/ja-jp/powershell/utility-modules/aishell/overview?view=ps-modules)を中継としてチャットAIに指示、あるいは共同でサーボ操作を行います。
   AI Shellを介して以下のようにサーボを操作できます。

   ![AI Shellを介したサーボ操作](./images/control-with-ai-shell.gif)

## ライセンスについて
**PwshOpcUaClient**を使用するコードは、GPLv2ライセンスです。
その他は、MITライセンスです。
