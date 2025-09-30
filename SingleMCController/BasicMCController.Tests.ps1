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

<#
# About This Script
This script is a test of `BasicMCController.ps1` using `Pester`.
Run the information model test (`POU/Program/ModelTest`) on the controller or simulator,
and use it to make it accessible via OPC UA.
The information model test runs on `UAMotionLinkLib.smc2` by default.

## Usage Environment
IDE:Sysmac Studio Ver.1.62 or later
PowerShell: PowerShell 7.5 or later
Pester     : 5.7.1

## Usage Steps (Simulator)
1.  Run `./PwshOpcUaClient/setup.ps1`.
    This retrieves the assemblies required by `PwshOpcUaClient` using NuGet.
2.  Open `UAMotionLinkLib.smc2` in Sysmac Studio.
3.  Start the simulator and the OPC UA server for simulator.
4.  Generate a certificate on the OPC UA server for simulator.   
    This step is unnecessary if a certificate has already been generated.
5.  Register a user and password for the OPC UA server for simulator.   
    This step is unnecessary if a user has already been registered.
6.  Run `Invoke-Pester`.
7.  Trust the server certificate in `PwshOpcUaClient`.
    Move the rejected server certificate from `PwshOpcUaClient/pki/rejected/certs` to `PwshOpcUaClient/pki/trusted/certs`.
8.  Run `Invoke-Pester`.


# このスクリプトについて
このスクリプトは**Pester**による`BasicMCController.ps1`のテストです。
コントローラまたは、シミュレータでモデルテスト(`POU/プログラム/ModelTest`)を動作させ、
OPC UAでアクセスできる状態にして使用します。
`UAMotionLinkLib.smc2`は、デフォルトでモデルテストが動作します。

## 使用環境
IDE        : Sysmac Studio Ver.1.62以降
PowerShell : PowerShell 7.5以降
Pester     : 5.7.1

## 使用手順 (シミュレータ)
1.  `./PwshOpcUaClient/setup.ps1`を実行
    `PwshOpcUaClient`が必要とするアセンブリをNuGetで取得。
2.  Sysmac Studioで`UAMotionLinkLib.smc2`を開く
3.  シミュレータとシミュレータ用OPC UAサーバを起動
4.  シミュレータ用OPC UAサーバで証明書を生成
    既に生成してある場合は不要。
5.  シミュレータ用OPC UAサーバへユーザーとパスワードを登録
    既に登録してある場合は不要。
6.  `Invoke-Pester`を実行
7.  `PwshOpcUaClient`でサーバ証明書を信頼
    `./PwshOpcUaClient/pki/rejected/certs`にある拒否したサーバ証明書を`./PwshOpcUaClient/pki/trusted/certs`に移動。
8.  `Invoke-Pester`を実行
#>

using namespace Opc.Ua
param(
    [bool]$UseSimulator = $true,
    [string]$ServerUrl = 'opc.tcp://localhost:4840',
    [bool]$UseSecurity = $true,
    [string]$UserName = 'taker',
    [string]$UserPassword = 'chocolatepancakes'
)

BeforeAll {
    . "$PSScriptRoot/PwshOpcUaClient/PwshOpcUaClient.ps1"
    . "$PSScriptRoot/ModelTestController.ps1"
    . "$PSScriptRoot/MethodCallException.ps1"
    . "$PSScriptRoot/BasicMCController.ps1"

    $AccessUserIdentity = [string]::IsNullOrEmpty($UserName) `
                            ? (New-Object UserIdentity) `
                            : (New-Object UserIdentity -ArgumentList $UserName, $UserPassword)
    $clientParam = @{
        ServerUrl = $ServerUrl
        UseSecurity = $UseSecurity
        SessionLifeTime = 60000
        AccessUserIdentity = $AccessUserIdentity
    }
    $client = New-PwshOpcUaClient @clientParam
    $nodeSeparator = $UseSimulator ? '.' : '/'
    $testNode = "ns=$($UseSimulator ? '2;Programs.' : '4;')ModelTest${nodeSeparator}BasicMCController"

    $testController = [ModelTestController]::CreateWrapped($client, $testNode, $nodeSeparator)
    $testController.Initialize()

    $target = [BasicMCController]::new("${testNode}${nodeSeparator}Target", $nodeSeparator)
}

AfterAll {
    $testController.Dispose()
    $testController = $null
    Dispose-PwshOpcUaClient -Client $client
    $client = $null
}

Describe 'Axis' -Tag 'Property' {
    It '現在対象としてる軸の軸情報を返す' -Tag 'Normal' {
        $target.SetAxisIndex($client.Session, 1)

        $axis = $target.Axis($client.Session)

        $axis.Cfg.AxNo
            | Should -Be 1
        $axis.Cfg.AxEnable
            | Should -BeTrue
    }

    It 'Sessionが不正であるとき、例外が発生する' -Tag 'Semi-Normal' {
        { $target.Axis($null) }
            | Should -Throw
    }

    AfterEach {
        $testController.TearDown()
    }
}

Describe 'AxisIndex' -Tag 'Property' {
    It '現在対象としてる軸のインデックスを返す' -Tag 'Normal' {
        $target.SetAxisIndex($client.Session, 1)

        $axisIndex = $target.AxisIndex($client.Session)

        $axisIndex
            | Should -Be 1
    }

    It 'Sessionが不正であるとき、例外が発生する' -Tag 'Abnormal' {
        { $target.AxisIndex($null) }
            | Should -Throw
    }

    AfterEach {
        $testController.TearDown()
    }
}

Describe 'SetAxisIndex' -Tag 'Method' {
    It '対象とする軸をインデックスで指定する' -Tag 'Normal' {
        $ok = $target.SetAxisIndex($client.Session, 1)

        $ok | Should -BeTrue
        $target.AxisIndex($client.Session)
            | Should -Be 1
    }

    It 'インデックスが範囲外のときFalseを返す。' -Tag 'Semi-Normal' {
        $target.SetAxisIndex($client.Session, 1)

        $ok = $target.SetAxisIndex($client.Session, 16)

        $ok | Should -BeFalse
        $target.AxisIndex($client.Session)
            | Should -Be 1
    }

    It 'Sessionが不正であるとき、例外が発生する' -Tag 'Abnormal' {
        { $target.SetAxisIndex($null, 1) }
            | Should -Throw
    }
        
    AfterEach {
        $testController.TearDown()
    }
}

Describe 'MoveAbsolute' -Tag 'Method', 'Motion' {
    It '指定したパラメータで絶対座標での位置決めを行うタスクを生成する' -Tag 'Normal' {
        $testController.SetAxisIndex(0)
        $testController.ServoOn()
        $target.SetAxisIndex($client.Session, 0)
        $target.Home($client.Session)
        $position = 10.0
        $motionContext = @{
            Position     = [double]$position
            Velocity     = [double]5.0
            Acceleration = [double]2.0
            Deceleration = [double]2.0
            Jerk         = [double]0.0
            Direction    = [uint32]0
            BufferMode   = [uint32]0
        }

        $motionTask = $target.MoveAbsolute($client.Session, $motionContext)
        $ok = $motionTask.Execute()
        while (-not $motionTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $result = $motionTask.GetResult()
        $motionTask.Dispose()
        
        $ok | Should -BeTrue
        $result.Error
            | Should -BeFalse
        $result.ErrorID
            | Should -Be 0
        $result.CommandAborted
            | Should -BeFalse
        $axis = $target.Axis($client.Session)
        [Math]::Abs($axis.Act.Pos - $position)
            | Should -BeLessThan 0.0001
        $axis.Status.Standstill
            | Should -BeTrue
    }

    It '動作中にドライバアラームが発生したとき、タスクは完了する' -Tag 'Semi-Normal' {
        $testController.SetAxisIndex(0)
        $testController.ServoOn()
        $target.SetAxisIndex($client.Session, 0)
        $target.Home($client.Session)
        $motionContext = @{
            Position     = [double]100.0
            Velocity     = [double]5.0
            Acceleration = [double]2.0
            Deceleration = [double]2.0
            Jerk         = [double]0.0
            Direction    = [uint32]0
            BufferMode   = [uint32]0
        }

        $motionTask = $target.MoveAbsolute($client.Session, $motionContext)
        $ok = $motionTask.Execute()
        Start-Sleep -Milliseconds 500
        $testController.FireDriverAlarm()
        while (-not $motionTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $result = $motionTask.GetResult()
        $motionTask.Dispose()

        $ok | Should -BeTrue
        $result.Error
            | Should -BeFalse
        $result.ErrorID
            | Should -Be 0
        $result.CommandAborted
            | Should -BeTrue
        $axis = $target.Axis($client.Session)
        $axis.Status.ErrorStop
            | Should -BeTrue
        $axis.MFaultLvl.Active
            | Should -BeTrue
        $axis.MFaultLvl.Code
            | Should -Not -Be 0
    }

    It '動作中に正方向限界入力信号が発生したとき、タスクは完了する' -Tag 'Semi-Normal' {
        $testController.SetAxisIndex(0)
        $testController.ServoOn()
        $target.SetAxisIndex($client.Session, 0)
        $target.Home($client.Session)
        $motionContext = @{
            Position     = [double]100.0
            Velocity     = [double]5.0
            Acceleration = [double]2.0
            Deceleration = [double]2.0
            Jerk         = [double]0.0
            Direction    = [uint32]0
            BufferMode   = [uint32]0
        }

        $motionTask = $target.MoveAbsolute($client.Session, $motionContext)
        $ok = $motionTask.Execute()
        Start-Sleep -Milliseconds 500
        $testController.EnablePositiveLimitSignal()
        while (-not $motionTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $result = $motionTask.GetResult()
        $motionTask.Dispose()

        $ok | Should -BeTrue
        $result.Error
            | Should -BeFalse
        $result.ErrorID
            | Should -Be 0
        $result.CommandAborted
            | Should -BeTrue
        $axis = $target.Axis($client.Session)
        $axis.Status.ErrorStop
            | Should -BeTrue
        $axis.DrvStatus.P_OT
            | Should -BeTrue
        $axis.MFaultLvl.Active
            | Should -BeTrue
        $axis.MFaultLvl.Code
            | Should -Not -Be 0
       $testController.DisablePositiveLimitSignal()
    }

    It '動作中に負方向限界入力信号が発生したとき、タスクは完了する' -Tag 'Semi-Normal' {
        $testController.SetAxisIndex(0)
        $testController.ServoOn()
        $target.SetAxisIndex($client.Session, 0)
        $target.Home($client.Session)
        $motionContext = @{
            Position     = [double]100.0
            Velocity     = [double]5.0
            Acceleration = [double]2.0
            Deceleration = [double]2.0
            Jerk         = [double]0.0
            Direction    = [uint32]0
            BufferMode   = [uint32]0
        }

        $motionTask = $target.MoveAbsolute($client.Session, $motionContext)
        $ok = $motionTask.Execute()
        Start-Sleep -Milliseconds 500
        $testController.EnableNegativeLimitSignal()
        while (-not $motionTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $result = $motionTask.GetResult()
        $motionTask.Dispose()

        $ok | Should -BeTrue
        $result.Error
            | Should -BeFalse
        $result.ErrorID
            | Should -Be 0
        $result.CommandAborted
            | Should -BeTrue
        $axis = $target.Axis($client.Session)
        $axis.Status.ErrorStop
            | Should -BeTrue
        $axis.DrvStatus.N_OT
            | Should -BeTrue
        $axis.MFaultLvl.Active
            | Should -BeTrue
        $axis.MFaultLvl.Code
            | Should -Not -Be 0
       $testController.DisableNegativeLimitSignal()
    }

    It '動作中に非常停止信号が発生したとき、タスクは完了する' -Tag 'Semi-Normal' {
        $testController.SetAxisIndex(0)
        $testController.ServoOn()
        $target.SetAxisIndex($client.Session, 0)
        $target.Home($client.Session)
        $motionContext = @{
            Position     = [double]100.0
            Velocity     = [double]5.0
            Acceleration = [double]2.0
            Deceleration = [double]2.0
            Jerk         = [double]0.0
            Direction    = [uint32]0
            BufferMode   = [uint32]0
        }

        $motionTask = $target.MoveAbsolute($client.Session, $motionContext)
        $ok = $motionTask.Execute()
        Start-Sleep -Milliseconds 500
        $testController.EnableEmergencyStopSignal()
        while (-not $motionTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $result = $motionTask.GetResult()
        $motionTask.Dispose()

        $ok | Should -BeTrue
        $result.Error
            | Should -BeFalse
        $result.ErrorID
            | Should -Be 0
        $result.CommandAborted
            | Should -BeTrue
        $axis = $target.Axis($client.Session)
        $axis.Status.ErrorStop
            | Should -BeTrue
        $axis.MFaultLvl.Active
            | Should -BeTrue
        $axis.MFaultLvl.Code
            | Should -Not -Be 0
        $testController.DisableEmergencyStopSignal()
    }

    It 'Sessionが不正であるとき、例外が発生する' -Tag 'Abnormal' {
        $testController.SetAxisIndex(0)
        $testController.ServoOn()
        $target.SetAxisIndex($client.Session, 0)
        $target.Home($client.Session)
        $motionContext = @{
            Position     = [double]10.0
            Velocity     = [double]5.0
            Acceleration = [double]2.0
            Deceleration = [double]2.0
            Jerk         = [double]0.0
            Direction    = [uint32]0
            BufferMode   = [uint32]0
        }

        { $target.MoveAbsolute($null, $motionContext) }
            | Should -Throw
    }
        
    AfterEach {
        $testController.TearDown()
    }
}

Describe 'MoveRelative' -Tag 'Method', 'Motion' {
    It '指定したパラメータで相対座標での位置決めを行うタスクを生成する' -Tag 'Normal' {
        $testController.SetAxisIndex(0)
        $testController.ServoOn()
        $target.SetAxisIndex($client.Session, 0)
        $target.SetPosition($client.Session, 100.0, 0)
        $prevPos = $target.Axis($client.Session).Act.Pos
        $distance = 10.0
        $motionContext = @{
            Distance     = [double]$distance
            Velocity     = [double]5.0
            Acceleration = [double]2.0
            Deceleration = [double]2.0
            Jerk         = [double]0.0
            BufferMode   = [uint32]0
        }

        $motionTask = $target.MoveRelative($client.Session, $motionContext)
        $ok = $motionTask.Execute()
        while (-not $motionTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $result = $motionTask.GetResult()
        $motionTask.Dispose()
        
        $ok | Should -BeTrue
        $result.Error
            | Should -BeFalse
        $result.ErrorID
            | Should -Be 0
        $result.CommandAborted
            | Should -BeFalse
        $axis = $target.Axis($client.Session)
        [Math]::Abs(($axis.Act.Pos - $prevPos) - $distance)
            | Should -BeLessThan 0.0001
        $axis.Status.Standstill
            | Should -BeTrue
    }

    It '動作中にドライバアラームが発生したとき、タスクは完了する' -Tag 'Semi-Normal' {
        $testController.SetAxisIndex(0)
        $testController.ServoOn()
        $target.SetAxisIndex($client.Session, 0)
        $target.Home($client.Session)
        $motionContext = @{
            Distance     = [double]100.0
            Velocity     = [double]5.0
            Acceleration = [double]2.0
            Deceleration = [double]2.0
            Jerk         = [double]0.0
            BufferMode   = [uint32]0
        }

        $motionTask = $target.MoveRelative($client.Session, $motionContext)
        $ok = $motionTask.Execute()
        Start-Sleep -Milliseconds 500
        $testController.FireDriverAlarm()
        while (-not $motionTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $result = $motionTask.GetResult()
        $motionTask.Dispose()
        
        $ok | Should -BeTrue
        $result.Error
            | Should -BeFalse
        $result.ErrorID
            | Should -Be 0
        $result.CommandAborted
            | Should -BeTrue
        $axis = $target.Axis($client.Session)
        $axis.Status.ErrorStop
            | Should -BeTrue
        $axis.MFaultLvl.Active
            | Should -BeTrue
        $axis.MFaultLvl.Code
            | Should -Not -Be 0
    }

    It '動作中に正方向限界入力号が発生したとき、タスクは完了する' -Tag 'Semi-Normal' {
        $testController.SetAxisIndex(0)
        $testController.ServoOn()
        $target.SetAxisIndex($client.Session, 0)
        $target.Home($client.Session)
        $motionContext = @{
            Distance     = [double]100.0
            Velocity     = [double]5.0
            Acceleration = [double]2.0
            Deceleration = [double]2.0
            Jerk         = [double]0.0
            BufferMode   = [uint32]0
        }

        $motionTask = $target.MoveRelative($client.Session, $motionContext)
        $ok = $motionTask.Execute()
        Start-Sleep -Milliseconds 500
        $testController.EnablePositiveLimitSignal()
        while (-not $motionTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $result = $motionTask.GetResult()
        $motionTask.Dispose()
        
        $ok | Should -BeTrue
        $result.Error
            | Should -BeFalse
        $result.ErrorID
            | Should -Be 0
        $result.CommandAborted
            | Should -BeTrue
        $axis = $target.Axis($client.Session)
        $axis.Status.ErrorStop
            | Should -BeTrue
        $axis.DrvStatus.P_OT
            | Should -BeTrue
        $axis.MFaultLvl.Active
            | Should -BeTrue
        $axis.MFaultLvl.Code
            | Should -Not -Be 0
        $testController.DisablePositiveLimitSignal()
    }

    It '動作中に負方向限界入力信号が発生したとき、タスクは完了する' -Tag 'Semi-Normal' {
        $testController.SetAxisIndex(0)
        $testController.ServoOn()
        $target.SetAxisIndex($client.Session, 0)
        $target.Home($client.Session)
        $motionContext = @{
            Distance     = [double]100.0
            Velocity     = [double]5.0
            Acceleration = [double]2.0
            Deceleration = [double]2.0
            Jerk         = [double]0.0
            BufferMode   = [uint32]0
        }

        $motionTask = $target.MoveRelative($client.Session, $motionContext)
        $ok = $motionTask.Execute()
        Start-Sleep -Milliseconds 500
        $testController.EnableNegativeLimitSignal()
        while (-not $motionTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $result = $motionTask.GetResult()
        $motionTask.Dispose()
        
        $ok | Should -BeTrue
        $result.Error
            | Should -BeFalse
        $result.ErrorID
            | Should -Be 0
        $result.CommandAborted
            | Should -BeTrue
        $axis = $target.Axis($client.Session)
        $axis.Status.ErrorStop
            | Should -BeTrue
        $axis.DrvStatus.N_OT
            | Should -BeTrue
        $axis.MFaultLvl.Active
            | Should -BeTrue
        $axis.MFaultLvl.Code
            | Should -Not -Be 0
        $testController.DisableNegativeLimitSignal()
    }

    It '動作中に非常停止信号が発生したとき、タスクは完了する' -Tag 'Semi-Normal' {
        $testController.SetAxisIndex(0)
        $testController.ServoOn()
        $target.SetAxisIndex($client.Session, 0)
        $target.Home($client.Session)
        $motionContext = @{
            Distance     = [double]100.0
            Velocity     = [double]5.0
            Acceleration = [double]2.0
            Deceleration = [double]2.0
            Jerk         = [double]0.0
            BufferMode   = [uint32]0
        }

        $motionTask = $target.MoveRelative($client.Session, $motionContext)
        $ok = $motionTask.Execute()
        Start-Sleep -Milliseconds 500
        $testController.EnableEmergencyStopSignal()
        while (-not $motionTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $result = $motionTask.GetResult()
        $motionTask.Dispose()
        
        $ok | Should -BeTrue
        $result.Error
            | Should -BeFalse
        $result.ErrorID
            | Should -Be 0
        $result.CommandAborted
            | Should -BeTrue
        $axis = $target.Axis($client.Session)
        $axis.Status.ErrorStop
            | Should -BeTrue
        $axis.MFaultLvl.Active
            | Should -BeTrue
        $axis.MFaultLvl.Code
            | Should -Not -Be 0
        $testController.DisableEmergencyStopSignal()
    }

    It 'Sessionが不正であるとき、例外が発生する' -Tag 'Abnormal' {
        $testController.SetAxisIndex(0)
        $testController.ServoOn()
        $target.SetAxisIndex($client.Session, 0)
        $target.SetPosition($client.Session, 100.0, 0)
        $motionContext = @{
            Distance     = [double]10.0
            Velocity     = [double]5.0
            Acceleration = [double]2.0
            Deceleration = [double]2.0
            Jerk         = [double]0.0
            BufferMode   = [uint32]0
        }

        { $target.MoveRelative($null, $motionContext) }
            | Should -Throw
    }
        
    AfterEach {
        $testController.TearDown()
    }
}

Describe 'MoveZeroPosition' -Tag 'Method', 'Motion' {
    It '選択している軸を指定したパラメータで原点に戻す' -Tag 'Normal' {
        $testController.SetAxisIndex(0)
        $testController.ServoOn()
        $target.SetAxisIndex($client.Session, 0)
        $target.Home($client.Session)
        $motionTask = $target.MoveAbsolute($client.Session, @{
            Position     = [double]10.0
            Velocity     = [double]5.0
            Acceleration = [double]2.0
            Deceleration = [double]2.0
            Jerk         = [double]0.0
            Direction    = [uint32]0
            BufferMode   = [uint32]0
        })
        $motionTask.Execute()
        while (-not $motionTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $motionTask.Dispose()
        $motionContext = @{
            Velocity     = [double]5.0
            Acceleration = [double]2.0
            Deceleration = [double]2.0
            Jerk         = [double]0.0
            BufferMode   = [uint32]0
        }

        $motionTask = $target.MoveZeroPosition($client.Session, $motionContext)
        $ok = $motionTask.Execute()
        while (-not $motionTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $result = $motionTask.GetResult()
        $motionTask.Dispose()
        
        $ok | Should -BeTrue
        $result.Error
            | Should -BeFalse
        $result.ErrorID
            | Should -Be 0
        $result.CommandAborted
            | Should -BeFalse
        $axis = $target.Axis($client.Session)
        [Math]::Abs($axis.Act.Pos)
            | Should -BeLessThan 0.0001
        $axis.Status.Standstill
            | Should -BeTrue
    }

    It '動作中にドライバアラームが発生したとき、タスクは完了する' -Tag 'Semi-Normal' {
        $testController.SetAxisIndex(0)
        $testController.ServoOn()
        $target.SetAxisIndex($client.Session, 0)
        $target.Home($client.Session)
        $motionTask = $target.MoveAbsolute($client.Session, @{
            Position     = [double]5.0
            Velocity     = [double]5.0
            Acceleration = [double]5.0
            Deceleration = [double]2.0
            Jerk         = [double]0.0
            Direction    = [uint32]0
            BufferMode   = [uint32]0
        })
        $motionTask.Execute()
        while (-not $motionTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $motionTask.Dispose()
        $motionContext = @{
            Velocity     = [double]1.0
            Acceleration = [double]1.0
            Deceleration = [double]1.0
            Jerk         = [double]0.0
            BufferMode   = [uint32]0
        }

        $motionTask = $target.MoveZeroPosition($client.Session, $motionContext)
        $ok = $motionTask.Execute()
        Start-Sleep -Milliseconds 500
        $testController.FireDriverAlarm()
        while (-not $motionTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $result = $motionTask.GetResult()
        $motionTask.Dispose()

        $ok | Should -BeTrue
        $result.Error
            | Should -BeFalse
        $result.ErrorID
            | Should -Be 0
        $result.CommandAborted
            | Should -BeTrue
        $axis = $target.Axis($client.Session)
        $axis.Status.ErrorStop
            | Should -BeTrue
        $axis.MFaultLvl.Active
            | Should -BeTrue
        $axis.MFaultLvl.Code
            | Should -Not -Be 0
    }

    It '動作中に正方向限界入力信号が発生したとき、タスクは完了する' -Tag 'Semi-Normal' {
        $testController.SetAxisIndex(0)
        $testController.ServoOn()
        $target.SetAxisIndex($client.Session, 0)
        $target.Home($client.Session)
        $motionTask = $target.MoveAbsolute($client.Session, @{
            Position     = [double]5.0
            Velocity     = [double]5.0
            Acceleration = [double]5.0
            Deceleration = [double]2.0
            Jerk         = [double]0.0
            Direction    = [uint32]0
            BufferMode   = [uint32]0
        })
        $motionTask.Execute()
        while (-not $motionTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $motionTask.Dispose()
        $motionContext = @{
            Velocity     = [double]1.0
            Acceleration = [double]1.0
            Deceleration = [double]1.0
            Jerk         = [double]0.0
            BufferMode   = [uint32]0
        }

        $motionTask = $target.MoveZeroPosition($client.Session, $motionContext)
        $ok = $motionTask.Execute()
        Start-Sleep -Milliseconds 500
        $testController.EnablePositiveLimitSignal()
        while (-not $motionTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $result = $motionTask.GetResult()
        $motionTask.Dispose()

        $ok | Should -BeTrue
        $result.Error
            | Should -BeFalse
        $result.ErrorID
            | Should -Be 0
        $result.CommandAborted
            | Should -BeTrue
        $axis = $target.Axis($client.Session)
        $axis.Status.ErrorStop
            | Should -BeTrue
        $axis.DrvStatus.P_OT
            | Should -BeTrue
        $axis.MFaultLvl.Active
            | Should -BeTrue
        $axis.MFaultLvl.Code
            | Should -Not -Be 0
        $testController.DisablePositiveLimitSignal()
    }

    It '動作中に負方向限界入力信号が発生したとき、タスクは完了する' -Tag 'Semi-Normal' {
        $testController.SetAxisIndex(0)
        $testController.ServoOn()
        $target.SetAxisIndex($client.Session, 0)
        $target.Home($client.Session)
        $motionTask = $target.MoveAbsolute($client.Session, @{
            Position     = [double]5.0
            Velocity     = [double]5.0
            Acceleration = [double]5.0
            Deceleration = [double]2.0
            Jerk         = [double]0.0
            Direction    = [uint32]0
            BufferMode   = [uint32]0
        })
        $motionTask.Execute()
        while (-not $motionTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $motionTask.Dispose()
        $motionContext = @{
            Velocity     = [double]1.0
            Acceleration = [double]1.0
            Deceleration = [double]1.0
            Jerk         = [double]0.0
            BufferMode   = [uint32]0
        }

        $motionTask = $target.MoveZeroPosition($client.Session, $motionContext)
        $ok = $motionTask.Execute()
        Start-Sleep -Milliseconds 500
        $testController.EnableNegativeLimitSignal()
        while (-not $motionTask.CheckDone()) { Start-Sleep -Milliseconds 300 }
        $result = $motionTask.GetResult()
        $motionTask.Dispose()

        $ok | Should -BeTrue
        $result.Error
            | Should -BeFalse
        $result.ErrorID
            | Should -Be 0
        $result.CommandAborted
            | Should -BeTrue
        $axis = $target.Axis($client.Session)
        $axis.Status.ErrorStop
            | Should -BeTrue
        $axis.DrvStatus.N_OT
            | Should -BeTrue
        $axis.MFaultLvl.Active
            | Should -BeTrue
        $axis.MFaultLvl.Code
            | Should -Not -Be 0
        $testController.DisableNegativeLimitSignal()
    }

    It 'Sessionが不正であるとき、例外が発生する' -Tag 'Abnormal' {
        $testController.SetAxisIndex(0)
        $testController.ServoOn()
        $target.SetAxisIndex($client.Session, 0)
        $target.Home($client.Session)
        $motionContext = @{
            Velocity     = [double]5.0
            Acceleration = [double]2.0
            Deceleration = [double]2.0
            Jerk         = [double]0.0
            BufferMode   = [uint32]0
        }

        { $target.MoveZeroPosition($null, $motionContext) }
            | Should -Throw
    }
        
    AfterEach {
        $testController.TearDown()
    }
}

Describe 'Home' -Tag 'Method' {
    It '現在選択している軸の原点を決める' -Tag 'Normal' {
        $testController.SetAxisIndex(0)
        $testController.ServoOn()
        $target.SetAxisIndex($client.Session, 0)
        $target.SetPosition($client.Session, 100.0, 0)
        $axis.Details.Homed
            | Should -BeFalse
        
        $result = $target.Home($client.Session)
        
        $result.Error
            | Should -BeFalse
        $result.ErrorID
            | Should -Be 0
        $result.CommandAborted
            | Should -BeFalse
        $axis = $target.Axis($client.Session)
        $axis.Details.Homed
            | Should -BeTrue
        $axis.Act.Pos
            | Should -Be 0
    }
    # TODO: モーションを伴う原点復帰モード

    It 'Sessionが不正であるとき、例外が発生する' -Tag 'Abnormal' {
        { $target.Home($null) }
            | Should -Throw
    }
        
    AfterEach {
        $testController.TearDown()
    }
}

Describe 'SetPosition' -Tag 'Method' {
    It '現在選択している軸の現在指令位置、フィードバック現在位置を設定する' -Tag 'Normal' {
        $testController.SetAxisIndex(0)
        $testController.ServoOn()
        $target.SetAxisIndex($client.Session, 0)
        $target.Home($client.Session)
        $axis = $target.Axis($client.Session)
        $axis.Act.Pos
            | Should -Be 0
        $axis.Details.Homed
            | Should -BeTrue
        $position = 100.0
        
        $result = $target.SetPosition($client.Session, $position, 0)
        
        $result.Error
            | Should -BeFalse
        $result.ErrorID
            | Should -Be 0
        $result.CommandAborted
            | Should -BeFalse
        $axis = $target.Axis($client.Session)
        [Math]::Abs($axis.Act.Pos - $position)
            | Should -BeLessThan 0.0001
        $axis.Details.Homed
            | Should -BeFalse
    }

    It 'Sessionが不正であるとき、例外が発生する' -Tag 'Abnormal' {
        { $target.SetPosition($null, 100,0, 0) }
            | Should -Throw
    }
        
    AfterEach {
        $testController.TearDown()
    }
}

Describe 'ResetAxisError' -Tag 'Method' {
    It '現在選択している軸の異常をクリアする' -Tag 'Normal' {
        $testController.SetAxisIndex(0)
        $testController.ServoOn()
        $testController.FireDriverAlarm()
        $target.SetAxisIndex($client.Session, 0)
        $axis = $target.Axis($client.Session)
        $axis.MFaultLvl.Active
            | Should -BeTrue
        
        $result = $target.ResetAxisError($client.Session)
        
        $result.Error
            | Should -BeFalse
        $result.ErrorID
            | Should -Be 0
        $result.Failuer
            | Should -BeFalse
        $axis = $target.Axis($client.Session)
        $axis.MFaultLvl.Active
            | Should -BeFalse
    }

    It 'エラーが発生していないときに実行しても何も起こらない' -Tag 'Normal' {
        $testController.SetAxisIndex(0)
        $testController.ServoOn()
        $target.SetAxisIndex($client.Session, 0)
        $axis = $target.Axis($client.Session)
        $axis.MFaultLvl.Active
            | Should -BeFalse
        
        $ok = $target.ResetAxisError($client.Session)
        
        $ok | Should -BeTrue
        $axis = $target.Axis($client.Session)
        $axis.MFaultLvl.Active
            | Should -BeFalse
    }

    It 'Sessionが不正であるとき、例外が発生する' -Tag 'Abnormal' {
        { $target.ResetAxisError($null) }
            | Should -Throw
    }
        
    AfterEach {
        $testController.TearDown()
    }
}
