# SingleMCController
SingleMCControllerは、コントローラまたは、シミュレータのOPC UAサーバが公開するBasicMCControllerModelを操作するためのPowerShellクライアントです。
SingleMCControllerは、指定したサーボ軸についての基本的な操作インターフェースを提供します。
SingleMCControllerは、そのインターフェースを使用してPowerShellからサーボ軸を操作する機能を提供します。
SingleMCControllerは、試運転や調整のための軽微なサーボ操作を目的にしています。運転を目的にしたサーボ制御には使用しないでください。
また、サーボ動作に係るリスク、特に不完全な動作や意図しない動作によって生じるリスクを十分に評価し、許容できるリスク程度となるよう軽減策を講じてください。
実機で使用する前にシミュレータで使用手順、正常に機能すること、異常時の振る舞いを確認することを推奨します。

# 使い方
1. PwshOpcUaClientのセットアップ   
   [PwshOpcUaClient](https://github.com/kmu2030/PwshOpcUaClient)を参照します。

2. クライアントのロード   
   `./SingleMCController.psm1`をインポートします。

   ```powershell
   Import-Module ./SingleMCController
   ```

3. クライアントの生成   
   以下のコマンドレットでクライアントを生成します。`.env`をセッションにロードして必要な情報を提供するものとします。

   ```powershell
   Import-Env
   $controller = New-SingleMCController
   ```

4. クライアントの使用   
   クライアントを生成したら、メソッドを使用してモーション操作を行います。
   以下のスクリプトは、絶対座標による位置決めを行います。

    ```powershell
    # 操作するサーボ軸をインデックスで指定します。
    $axisIndex = 0
    $ok = $controller.SetAxisIndex($axisIndex)
    $prevPos = $controller.Axis().Act.Pos
    # モーション操作は、タスクオブジェクトを生成します。
    $position = 100.0
    $moveTask = $controller.MoveAbsolute({
        Position     = $position
        Velocity     = 10.0
        Acceleration = 2.0
        Deceleration = 2.0
        Jerk         = 0.0
        Direction    = 0
        BufferMode   = 0
    })

    # タスクオブジェクトのExecuteを実行すると、モーションを開始します。
    $moveTask.Execute()

    # タスクの実行状況は、CheckDoneを実行して確認します。
    # Trueが返って来た時点でタスクは完了です。
    # モーションが完了するか、Cancelを実行するまでタスクは継続します。
    # Cancelを実行することで、タスクは完了しますがモーションは継続します。
    while (-not $moveTask.CheckDone()) { Start-Sleep -Milliseconds 300 }

    # タスクが完了したら、結果を取得します。
    # タスク結果は、以下を要素に持つhashtableです。
    # * [bool]Error: エラーが発生したかどうか、Trueはエラー有。
    # * [uint16]ErrorID: エラーID。
    # * [bool]CommandAborted: 命令が中止されたかどうか、Trueは中止。
    $result = $moveTask.GetResult()

    # 使用したタスクは必ずDisposeを実行して破棄します。
    $moveTask.Dispose()

    # モーションを正常に完了していれば、指定した位置を指します。
    $axis = $controller.Axis().Act.Pos
    $ok = ([Math]::Abs(($axis.Act.Pos - $prevPos) - $distance) -lt 0.0001) -and $axis.Status.Standstill
    ```

5. クライアントの破棄   
   クライアントの使用が終了したら、以下のように破棄します。

   ```powershell
   $controller.Dispose()
   ```

   クライアントはリソースを保持しているため、必ず実行します。
   