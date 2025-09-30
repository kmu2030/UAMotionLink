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

function New-SingleMCController() {
    <#
    .SYNOPSIS
        SingleMCControllerについて、第一引数にSessionをとるメソッドのSessionを部分適用したメソッドを持つラッパーオブジェクトを生成します。
        生成に失敗したとき、$nullを返します。
        生成したラッパーオブジェクトはリソースを保持するため、使用後にDisposeメソッドを呼び出してリソースを解放します。
        ラッパーオブジェクトのメソッドについては、SingleMCController.ps1を確認してください。

    .EXAMPLE
        # この例は、環境変数を参照してラッパーオブジェクトを生成します。
        # 特定の環境変数が存在するとき、引数に優先して使用します。
        # Import-Envは、.envをセッションの環境変数にロードするコマンドレットとします。
        # ラッパーオブジェクトの生成は、OPC UAサーバとのコネクション確立を実行するため時間がかかります。
        Import-Env
        $controller = New-SingleMCController

    .EXAMPLE
        # この例は、パラメータを引数として指定してラッパーオブジェクトを生成します。
        # ラッパーオブジェクトの生成は、OPC UAサーバとのコネクション確立を実行するため時間がかかります。
        $controller = New-SingleMCController `
            -ServerUrl 'opc.tcp://localhost:4840' `
            -UserName 'taker' `
            -UserPassword 'chocolatepnacakes' `
            -Node 'ns=2;Programs.DeviceInterfaces.SingleMCController'
            -NodeSeparator = '.'

    .EXAMPLE
        # この例は、ラッパーオブジェクトを破棄します。
        $controller = New-SingleMCController
        $controller.Dispose()

    .EXAMPLE
        # この例は、指定した軸についての軸情報を取得します。
        $controller = New-SingleMCController
        # SingleMCControllerのラッパーオブジェクトのメソッド呼び出しにSessionを指定する必要はありません。
        $axisIndex = 0
        $ok = $controller.SetAxisIndex($axisIndex)
        $axis = $controller.Axis()
        # ラッパーオブジェクトは、不要になった時点で破棄します。
        # 例外が発生した場合も破棄してください。
        $controller.Dispose()

    .EXAMPLE
        # この例は、指定した軸について、絶対座標による位置決めを行います。
        $controller = New-SingleMCController
        $axisIndex = 0
        $ok = $controller.SetAxisIndex($axisIndex)
        $position = 100.0
        $moveTask = $controller.MoveAbsolute(@{
            Position     = $position
            Velocity     = 10.0
            Acceleration = 2.0
            Deceleration = 2.0
            Jerk         = 0.0
            Direction    = 0
            BufferMode   = 0
        })
        $ok = $moveTask.Execute()
        while (-not $moveTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $result = $moveTask.GetResult()
        $moveTask.Dispose()
        $axis = $controller.Axis().ActPos
        $ok = ([Math]::Abs($axis.Act.Pos - $position) -lt 0.0001) -and $axis.Status.Standstill
        $controller.Dispose()

    .EXAMPLE
        # この例は、指定した軸について、相対座標による位置決めを行います。
        $controller = New-SingleMCController
        $axisIndex = 0
        $ok = $controller.SetAxisIndex($axisIndex)
        $prevPos = $controller.Axis().Act.Pos
        $distance = 100.0
        $moveTask = $controller.MoveRelative(@{
            Distance     = $distance
            Velocity     = 10.0
            Acceleration = 2.0
            Deceleration = 2.0
            Jerk         = 0.0
            BufferMode   = 0
        })
        $ok = $moveTask.Execute()
        while (-not $moveTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $result = $moveTask.GetResult()
        $moveTask.Dispose()
        $axis = $controller.Axis().Act.Pos
        $ok = ([Math]::Abs(($axis.Act.Pos - $prevPos) - $distance) -lt 0.0001) -and $axis.Status.Standstill
        $controller.Dispose()

    .EXAMPLE
        # この例は、指定した軸を原点に戻します。
        $controller = New-SingleMCController
        $ok = $controller.SetAxisIndex(0)
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
        $motionTask = $controller.MoveZeroPosition($motionContext)
        while (-not $motionTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $result = $motionTask.GetResult()
        $motionTask.Dispose()
        $axis = $controller.Axis().Act.Pos
        $ok = ([Math]::Abs($axis.Act.Pos) -lt 0.0001) -and $axis.Status.Standstill
        $controller.Dispose()

    .EXAMPLE
        # この例は、指定した軸の原点を決めます。
        $controller = New-SingleMCController
        $axisIndex = 0
        $ok = $controller.SetAxisIndex($axisIndex)
        $result = $controller.Home()
        # $resultは以下の値を保持しています。
        # $result.Error (bool): 例外有無。例外が発生したときTrue、そうでないときFalse。
        # $result.ErrorID (uint16): 例外コード。
        # $result.CommandAborted (bool): 処理中止有無。処理が中止されたときTrue、そうでないときFalse。
        $controller.Dispose()

    .EXAMPLE
        # この例は、指定した軸の現在指令位置とフィードバック現在位置を任意の値に変更します。
        $controller = New-SingleMCController
        $axisIndex = 0
        $ok = $controller.SetAxisIndex($axisIndex)
        $referenceType = 0 # サーボ軸
        $position = 100
        $result = $controller.SetPosition($position, $referenceType)
        # $resultは以下の値を保持しています。
        # $result.Error (bool): 例外有無。例外が発生したときTrue、そうでないときFalse。
        # $result.ErrorID (uint16): 例外コード。
        # $result.CommandAborted (bool): 処理中止有無。処理が中止されたときTrue、そうでないときFalse。
        $controller.Dispose()

    .EXAMPLE
        # この例は、指定した軸の異常を解除します。
        $controller = New-SingleMCController
        $axisIndex = 0
        $ok = $controller.SetAxisIndex($axisIndex)
        $result = $controller.ResetAxisError()
        # $resultは以下の値を保持しています。
        # $result.Error (bool): 例外有無。例外が発生したときTrue、そうでないときFalse。
        # $result.ErrorID (uint16): 例外コード。
        # $result.Failure (bool): 処理が正常に実行されたかどうか。正常であったときFalse、そうでないときTrue。
        $controller.Dispose()

    .OUTPUTS
        System.Management.Automation.PSObject
            生成したラッパーオブジェクトです。
            ラップの対象であるSingleMCControllerのメソッドについては、SingleMCController.ps1を参照してください。
    #>
    param(
        # 接続するOPC UAサーバのURLを指定します。
        # 環境変数に"OPC_UA_ENDPOINT"が存在するとき、環境変数の値を使用します。
        [string]$ServerUrl = 'opc.tcp://localhost:4840',
        # OPC UAサーバへアクセスするユーザーを指定します。
        # 環境変数に"OPC_UA_CLIENT_USER"が存在するとき、環境変数の値を使用します。
        [string]$UserName = 'taker',
        # OPC UAサーバへアクセスするユーザーのパスワードを指定します。
        # 環境変数に"OPC_UA_CLIENT_USER_PASSWORD"が存在するとき、環境変数の値を使用します。
        [string]$UserPassword = 'chocolatepancakes',
        # BasicMCControllerModelを提供しているノードIDを指定します。
        # 環境変数に"SINGLE_MC_CONTROLLER_NODE"が存在するとき、環境変数の値を使用します。
        [string]$Node = 'ns=2;Programs.DeviceInterfaces.SingleMCController',
        # ノードIDの階層セパレータを指定します。
        # 環境変数に"SINGLE_MC_CONTROLLER_NODE_SEPARATOR"が存在するとき、環境変数の値を使用します。
        [string]$NodeSeparator = '.',
        # 既存のPwshOpcUaClientオブジェクトを指定することで、既存のセッションを使用します。
        [object]$Client = $null 
    )

    try {
        $ServerUrl = $Env:OPC_UA_ENDPOINT ?? $ServerUrl
        $UserName = $Env:OPC_UA_CLIENT_USER ?? $UserName
        $UserPassword = $Env:OPC_UA_CLIENT_PASSWORD ?? $UserPassword
        $Node = $Env:SINGLE_MC_CONTROLLER_NODE ?? $Node
        $NodeSeparator = $Env:SINGLE_MC_CONTROLLER_NODE_SEPARATOR ?? $NodeSeparator

        if (($null -eq $Client) -or ($null -eq $Client.Session)) {
            $AccessUserIdentity = [string]::IsNullOrEmpty($UserName) `
                ? (New-Object UserIdentity) `
                : (New-Object UserIdentity -ArgumentList $UserName, $UserPassword)
            $clientParam = @{
                ServerUrl          = $ServerUrl
                UseSecurity        = $true
                SessionLifeTime    = 60000
                AccessUserIdentity = $AccessUserIdentity
            }
            $Client = New-PwshOpcUaClient @clientParam
            $UserPassword = $null
            $AccessUserIdentity = $null
            $clientParam = $null
        }
        $controller = [BasicMCController]::new($Node, $NodeSeparator)

        $obj = [PSCustomObject]@{
            Client     = $Client
            Controller = $controller
        }

        $methods = $controller.GetType().GetMethods()
        foreach ($method in $methods) {
            $methodName = $method.Name
            if (($method.DeclaringType -ne [BasicMCController]) `
                    -or ($null -ne $obj.$methodName)
            ) { continue }

            $params = $method.GetParameters();
            if ($params.Count -gt 0 -and $params[0].ParameterType.Name -eq 'ISession') {
                $scriptBlock = [scriptblock]::Create("return `$this.Controller.$methodName.Invoke(@(`$this.Client.Session) + `$args)")
            }
            else {
                $scriptBlock = [scriptblock]::Create("return `$this.Controller.$methodName.Invoke(`$args)")
            }

            $obj | Add-Member -MemberType ScriptMethod -Name $methodName -Value $scriptBlock
        }
        $obj | Add-Member -MemberType ScriptMethod -Name 'Dispose' -Value {
            Dispose-PwshOpcUaClient -Client $this.Client
            $this.Client = $null
            $this.Controller = $null
        }

        Write-Output $obj
    }
    catch {
        Dispose-PwshOpcUaClient -Client $client
        $client = $null
        Write-Error $_.Exception
        Write-Output $null
    }
}
