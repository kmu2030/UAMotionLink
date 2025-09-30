using namespace Opc.Ua
using namespace Opc.Ua.Configuration
using namespace Opc.Ua.Client
using namespace Opc.Ua.Client.ComplexTypes

<#
.SYNOPSIS
    OPC UAサーバが公開するBasicMCControllerModelを介したサーボ操作を提供します。
.NOTES
    生成AI、AIエージェントへの情報として、メソッドにコメントベースのヘルプを記載しています。
#>
class SingleMCController : BasicMCController {
    SingleMCController([string]$BaseNodeId) : base($BaseNodeId) {}
    SingleMCController([string]$BaseNodeId, [string]$NodeSeparator) : base($BaseNodeId, $NodeSeparator) {}

    <#
    .SYNOPSIS
        現在対象としている軸の軸情報を取得します。
    .EXAMPLE
        $axis = $controller.Axis($session)
        # $axisは以下のプロパティを持ちます。
        # $axis.Cfg (object): 軸基本設定
        # $axis.Cfg.AxNo (uint16): 軸番号
        # $axis.Cfg.AxEnable: 軸使用
        # $axis.Cfg.AxType (enum): 軸種別
        # $axis.Cfg.NodeAddress (uint16): ノードアドレス
        # $axis.Scale (object): 単位変換設定
        # $axis.Scale.Num (uint32): モータ1回転のパルス数
        # $axis.Scale.Den (uint32): モータ1回転の移動量
        # $axis.Scale.Units (enum): 表示単位
        # $axis.Scale.CountMode (enum): カウントモード
        # $axis.Scale.MaxPos (double): 現在位置上限値
        # $axis.Scale.MinPos (double): 現在位置下限値
        # $axis.Status (object): 軸ステータス
        # $axis.Status.Ready (bool): 起動準備完了
        # $axis.Status.Disabled (bool): 無効化中
        # $axis.Status.Standstill (bool): 停止中
        # $axis.Status.Discrete (bool): 位置決め動作中
        # $axis.Status.Continuous (bool): 連続動作中
        # $axis.Status.Synchronized (bool): 同期動作中
        # $axis.Status.Homing (bool): 原点復帰中
        # $axis.Status.Stopping (bool): 減速停止中
        # $axis.Status.ErrorStop (bool): エラー減速停止中
        # $axis.Details (object): 軸制御ステータス
        # $axis.Details.Idle (bool): 停止中
        # $axis.Details.InPosWaiting (bool): インポジション待ち
        # $axis.Details.Homed (bool): 原点確定
        # $axis.Details.InHome (bool): 原点停止
        # $axis.Details.VelLimit (bool): 指令速度飽和
        # $axis.Dir (object): 指令方向ステータス
        # $axis.Dir.Posi (bool): 正方向指令中
        # $axis.Dir.Nega (bool): 負方向指令中
        # $axis.DrvStatus (object): サーボドライバ状態
        # $axis.DrvStatus.ServoOn (bool): サーボON
        # $axis.DrvStatus.Ready (bool): サーボレディ
        # $axis.DrvStatus.MainPower (bool): 主回路電源
        # $axis.DrvStatus.P_ON (bool): 正方向限界入力
        # $axis.DrvStatus.N_ON (bool): 負方向限界入力
        # $axis.Cmd (object): 軸指令値
        # $axis.Cmd.Pos (double): 指令現在位置
        # $axis.Cmd.Vel (double): 指令現在速度
        # $axis.Cmd.AccDec (double): 指令現在加減速度
        # $axis.Cmd.Jerk (double): 指令現在ジャーク
        # $axis.Cmd.Trq (double): 指令現在トルク
        # $axis.Act (object): 軸現在値
        # $axis.Act.Pos (double): フィードバック現在位置
        # $axis.Act.Vel (double): フィードバック現在速度
        # $axis.Act.Trq (double): フィードバック現在トルク
        # $axis.Act.TimeStamp (uint64): タイムスタンプ
        # $axis.MFaultLvl (object): 軸軽度フォールト情報
        # $axis.MFaultLvl.Active (bool): 軽度フォールト発生中
        # $axis.MFaultLvl.Code (uint16): コード
    .OUTPUTS
        System.Object
            取得した軸情報です。軸情報の詳細は、例を参照してください。
    .NOTES
        $Sessionが不正である場合、例外が発生します。
    #>
    [object] Axis(
        # OPC UAサーバへのセッション。
        [ISession]$Session
    ) { return ([BasicMCController]$this).Axis($Session) }

    <#
    .SYNOPSIS
        現在対象としている軸のインデックスを取得します。
    .EXAMPLE
        $axisIndex = $controller.AxisIndex($session)
    .OUTPUTS
        System.UInt16
            現在操作対象としている軸のインデックスです。
    .NOTES
        $Sessionが不正である場合、例外が発生します。
    #>
    [uint16] AxisIndex(
        # OPC UAサーバへのセッション。
        [ISession]$Session
    ) { return ([BasicMCController]).AxisIndex($Session) }

    <#
    .SYNOPSIS
        使用する軸をインデックスで指定します。
    .EXAMPLE
        $axisIndex = 1
        $ok = $controller.SetAxisIndex($session, $axisIndex)
    .OUTPUTS
        System.Boolean
            設定に成功したらTrue、そうでないときFalseです。
    .NOTES
        $Sessionが不正である場合、例外が発生します。
    #>
    [bool] SetAxisIndex(
        # OPC UAサーバへのセッション。
        [ISession]$Session,
        # 使用する軸のインデックス。
        [uint16]$AxisIndex
    ) { return ([BasicMCController]$this).SetAxisIndex($Session, $AxisIndex) }

    <#
    .SYNOPSIS
        絶対座標による位置決めを行うタスクを生成します。
    .EXAMPLE
        # 絶対座標で100 指令単位の位置に移動する例です。
        # モーションパラメータ:
        # Position (double): 絶対座標の目標位置。単位は、[指令単位]。
        # Velocity (double): 目標速度。単位は、[軸指令単位/s]。
        # Acceleration (double): 加速度。単位は、[軸指令単位/s^2]。
        # Deceleration (double): 減速度。単位は、[軸指令単位/s^2]。
        # Jerk (double): ジャーク。単位は、[軸指令単位/s^3]。
        # Direction (uint32): 動作方向。ロータリモードでのみ使用。0: 正方向指定、1: 近回り指定、2: 負方向指定、3: 現在方向指定、4: 方向指定なし
        # BufferMode (uint32): バッファモード。
        $motionContext = @{
            Position     = [double]100.0
            Velocity     = [double]5.0
            Acceleration = [double]2.0
            Deceleration = [double]2.0
            Jerk         = [double]0.0
            Direction    = [uint32]0
            BufferMode   = [uint32]0
        }
        $moveTask = $controller.MoveAbsolute($session, $motionContext)
        while (-not $moveTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $result = $moveTask.GetResult()
        $moveTask.Dispose()
    .OUTPUTS
        CallMethodTask
            生成したタスクです。
    .NOTES
        $Sessionが不正である場合、例外が発生します。
    #>
    [CallMethodTask] MoveAbsolute(
        # OPC UAサーバへのセッション。
        [ISession]$Session,
        # モーションパラメータ。
        [hashtable]$MotionContext = @{
            Position     = [double]0.0
            Velocity     = [double]0.0
            Acceleration = [double]0.0
            Deceleration = [double]0.0
            Jerk         = [double]0.0
            Direction    = [uint32]0
            BufferMode   = [uint32]0
        }
    ) { return ([BasicMCController]$this).MoveAbsolute($Session, $MotionContext) }

    <#
    .SYNOPSIS
        現在位置からの移動距離を指定しての位置決め、相対位置決めを行うタスクを生成します。
    .EXAMPLE
        # 現在位置から100 指令単位の位置へ位置決めをする例です。
        # モーションパラメータ:
        # Distance (double): 現在位置kらの移動距離。単位は、[指令単位]。
        # Velocity (double): 目標速度。単位は、[軸指令単位/s]。
        # Acceleration (double): 加速度。単位は、[軸指令単位/s^2]。
        # Deceleration (double): 減速度。単位は、[軸指令単位/s^2]。
        # Jerk (double): ジャーク。単位は、[軸指令単位/s^3]。
        # BufferMode (uint32): バッファモード。
        $motionContext = @{
            Distance     = [double]100.0
            Velocity     = [double]5.0
            Acceleration = [double]2.0
            Deceleration = [double]2.0
            Jerk         = [double]0.0
            Direction    = [uint32]0
            BufferMode   = [uint32]0
        }
        $motionTask = $controller.MoveRelative($session, $motionContext)
        while (-not $motionTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $result = $motionTask.GetResult()
        $motionTask.Dispose()
    .OUTPUTS
        CallMethodTask
            生成したタスクです。
    .NOTES
        $Sessionが不正である場合、例外が発生します。
    #>
    [CallMethodTask] MoveRelative(
        # OPC UAサーバへのセッション。
        [ISession]$Session,
        # モーションパラメータ。
        [hashtable]$MotionContext = @{
            Distance     = [double]0.0
            Velocity     = [double]0.0
            Acceleration = [double]0.0
            Deceleration = [double]0.0
            Jerk         = [double]0.0
            BufferMode   = [uint32]0
        }
    ) { return ([BasicMCController]$this).MoveRelative($Session, $MotionContext) }

    <#
    .SYNOPSIS
        絶対座標の"0"を目標位置として位置決め、原点へ戻るタスクを生成します。
    .EXAMPLE
        # 現在位置から原点へ戻る例です。
        # モーションパラメータ:
        # Velocity (double): 目標速度。単位は、[軸指令単位/s]。
        # Acceleration (double): 加速度。単位は、[軸指令単位/s^2]。
        # Deceleration (double): 減速度。単位は、[軸指令単位/s^2]。
        # Jerk (double): ジャーク。単位は、[軸指令単位/s^3]。
        # BufferMode (uint32): バッファモード。
        $motionContext = @{
            Velocity     = [double]5.0
            Acceleration = [double]2.0
            Deceleration = [double]2.0
            Jerk         = [double]0.0
            Direction    = [uint32]0
            BufferMode   = [uint32]0
        }
        $motionTask = $controller.MoveZeroPosition($session, $motionContext)
        while (-not $motionTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $result = $motionTask.GetResult()
        $motionTask.Dispose()
    .OUTPUTS
        CallMethodTask
            生成したタスクです。
    .NOTES
        $Sessionが不正である場合、例外が発生します。
    #>
    [CallMethodTask] MoveZeroPosition(
        # OPC UAサーバへのセッション。
        [ISession]$Session,
        # モーションパラメータ。
        [hashtable]$MotionContext = @{
            Distance     = [double]0.0
            Velocity     = [double]0.0
            Acceleration = [double]0.0
            Deceleration = [double]0.0
            Jerk         = [double]0.0
            BufferMode   = [uint32]0
        }
    ) { return ([BasicMCController]$this).MoveZeroPosition($Session, $MotionContext) }

    <#
    .SYNOPSIS
        原点を決めます。
    .EXAMPLE
        $result = $controller.Home($session)
        # $resultは以下の値を保持しています。
        # $result.Error (bool): 例外有無。例外が発生したときTrue、そうでないときFalse。
        # $result.ErrorID (uint16): 例外コード。
        # $result.CommandAborted (bool): 処理中止有無。処理が中止されたときTrue、そうでないときFalse。
    .OUTPUTS
        System.Collections.Hashtable
            処理結果です。詳細は例を例を参照してください。
    .NOTES
        $Sessionが不正である場合、例外が発生します。
    #>
    [hashtable] Home(
        # OPC UAサーバへのセッション。
        [ISession]$Session
    ) { return ([BasicMCController]$this).Home($Session) }

    <#
    .SYNOPSIS
        軸の現在指令位置とフィードバック現在位置を任意の値に変更します。
    .EXAMPLE
        $referenceType = 0 # サーボ軸
        $position = 100
        $result = $controller.SetPosition($session, $position, $referenceType)
        # $resultは以下の値を保持しています。
        # $result.Error (bool): 例外有無。例外が発生したときTrue、そうでないときFalse。
        # $result.ErrorID (uint16): 例外コード。
        # $result.CommandAborted (bool): 処理中止有無。処理が中止されたときTrue、そうでないときFalse。
    .OUTPUTS
        System.Collections.Hashtable
            処理結果です。詳細は例を例を参照してください。
    .NOTES
        $Sessionが不正である場合、例外が発生します。
    #>
    [hashtable] SetPosition(
        # OPC UAサーバへのセッション。
        [ISession]$Session,
        # 目標位置。絶対座標で指定します。
        [double]$Position = 0.0,
        # 位置種別選択。0: 指令位置(サーボ軸、仮想サーボ軸に適用可)、1: フィードバック現在位置(エンコーダ軸、仮想エンコーダ軸に適用可)
        [uint32]$ReferenceType = 1
    ) { return ([BasicMCController]$this).SetPosition($Session, $Position, $ReferenceType) }

    <#
    .SYNOPSIS
        軸の異常を解除します。
    .EXAMPLE
        $result = $controller.ResetAxisError($session)
        # $resultは以下の値を保持しています。
        # $result.Error (bool): 例外有無。例外が発生したときTrue、そうでないときFalse。
        # $result.ErrorID (uint16): 例外コード。
        # $result.Failure (bool): 処理が正常に実行されたかどうか。正常であったときFalse、そうでないときTrue。
    .OUTPUTS
        System.Collections.Hashtable
            処理結果です。詳細は例を例を参照してください。
    .NOTES
        $Sessionが不正である場合、例外が発生します。
    #>
    [hashtable] ResetAxisError(
        # OPC UAサーバへのセッション。
        [ISession]$Session
    ) { return ([BasicMCController]$this).ResetAxisError($Session) }
}
