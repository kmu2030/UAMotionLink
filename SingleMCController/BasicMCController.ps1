<#
GNU General Public License, Version 2.0

Copyright (C) 2025 KITA Munemitsu
https://github.com/kmu2030/UAMotionLinkLib

This program is free software; you can redistribute it and/or modify it under the terms of
the GNU General Public License as published by the Free Software Foundation;
either version 2 of the License, or (at your option) any later version.
This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program;
if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#>

using namespace Opc.Ua
using namespace Opc.Ua.Configuration
using namespace Opc.Ua.Client
using namespace Opc.Ua.Client.ComplexTypes

<#
.SYNOPSIS
    OPC UAサーバが公開するBasicMCControllerModelを介したサーボ操作を提供します。
.NOTES
    エージェントへの情報として、メソッドにコメントベースのヘルプを記載しています。
#>
class BasicMCController {
    [hashtable] $Methods = $null
    [hashtable] $Properties = $null
    [string] $BaseNodeId = ''
    [string] $NodeSeparator = '.'

    BasicMCController([string]$BaseNodeId) {
        $this.Init($BaseNodeId, '.')
    }

    BasicMCController([string]$BaseNodeId, [string]$NodeSeparator) {
        $this.Init($BaseNodeId, $NodeSeparator)
    }

    hidden [void] Init([string]$BaseNodeId, [string]$NodeSeparator) {
        $this.BaseNodeId = $BaseNodeId
        $this.NodeSeparator = $NodeSeparator
        $this.Methods = @{}
        $this.Properties = @{}
    }

    <#
    .SYNOPSIS
        疑似UA Method呼び出しを定義します。
    #>
    hidden [void] DefinePseudoMethod([hashtable]$Definition) {
        $methodName = $Definition.Name

        $checkCallableParams = $null
        if ($Definition.CheckCallable) {
            $checkCallableParams = [ReadValueIdCollection]::new()
            $checkCallableParam = New-Object ReadValueId -Property @{
                AttributeId = [Attributes]::Value
            }
            $checkCallableParam.NodeId = [NodeId]::new((@($this.BaseNodeId, $methodName, 'Busy') -join $this.NodeSeparator))
            $checkCallableParams.Add($checkCallableParam)
        }

        $callParams = [WriteValueCollection]::new()
        foreach ($p in $Definition.InParams) {
            $callParam = [WriteValue]::new()
            $callParam.NodeId = [NodeId]::new((@($this.BaseNodeId, $methodName, $p) -join $this.NodeSeparator))
            $callParam.AttributeId = [Attributes]::Value
            $callParam.Value = [DataValue]::new()
            $callParams.Add($callParam)
        }
        $callParam = [WriteValue]::new()
        $callParam.NodeId = [NodeId]::new((@($this.BaseNodeId, $methodName, 'Execute') -join $this.NodeSeparator))
        $callParam.AttributeId = [Attributes]::Value
        $callParam.Value = [DataValue]::new()
        $callParam.Value.Value = $true
        $callParams.Add($callParam)

        $doneParams = [ReadValueIdCollection]::new()
        $doneParam = New-Object ReadValueId -Property @{
            AttributeId = [Attributes]::Value
        }
        $doneParam.NodeId = [NodeId]::new((@($this.BaseNodeId, $methodName, 'Done') -join $this.NodeSeparator))
        $doneParams.Add($doneParam)
        foreach ($p in $Definition.OutParams) {
            $doneParam = New-Object ReadValueId -Property @{
                AttributeId = [Attributes]::Value
            }
            $doneParam.NodeId = [NodeId]::new((@($this.BaseNodeId, $methodName, $p) -join $this.NodeSeparator))
            $doneParams.Add($doneParam)
        }

        $clearParams = [WriteValueCollection]::new()
        $clearParam = [WriteValue]::new()
        $clearParam.NodeId = [NodeId]::new((@($this.BaseNodeId, $methodName, 'Execute') -join $this.NodeSeparator))
        $clearParam.AttributeId = [Attributes]::Value
        $clearParam.Value = [DataValue]::new()
        $clearParam.Value.Value = $false
        $clearParams.Add($clearParam)

        $checkClearedParams = $null
        if ($Definition.CheckCleared) {
            $checkClearedParams = [ReadValueIdCollection]::new()
            $checkClearedParam = New-Object ReadValueId -Property @{
                AttributeId = [Attributes]::Value
            }
            $checkClearedParam.NodeId = [NodeId]::new((@($this.BaseNodeId, $methodName, 'Done') -join $this.NodeSeparator))
            $checkClearedParams.Add($checkClearedParam)
        }

        $this.Methods[$methodName] = @{
            CheckCallableParams = $checkCallableParams
            CallParams          = $callParams
            DoneParams          = $doneParams
            ClearParams         = $clearParams
            CheckClearedParams  = $checkClearedParams
            InProcessor         = $Definition.InProcessor
            OutProcessor        = $Definition.OutProcessor
            OnCalled            = $Definition.OnCalled
            OnDone              = $Definition.OnDone
            OnCleared           = $Definition.OnCleared
        }
    }

    <#
    .SYNOPSIS
        プロパティ取得を定義します。
    #>
    hidden [void] DefineProperty([hashtable]$Definition) {
        $readValues = [ReadValueIdCollection]::new()
        foreach ($r in $Definition.ReadValues) {
            $readValue = New-Object ReadValueId -Property @{
                AttributeId = [Attributes]::Value
            }
            $readValue.NodeId = [NodeId]::new((@($this.BaseNodeId, $r) -join $this.NodeSeparator))
            $readValues.Add($readValue)
        }

        $this.Properties[$Definition.Name] = @{
            ReadValues    = $readValues
            PostProcessor = $Definition.PostProcessor
        }
    }

    <#
    .SYNOPSIS
        OPC UAサーバが公開するBasicMCControllerModelのメソッドを実行します。
    #>
    hidden [Object] CallMethod(
        [ISession]$Session,
        [hashtable]$Context
    ) {
        return $this.CallMethod($Session, $Context, $null)
    }

    <#
    .SYNOPSIS
        OPC UAサーバが公開するBasicMCControllerModelのメソッドを実行します。
    #>
    hidden [Object] CallMethod(
        [ISession]$Session,
        [hashtable]$Context,
        [array]$CallArgs
    ) {
        if (-not $Session.Connected) {
            throw [System.ArgumentException]::new('Session is not connected.', $Session, 'Session')
        }

        if ($null -ne $CallArgs) {
            (& $Context.InProcessor $CallArgs $Context)
            | Out-Null
        }

        $exception = $null
        try {
            $results = $null
            $diagnosticInfos = $null

            if ($null -ne $Context.CheckCallableParams) {
                $results = [DataValueCollection]::new()
                $diagnosticInfos = [DiagnosticInfoCollection]::new()
                do {
                    $response = $Session.Read(
                        $null,
                        [double]0,
                        [TimestampsToReturn]::Both,
                        $Context.CheckCallableParams,
                        [ref]$results,
                        [ref]$diagnosticInfos
                    )
                    if ($null -ne ($exception = $this.ValidateResponse(
                                $response,
                                $results,
                                $diagnosticInfos,
                                $Context.CheckCallableParams,
                                'Failed to check callable.'))
                    ) {
                        throw $exception
                    }
                }
                until ($results.Count -gt 0 -and -not $results[0].Value)
            }
            
            $results = $null
            $diagnosticInfos = $null
            $response = $Session.Write(
                $null,
                $Context.CallParams,
                [ref]$results,
                [ref]$diagnosticInfos
            )
            if ($null -ne ($exception = $this.ValidateResponse(
                        $response,
                        $results,
                        $diagnosticInfos,
                        $Context.CallParams,
                        'Failed to write call parameters.'))
            ) {
                throw $exception
            }

            if ($null -ne $Context.OnCalled) {
                (& $Context.OnCalled $response $results $diagnosticInfos $Context)
            }
    
            $results = [DataValueCollection]::new()
            $diagnosticInfos = [DiagnosticInfoCollection]::new()
            do {
                $response = $Session.Read(
                    $null,
                    [double]0,
                    [TimestampsToReturn]::Both,
                    $Context.DoneParams,
                    [ref]$results,
                    [ref]$diagnosticInfos
                )
                if ($null -ne ($exception = $this.ValidateResponse(
                            $response,
                            $results,
                            $diagnosticInfos,
                            $Context.DoneParams,
                            'Failed to get execution result parameters.'))
                ) {
                    throw $exception
                }
            }
            until ($results.Count -gt 0 -and $results[0].Value)
    
            if ($null -ne $Context.OnDone) {
                (& $Context.OnDone $response $results $diagnosticInfos $Context)
            }

            $outs = New-Object System.Collections.ArrayList
            foreach ($r in $results | Select-Object -Skip 1) {
                $outs.Add($r.Value)
            }
    
            return (& $Context.OutProcessor $outs $Context)
        }
        finally {
            $results = $null
            $diagnosticInfos = $null
            $response = $Session.Write(
                $null,
                $Context.ClearParams,
                [ref]$results,
                [ref]$diagnosticInfos
            )
            if (($null -ne ($_exception = $this.ValidateResponse(
                            $response,
                            $results,
                            $diagnosticInfos,
                            $Context.ClearParams,
                            'Failed to clear method call parameters.'))) `
                    -and ($null -eq $exception)
            ) {
                throw $_exception
            }

            if ($null -ne $Context.OnCleared) {
                (& $Context.OnCleared $response $results $diagnosticInfos $Context)
            }

            if ($null -ne $Context.CheckClearedParams) {
                $results = [DataValueCollection]::new()
                $diagnosticInfos = [DiagnosticInfoCollection]::new()
                do {
                    $response = $Session.Read(
                        $null,
                        [double]0,
                        [TimestampsToReturn]::Both,
                        $Context.CheckClearedParams,
                        [ref]$results,
                        [ref]$diagnosticInfos
                    )
                    if ($null -ne ($_exception = $this.ValidateResponse(
                                $response,
                                $results,
                                $diagnosticInfos,
                                $Context.CheckClearedParams,
                                'Failed to check cleared.'))
                    ) {
                        throw $_exception
                    }
                }
                until ($results.Count -gt 0 -and -not $results[0].Value)
            }
        }
    }

    <#
    .SYNOPSIS
        OPC UAサーバが公開するBasicMCControllerModelのメソッドを実行するタスクを作成します。
    #>
    hidden [CallMethodTask] CreateCallMethodTask(
        [ISession]$Session,
        [hashtable]$Context,
        [array]$CallArgs
    ) {
        if (-not $Session.Connected) {
            throw [System.ArgumentException]::new('Session is not connected.', $Session, 'Session')
        }

        if ($null -ne $CallArgs) {
            (& $Context.InProcessor $CallArgs $Context)
            | Out-Null
        }

        return [CallMethodTask]::new($Session, $Context)
    }

    <#
    .SYNOPSIS
        OPC UAサーバが公開するBasicMCControllerModelのプロパティを取得します。
    #>
    hidden [Object] FetchProperty(
        [ISession]$Session,
        [hashtable]$Context
    ) {
        if (-not $Session.Connected) {
            throw [System.ArgumentException]::new('Session is not connected.', $Session, 'Session')
        }
  
        $results = [DataValueCollection]::new()
        $diagnosticInfos = [DiagnosticInfoCollection]::new()
        do {
            $response = $Session.Read(
                $null,
                [double]0,
                [TimestampsToReturn]::Both,
                $Context.ReadValues,
                [ref]$results,
                [ref]$diagnosticInfos
            )
            if ($null -ne ($exception = $this.ValidateResponse(
                        $response,
                        $results,
                        $diagnosticInfos,
                        $Context.ReadValues,
                        'Failed to read values.'))
            ) {
                throw $exception
            }
        }
        until ($results.Count -eq $Context.ReadValues.Count)

        $reads = New-Object System.Collections.ArrayList
        foreach ($r in $results) {
            $reads.Add($r.Value)
        }

        return (& $Context.PostProcessor $reads $Context)
    }

    <#
    .SYNOPSIS
        OPC UAサーバとのメッセージ交換結果をバリデートします。
    #>
    hidden [Object] ValidateResponse($Response, $Results, $DiagnosticInfos, $Requests, $ExceptionMessage) {
        if (($Results
                | Where-Object { $_ -is [StatusCode] }
                | ForEach-Object { [ServiceResult]::IsNotGood($_) }
            ) -contains $true `
                -or ($Results.Count -ne $Requests.Count)
        ) {
            return [MethodCallException]::new($ExceptionMessage, @{
                    Response        = $Response
                    Results         = $Results
                    DiagnosticInfos = $DiagnosticInfos
                })
        }
        else {
            return $null
        }
    }

    hidden [hashtable] GetMethodContext([string]$Name) {
        if ($null -eq $this.Methods.$Name) {
            return $null
        }

        return @{
            CallParams         = $this.Methods.$Name.CallParams.Clone()
            DoneParams         = $this.Methods.$Name.DoneParams.Clone()
            ClearParams        = $this.Methods.$Name.ClearParams.Clone()
            CheckClearedParams = $this.Methods.$Name.CheckClearedParams?.Clone()
            InProcessor        = $this.Methods.$Name.InProcessor
            OutProcessor       = $this.Methods.$Name.OutProcessor
            OnCalled           = $this.Methods.$Name.OnCalled
            OnDone             = $this.Methods.$Name.OnDone
            OnCleared          = $this.Methods.$Name.OnCleared
        }
    }

    hidden [hashtable] GetPropertyContext([string]$Name) {
        if ($null -eq $this.Properties.$Name) {
            return $null
        }

        return @{
            ReadValues    = $this.Properties.$Name.ReadValues.Clone()
            PostProcessor = $this.Properties.$Name.PostProcessor
        }
    }

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
        # $axis.DrvStatus.P_OT (bool): 正方向限界入力
        # $axis.DrvStatus.N_OT (bool): 負方向限界入力
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
    [object] Axis([ISession]$Session) {
        $propContext = $this.GetPropertyContext((Get-PSCallStack)[0].FunctionName);
        if ($null -eq $propContext) {
            $propName = (Get-PSCallStack)[0].FunctionName
            $this.DefineProperty(@{
                    Name          = $propName
                    ReadValues    = @($propName)
                    PostProcessor = {
                        param($Reads, $Context)
                        return $Reads[0].Body
                    }
                })
            $propContext = $this.GetPropertyContext($propName);
        }

        return [object]$this.FetchProperty($Session, $propContext)
    }

    <#
    .SYNOPSIS
        現在対象としている軸のインデックスを取得します。
    .EXAMPLE
        $axisIndex = $controller.AxisIndex()
    .OUTPUTS
        System.UInt16
            現在操作対象としている軸のインデックスです。
    .NOTES
        $Sessionが不正である場合、例外が発生します。
    #>
    [uint16] AxisIndex([ISession]$Session) {
        $propContext = $this.GetPropertyContext((Get-PSCallStack)[0].FunctionName);
        if ($null -eq $propContext) {
            $propName = (Get-PSCallStack)[0].FunctionName
            $this.DefineProperty(@{
                    Name          = $propName
                    ReadValues    = @($propName)
                    PostProcessor = {
                        param($Reads, $Context)
                        return $Reads[0]
                    }
                })
            $propContext = $this.GetPropertyContext($propName);
        }

        return [uint16]$this.FetchProperty($Session, $propContext)
    }

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
    ) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName);
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefinePseudoMethod(@{
                    Name         = $methodName
                    InParams     = @('NewValue')
                    OutParams    = @('Ok')
                    InProcessor  = {
                        param($CallArgs, $Context)
                        $Context.CallParams[0].Value.Value = [uint16]$CallArgs[0]
                    }
                    OutProcessor = {
                        param($Outs, $Context)
                        return $Outs[0]
                    }
                    CheckCleared = $true
                })
            $methodContext = $this.GetMethodContext($methodName);
        }

        return [bool]$this.CallMethod($Session, $methodContext, @(,$AxisIndex))
    }

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
    ) {
        $methodName = 'MoveAbsolute'
        $methodContext = $this.GetMethodContext($methodName);
        if ($null -eq $methodContext) {
            $this.DefinePseudoMethod(@{
                    Name         = $methodName
                    InParams     = @('Position', 'Velocity', 'Acceleration', 'Deceleration', 'Jerk', 'Direction', 'BufferMode')
                    OutParams    = @('Error', 'ErrorID', 'CommandAborted')
                    InProcessor  = {
                        param($CallArgs, $Context)
                        $mc = $CallArgs[0]
                        $Context.CallParams[0].Value.Value = [double]$mc.Position
                        $Context.CallParams[1].Value.Value = [double]$mc.Velocity
                        $Context.CallParams[2].Value.Value = [double]$mc.Acceleration
                        $Context.CallParams[3].Value.Value = [double]$mc.Deceleration
                        $Context.CallParams[4].Value.Value = [double]$mc.Jerk
                        $Context.CallParams[5].Value.Value = [uint32]$mc.Direction
                        $Context.CallParams[6].Value.Value = [uint32]$mc.BufferMode
                    }
                    OutProcessor = {
                        param($Outs, $Context)
                        return @{
                            Error = $Outs[0]
                            ErrorID = $Outs[1]
                            CommandAborted = $Outs[2]
                        }
                    }
                    CheckCleared = $true
                })
            $methodContext = $this.GetMethodContext($methodName);
        }

        return $this.CreateCallMethodTask($Session, $methodContext, @(,$MotionContext))
    }

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
    ) {
        $methodName = 'MoveRelative'
        $methodContext = $this.GetMethodContext($methodName);
        if ($null -eq $methodContext) {
            $this.DefinePseudoMethod(@{
                    Name         = $methodName
                    InParams     = @('Distance', 'Velocity', 'Acceleration', 'Deceleration', 'Jerk', 'BufferMode')
                    OutParams    = @('Error', 'ErrorID', 'CommandAborted')
                    InProcessor  = {
                        param($CallArgs, $Context)
                        $mc = $CallArgs[0]
                        $Context.CallParams[0].Value.Value = [double]$mc.Distance
                        $Context.CallParams[1].Value.Value = [double]$mc.Velocity
                        $Context.CallParams[2].Value.Value = [double]$mc.Acceleration
                        $Context.CallParams[3].Value.Value = [double]$mc.Deceleration
                        $Context.CallParams[4].Value.Value = [double]$mc.Jerk
                        $Context.CallParams[5].Value.Value = [uint32]$mc.BufferMode
                    }
                    OutProcessor = {
                        param($Outs, $Context)
                        return @{
                            Error = $Outs[0]
                            ErrorID = $Outs[1]
                            CommandAborted = $Outs[2]
                        }
                    }
                    CheckCleared = $true
                })
            $methodContext = $this.GetMethodContext($methodName);
        }

        return $this.CreateCallMethodTask($Session, $methodContext, @(,$MotionContext))
    }

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
            Velocity     = [double]0.0
            Acceleration = [double]0.0
            Deceleration = [double]0.0
            Jerk         = [double]0.0
            BufferMode   = [uint32]0
        }
    ) {
        $methodName = 'MoveZeroPosition'
        $methodContext = $this.GetMethodContext($methodName);
        if ($null -eq $methodContext) {
            $this.DefinePseudoMethod(@{
                    Name         = $methodName
                    InParams     = @('Velocity', 'Acceleration', 'Deceleration', 'Jerk', 'BufferMode')
                    OutParams    = @('Error', 'ErrorID', 'CommandAborted')
                    InProcessor  = {
                        param($CallArgs, $Context)
                        $mc = $CallArgs[0]
                        $Context.CallParams[0].Value.Value = [double]$mc.Velocity
                        $Context.CallParams[1].Value.Value = [double]$mc.Acceleration
                        $Context.CallParams[2].Value.Value = [double]$mc.Deceleration
                        $Context.CallParams[3].Value.Value = [double]$mc.Jerk
                        $Context.CallParams[4].Value.Value = [uint32]$mc.BufferMode
                    }
                    OutProcessor = {
                        param($Outs, $Context)
                        return @{
                            Error = $Outs[0]
                            ErrorID = $Outs[1]
                            CommandAborted = $Outs[2]
                        }
                    }
                    CheckCleared = $true
                })
            $methodContext = $this.GetMethodContext($methodName);
        }

        return $this.CreateCallMethodTask($Session, $methodContext, @(,$MotionContext))
    }

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
    ) {
        $methodName = 'Home'
        $methodContext = $this.GetMethodContext($methodName);
        if ($null -eq $methodContext) {
            $this.DefinePseudoMethod(@{
                    Name         = $methodName
                    InParams     = @()
                    OutParams    = @('Error', 'ErrorID', 'CommandAborted')
                    InProcessor  = {}
                    OutProcessor = {
                        param($Outs, $Context)
                        return @{
                            Error = $Outs[0]
                            ErrorID = $Outs[1]
                            CommandAborted = $Outs[2]
                        }
                    }
                    CheckCleared = $true
                })
            $methodContext = $this.GetMethodContext($methodName);
        }

        return $this.CallMethod($Session, $methodContext)
    }

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
        # 位置種別選択。0: 指令位置、1: フィードバック現在位置
        [uint32]$ReferenceType = 0
    ) {
        $methodName = 'SetPosition'
        $methodContext = $this.GetMethodContext($methodName);
        if ($null -eq $methodContext) {
            $this.DefinePseudoMethod(@{
                    Name         = $methodName
                    InParams     = @('Position', 'ReferenceType')
                    OutParams    = @('Error', 'ErrorID', 'CommandAborted')
                    InProcessor  = {
                        param($CallArgs, $Context)
                        $Context.CallParams[0].Value.Value = [double]$Callargs[0];
                        $Context.CallParams[1].Value.Value = [uint32]$CallArgs[1];
                    }
                    OutProcessor = {
                        param($Outs, $Context)
                        return @{
                            Error = $Outs[0]
                            ErrorID = $Outs[1]
                            CommandAborted = $Outs[2]
                        }
                    }
                    CheckCleared = $true
                })
            $methodContext = $this.GetMethodContext($methodName);
        }

        return $this.CallMethod($Session, $methodContext, @($Position, $ReferenceType))
    }

    <#
    .SYNOPSIS
        現在選択している軸の異常を解除します。
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
    ) {
        $methodName = 'Reset'
        $methodContext = $this.GetMethodContext($methodName);
        if ($null -eq $methodContext) {
            $this.DefinePseudoMethod(@{
                    Name         = $methodName
                    InParams     = @()
                    OutParams    = @('Failure', 'Error', 'ErrorID')
                    InProcessor  = {}
                    OutProcessor = {
                        param($Outs, $Context)
                        return @{
                            Failure = $Outs[1]
                            Error = $Outs[1]
                            ErrorID = $Outs[2]
                        }
                    }
                    CheckCleared = $true
                })
            $methodContext = $this.GetMethodContext($methodName)
        }

        return $this.CallMethod($Session, $methodContext)
    }
}

<#
.SYNOPSIS
    OPC UAサーバのメソッドを呼び出すタスクです。
    実行が長時間に及ぶメソッド、キャンセルが可能なメソッド、他のメソッドと同時実行可能なメソッドが、このタスクを使用します。
.DESCRIPTION
    タスクの以下のメソッドは、OPC UAサーバとメッセージ交換をします。

    * Execute
    * CheckDone
    * Cancel
    * Dispose

    これらは、同期処理です。これは、OPC UAクライアントの仕様によります。
    複数メソッドのタスクを並列に使用する場合、常に1つのタスクの1つのメソッドだけを実行するようにします。
    競合しないメソッドは同時に処理状態になっても問題ありませんが、OPC UAサーバへの問い合わせは常に単一である必要があります。
    ジョブ等で並列処理をする場合、それが満たされるようにしてください。
#>
class CallMethodTask {
    [ISession] $Session
    [hashtable] $Context
    [object] $Result
    [bool] $IsExecuted
    [bool] $IsDone
    [bool] $IsCleared

    CallMethodTask([ISession]$Session, [hashtable]$Context) {
        $this.Session = $Session
        $this.Context = $Context
        $this.Result = $null
        $this.IsExecuted = $false
        $this.IsDone = $false
        $this.IsCleared = $false
    }

    <#
    .SYNOPSIS
        メソッドの処理結果を取得します。
    .OUTPUTS
        System.Object
            メソッドの処理結果です。
    #>
    [object] GetResult() { return $this.Result }

    <#
    .SYNOPSIS
        タスクを実行します。
        タスクを実行することで、メソッドの処理を開始します。
    .OUTPUTS
        System.Boolean
            タスクの処理開始に成功したときTrue、そうでないときFalseです。
    .NOTES
        実行済みタスクを再度実行すると例外が発生します。
    #>
    [bool] Execute() {
        if ($this.IsDone -or $this.IsCleared) { throw 'Task is done.' }

        if ($null -ne $this.Context.CheckCallableParams) {
            $results = [DataValueCollection]::new()
            $diagnosticInfos = [DiagnosticInfoCollection]::new()
            do {
                $response = $this.Session.Read(
                    $null,
                    [double]0,
                    [TimestampsToReturn]::Both,
                    $this.Context.CheckCallableParams,
                    [ref]$results,
                    [ref]$diagnosticInfos
                )
                if ($null -ne ($exception = $this.ValidateResponse(
                            $response,
                            $results,
                            $diagnosticInfos,
                            $this.Context.CheckCallableParams,
                            'Failed to check callable.'))
                ) {
                    throw $exception
                }
            }
            until ($results.Count -gt 0)
            if ($results[0].Value) { return $false }
        }

        $exception = $null
        $results = $null
        $diagnosticInfos = $null
        $response = $this.Session.Write(
            $null,
            $this.Context.CallParams,
            [ref]$results,
            [ref]$diagnosticInfos
        )
        if ($null -ne ($exception = $this.ValidateResponse(
                    $response,
                    $results,
                    $diagnosticInfos,
                    $this.Context.CallParams,
                    'Failed to write call parameters.'))
        ) {
            throw $exception
        }

        if ($null -ne $this.Context.OnCalled) {
            (& $this.Context.OnCalled $response $results $diagnosticInfos $this.Context)
        }

        $this.IsExecuted = $true

        return $true
    }

    <#
    .SYNOPSIS
        メソッドの処理が完了しているか確認します。
    .OUTPUTS
        System.Boolean
            処理が完了しているとき、Trueを返し、そうでないときFalseを返します。
            Trueを返した後は、GetResultで結果を取得できます。
    .NOTES
        未実行のタスクで実行すると例外が発生します。
    #>
    [bool] CheckDone() {
        if (-not $this.IsExecuted) { throw 'Task is not executed.' }
        if ($this.IsDone) { return $true }

        $results = [DataValueCollection]::new()
        $diagnosticInfos = [DiagnosticInfoCollection]::new()
        
        $response = $this.Session.Read(
            $null,
            [double]0,
            [TimestampsToReturn]::Both,
            $this.Context.DoneParams,
            [ref]$results,
            [ref]$diagnosticInfos
        )
        if ($null -ne ($exception = $this.ValidateResponse(
                    $response,
                    $results,
                    $diagnosticInfos,
                    $this.Context.DoneParams,
                    'Failed to get execution result parameters.'))
        ) {
            throw $exception
        }

        if ($results.Count -lt 1 -or -not $results[0].Value) {
            return $false
        }

        if ($null -ne $this.Context.OnDone) {
            (& $this.Context.OnDone $response $results $diagnosticInfos $this.Context)
        }

        $outs = New-Object System.Collections.ArrayList
        foreach ($r in $results | Select-Object -Skip 1) {
            $outs.Add($r.Value)
        }

        $this.Result = (& $this.Context.OutProcessor $outs $this.Context)
        $this.IsDone = $true

        return $true
    }

    <#
    .SYNOPSIS
        メソッドの処理をキャンセルします。
    #>
    [void] Cancel() {
        $this.ClearParams()
    }

    hidden [void] ClearParams() {
        if (-not $this.IsExecuted -or $this.IsCleared) { return }

        $results = $null
        $diagnosticInfos = $null
        $response = $this.Session.Write(
            $null,
            $this.Context.ClearParams,
            [ref]$results,
            [ref]$diagnosticInfos
        )
        if ($null -ne ($_exception = $this.ValidateResponse(
                    $response,
                    $results,
                    $diagnosticInfos,
                    $this.Context.ClearParams,
                    'Failed to clear method call parameters.'))
        ) {
            throw $_exception
        }

        if ($null -ne $this.Context.OnCleared) {
            (& $this.Context.OnCleared $response $results $diagnosticInfos $this.Context)
        }

        if ($null -eq $this.Context.CheckClearedParams) {
            $this.IsCleared = $true
            return
        }

        $results = [DataValueCollection]::new()
        $diagnosticInfos = [DiagnosticInfoCollection]::new()
        do {
            $response = $this.Session.Read(
                $null,
                [double]0,
                [TimestampsToReturn]::Both,
                $this.Context.CheckClearedParams,
                [ref]$results,
                [ref]$diagnosticInfos
            )
            if ($null -ne ($_exception = $this.ValidateResponse(
                        $response,
                        $results,
                        $diagnosticInfos,
                        $this.Context.CheckClearedParams,
                        'Failed to check cleared.'))
            ) {
                throw $_exception
            }
        }
        until ($results.Count -gt 0 -and -not $results[0].Value)

        $this.IsCleared = $true
    }

    <#
    .SYNOPSIS
        タスクを破棄します。タスク実行後に必ず実行します。
    #>
    [void] Dispose() {
        $this.ClearParams()
        $this.Session = $null
        $this.Context = $null
        $this.Result = $null
    }

    <#
    .SYNOPSIS
        OPC UAのメッセージ交換のレスポンスをバリデートします。
    #>
    hidden [Object] ValidateResponse($Response, $Results, $DiagnosticInfos, $Requests, $ExceptionMessage) {
        if (($Results
                | Where-Object { $_ -is [StatusCode] }
                | ForEach-Object { [ServiceResult]::IsNotGood($_) }
            ) -contains $true `
                -or ($Results.Count -ne $Requests.Count)
        ) {
            return [MethodCallException]::new($ExceptionMessage, @{
                    Response        = $Response
                    Results         = $Results
                    DiagnosticInfos = $DiagnosticInfos
                })
        }
        else {
            return $null
        }
    }
}
