<#
GNU General Public License, Version 2.0

Copyright (C) 2025 KITA Munemitsu
https://github.com/kmu2030

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
using namespace Opc.Ua.Client

class ModelTestController {
    [hashtable] $Methods = $null
    [hashtable] $MethodTasks = $null
    [string] $BaseNodeId = ''
    [string] $NodeSeparator = '.'

    static [PSCustomObject] CreateWrapped([object]$Client, [string]$BaseNodeId, [string]$NodeSeparator) {
        $controller = [ModelTestController]::new($BaseNodeId, $NodeSeparator)
        $obj = [PSCustomObject]@{
            Client = $client
            Controller = $controller
        }

        $_methods = $controller.GetType().GetMethods()
        foreach ($method in $_methods) {
            $methodName = $method.Name

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
            $this.Client = $null
            $this.Controller = $null
        }

        return $obj
    }

    ModelTestController([string]$BaseNodeId) {
        $this.Init($BaseNodeId, '.')
    }

    ModelTestController([string]$BaseNodeId, [string]$NodeSeparator) {
        $this.Init($BaseNodeId, $NodeSeparator)
    }

    hidden [void] Init([string]$BaseNodeId, [string]$NodeSeparator) {
        $this.BaseNodeId = $BaseNodeId
        $this.NodeSeparator = $NodeSeparator
        $this.Methods = @{}
        $this.MethodTasks = @{}
    }

    hidden [void] DefineExecuteMethod([hashtable]$Definition) {
        $methodName = $Definition.Name

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

        $this.Methods[$methodName] = @{
            CallParams = $callParams
            DoneParams = $doneParams
            ClearParams = $clearParams
            InProcessor = $Definition.InProcessor
            OutProcessor = $Definition.OutProcessor
            OnCalled = $Definition.OnCalled
            OnDone = $Definition.OnDone
            OnCleared = $Definition.OnCleared
        }
    }

    hidden [void] DefineStrictExecuteMethod([hashtable]$Definition) {
        $methodName = $Definition.Name

        $checkCallableParams = [ReadValueIdCollection]::new()
        $checkCallableParam = New-Object ReadValueId -Property @{
            AttributeId = [Attributes]::Value
        }
        $checkCallableParam.NodeId = [NodeId]::new((@($this.BaseNodeId, $methodName, 'Busy') -join $this.NodeSeparator))
        $checkCallableParams.Add($checkCallableParam)

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

        $checkClearedParams = [ReadValueIdCollection]::new()
        $checkClearedParam = New-Object ReadValueId -Property @{
            AttributeId = [Attributes]::Value
        }
        $checkClearedParam.NodeId = [NodeId]::new((@($this.BaseNodeId, $methodName, 'Done') -join $this.NodeSeparator))
        $checkClearedParams.Add($checkClearedParam)

        $this.Methods[$methodName] = @{
            CheckCallableParams = $checkCallableParams
            CallParams = $callParams
            DoneParams = $doneParams
            ClearParams = $clearParams
            CheckClearedParams = $checkClearedParams
            InProcessor = $Definition.InProcessor
            OutProcessor = $Definition.OutProcessor
            OnCalled = $Definition.OnCalled
            OnDone = $Definition.OnDone
            OnCleared = $Definition.OnCleared
        }
    }

    hidden [void] DefineEnableMethod([hashtable]$Definition) {
        $methodName = $Definition.Name

        $checkCallableParams = [ReadValueIdCollection]::new()
        $checkCallableParam = New-Object ReadValueId -Property @{
            AttributeId = [Attributes]::Value
        }
        $checkCallableParam.NodeId = [NodeId]::new((@($this.BaseNodeId, $methodName, 'Busy') -join $this.NodeSeparator))
        $checkCallableParams.Add($checkCallableParam)

        $callParams = [WriteValueCollection]::new()
        foreach ($p in $Definition.InParams) {
            $callParam = [WriteValue]::new()
            $callParam.NodeId = [NodeId]::new((@($this.BaseNodeId, $methodName, $p) -join $this.NodeSeparator))
            $callParam.AttributeId = [Attributes]::Value
            $callParam.Value = [DataValue]::new()
            $callParams.Add($callParam)
        }
        $callParam = [WriteValue]::new()
        $callParam.NodeId = [NodeId]::new((@($this.BaseNodeId, $methodName, 'Enable') -join $this.NodeSeparator))
        $callParam.AttributeId = [Attributes]::Value
        $callParam.Value = [DataValue]::new()
        $callParam.Value.Value = $true
        $callParams.Add($callParam)

        $busyParams = [ReadValueIdCollection]::new()
        $busyParam = New-Object ReadValueId -Property @{
            AttributeId = [Attributes]::Value
        }
        $busyParam.NodeId = [NodeId]::new((@($this.BaseNodeId, $methodName, 'Busy') -join $this.NodeSeparator))
        $busyParams.Add($busyParam)
        foreach ($p in $Definition.OutParams) {
            $busyParam = New-Object ReadValueId -Property @{
                AttributeId = [Attributes]::Value
            }
            $busyParam.NodeId = [NodeId]::new((@($this.BaseNodeId, $methodName, $p) -join $this.NodeSeparator))
            $busyParams.Add($busyParam)
        }

        $clearParams = [WriteValueCollection]::new()
        $clearParam = [WriteValue]::new()
        $clearParam.NodeId = [NodeId]::new((@($this.BaseNodeId, $methodName, 'Enable') -join $this.NodeSeparator))
        $clearParam.AttributeId = [Attributes]::Value
        $clearParam.Value = [DataValue]::new()
        $clearParam.Value.Value = $false
        $clearParams.Add($clearParam)

        $checkClearedParams = [ReadValueIdCollection]::new()
        $checkClearedParam = New-Object ReadValueId -Property @{
            AttributeId = [Attributes]::Value
        }
        $checkClearedParam.NodeId = [NodeId]::new((@($this.BaseNodeId, $methodName, 'Busy') -join $this.NodeSeparator))
        $checkClearedParams.Add($checkClearedParam)

        $this.Methods[$methodName] = @{
            CheckCallableParams = $checkCallableParams
            CallParams = $callParams
            BusyParams = $busyParams
            ClearParams = $clearParams
            CheckClearedParams = $checkClearedParams
            InProcessor = $Definition.InProcessor
            OutProcessor = $Definition.OutProcessor
            OnCalled = $Definition.OnCalled
            OnBusy = $Definition.OnBusy
            OnCleared = $Definition.OnCleared
        }
    }

    hidden [Object] CallMethod(
        [ISession]$Session,
        [hashtable]$Context
    ) {
        return $this.CallMethod($Session, $Context, $null)
    }

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
            if ($null -ne $Context.CheckCallableParams) {
                $results= [DataValueCollection]::new()
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
    
            $results= [DataValueCollection]::new()
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

            if ($null -ne $Context.CheckClearedParams) {
                $results= [DataValueCollection]::new()
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

    hidden [ModelTestControllerEnableMethodTask] CreateEnableMethodTask(
        [ISession]$Session,
        [hashtable]$Context
    ) { return $this.CreateEnableMethodTask($Session, $Context, $null) }

    hidden [ModelTestControllerEnableMethodTask] CreateEnableMethodTask(
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

        return [ModelTestControllerEnableMethodTask]::new($Session, $Context)
    }

    hidden [Object] ValidateResponse($Response, $Results, $DiagnosticInfos, $Requests, $ExceptionMessage) {
        if (($Results
                | Where-Object { $_ -is [StatusCode]}
                | ForEach-Object { [ServiceResult]::IsNotGood($_) }
            ) -contains $true `
            -or ($Results.Count -ne $Requests.Count)
        ) {
            return [ModelTestControllerMethodCallException]::new($ExceptionMessage, @{
                Response = $Response
                Results = $Results
                DiagnosticInfos = $DiagnosticInfos
            })
        } else {
            return $null
        }
    }

    [hashtable] GetMethodContext([string]$Name) {
        if ($null -eq $this.Methods.$Name) { return $null }

        return @{
            CheckCallableParams = $this.Methods.$Name.CheckCallableParams?.Clone()
            CallParams = $this.Methods.$Name.CallParams?.Clone()
            BusyParams = $this.Methods.$Name.BusyParams?.Clone()
            DoneParams = $this.Methods.$Name.DoneParams?.Clone()
            ClearParams = $this.Methods.$Name.ClearParams?.Clone()
            CheckClearedParams = $this.Methods.$Name.CheckClearedParams?.Clone()
            InProcessor = $this.Methods.$Name.InProcessor
            OutProcessor = $this.Methods.$Name.OutProcessor
            OnCalled = $this.Methods.$Name.OnCalled
            OnBusy = $this.Methods.$Name.OnBusy
            OnCleared = $this.Methods.$Name.OnCleared
        }
    }

    hidden [object] GetMethodTask([string]$Name) {
        return $this.MethodTasks.$Name
    }

    hidden [void] SetMethodTask([string]$Name, [object]$task) {
        if ($null -ne $this.MethodTasks.$Name) { throw "Task: $Name is already exist." }
        $this.MethodTasks[$Name] = $task
    }

    hidden [void] DeleteMethodTask([string]$Name) {
        if ($null -eq $this.MethodTasks.$Name) { return }
        $this.MethodTasks.Remove($Name)
            | Out-Null
    }

    # Refer: POU/FunctionBlock/ModelTest_BasicMCControllerModel/Initialize
    [void] Initialize([ISession]$Session) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName)
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineStrictExecuteMethod(@{
                Name = $methodName
                InParams = @()
                OutParams = @()
                InProcessor = {}
                OutProcessor = {}
            })
            $methodContext = $this.GetMethodContext($methodName)
        }

        $this.CallMethod($Session, $methodContext)
            | Out-Null
    }

    # Refer: POU/FunctionBlock/ModelTest_BasicMCControllerModel/ServoOn
    [void] ServoOn([ISession]$Session) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName)
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineStrictExecuteMethod(@{
                Name = $methodName
                InParams = @()
                OutParams = @()
                InProcessor = {}
                OutProcessor = {}
            })
            $methodContext = $this.GetMethodContext($methodName)
        }

        $this.CallMethod($Session, $methodContext)
            | Out-Null
    }

    # Refer: POU/FunctionBlock/ModelTest_BasicMCControllerModel/ServoOff
    [void] ServoOff([ISession]$Session) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName)
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineStrictExecuteMethod(@{
                Name = $methodName
                InParams = @()
                OutParams = @()
                InProcessor = {}
                OutProcessor = {}
            })
            $methodContext = $this.GetMethodContext($methodName)
        }

        $this.CallMethod($Session, $methodContext)
            | Out-Null
    }

    # Refer: POU/FunctionBlock/ModelTest_BasicMCControllerModel/Stop
    [void] Stop([ISession]$Session) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName)
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineStrictExecuteMethod(@{
                Name = $methodName
                InParams = @()
                OutParams = @()
                InProcessor = {}
                OutProcessor = {}
            })
            $methodContext = $this.GetMethodContext($methodName)
        }

        $this.CallMethod($Session, $methodContext)
            | Out-Null
    }

    # Refer: POU/FunctionBlock/ModelTest_BasicMCControllerModel/Home
    [void] Home([ISession]$Session) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName)
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineStrictExecuteMethod(@{
                Name = $methodName
                InParams = @()
                OutParams = @()
                InProcessor = {}
                OutProcessor = {}
            })
            $methodContext = $this.GetMethodContext($methodName)
        }

        $this.CallMethod($Session, $methodContext)
            | Out-Null
    }

   # Refer: POU/FunctionBlock/ModelTest_BasicMCControllerModel/SetAxisIndex
   [void] SetAxisIndex([ISession]$Session, [uint16]$AxisIndex) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName)
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineStrictExecuteMethod(@{
                Name = $methodName
                InParams     = @('Value')
                OutParams    = @()
                InProcessor  = {
                    param($CallArgs, $Context)
                    $Context.CallParams[0].Value.Value = [uint16]$CallArgs[0]
                }
                OutProcessor = {}
            })
            $methodContext = $this.GetMethodContext($methodName)
        }

        $this.CallMethod($Session, $methodContext, @(,$AxisIndex))
            | Out-Null
    }

    # Refer: POU/FunctionBlock/ModelTest_BasicMCControllerModel/FireDriverAlarm
    [void] FireDriverAlarm([ISession]$Session) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName)
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineStrictExecuteMethod(@{
                Name = $methodName
                InParams = @()
                OutParams = @()
                InProcessor = {}
                OutProcessor = {}
            })
            $methodContext = $this.GetMethodContext($methodName)
        }

        $this.CallMethod($Session, $methodContext)
            | Out-Null
    }

    # Refer: POU/FunctionBlock/ModelTest_BasicMCControllerModel/FireDriverWarning
    [void] FireDriverWarning([ISession]$Session) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName)
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineStrictExecuteMethod(@{
                Name = $methodName
                InParams = @()
                OutParams = @()
                InProcessor = {}
                OutProcessor = {}
            })
            $methodContext = $this.GetMethodContext($methodName)
        }

        $this.CallMethod($Session, $methodContext)
            | Out-Null
    }

    # Refer: POU/FunctionBlock/ModelTest_BasicMCControllerModel/FirePositiveLimitSignal
    [void] EnablePositiveLimitSignal([ISession]$Session) {
        $methodName = 'FirePositiveLimitSignal'
        $task = $this.GetMethodTask($methodName)
        if ($null -eq $task) {
            $methodContext = $this.GetMethodContext($methodName)
            if ($null -eq $methodContext) {
                $this.DefineEnableMethod(@{
                    Name = $methodName
                    InParams = @()
                    OutParams = @()
                    InProcessor = {}
                    OutProcessor = {}
                    OnCalled = { Start-Sleep -Milliseconds 20 }
                })
                $methodContext = $this.GetMethodContext($methodName)
            }
            $task = $this.CreateEnableMethodTask($Session, $methodContext)
            if (-not $task.Enable()) {
                $task.Dispose()
                throw 'Failed to fire PositiveLimitSignal.'
            }
            $this.SetMethodTask($methodName, $task)
        }
        if (-not $task.CheckBusy()) { throw "The $methodName task exists, but it is not busy." }
    }

    # Refer: POU/FunctionBlock/ModelTest_BasicMCControllerModel/FirePositiveLimitSignal
    [void] DisablePositiveLimitSignal() {
        $methodName = 'FirePositiveLimitSignal'
        $task = $this.GetMethodTask($methodName)
        if ($null -eq $task) { return }
        $task.Dispose()
        $this.DeleteMethodTask($methodName)
    }

    # Refer: POU/FunctionBlock/ModelTest_BasicMCControllerModel/FireNegativeLimitSignal
    [void] EnableNegativeLimitSignal([ISession]$Session) {
        $methodName = 'FireNegativeLimitSignal'
        $task = $this.GetMethodTask($methodName)
        if ($null -eq $task) {
            $methodContext = $this.GetMethodContext($methodName)
            if ($null -eq $methodContext) {
                $this.DefineEnableMethod(@{
                    Name = $methodName
                    InParams = @()
                    OutParams = @()
                    InProcessor = {}
                    OutProcessor = {}
                    OnCalled = { Start-Sleep -Milliseconds 20 }
                })
                $methodContext = $this.GetMethodContext($methodName)
            }
            $task = $this.CreateEnableMethodTask($Session, $methodContext)
            if (-not $task.Enable()) {
                $task.Dispose()
                throw 'Failed to fire NegativeLimitSignal.'
            }
            $this.SetMethodTask($methodName, $task)
        }
        if (-not $task.CheckBusy()) { throw "The $methodName task exists, but it is not busy." }
    }

    # Refer: POU/FunctionBlock/ModelTest_BasicMCControllerModel/FireNegativeLimitSignal
    [void] DisableNegativeLimitSignal() {
        $methodName = 'FireNegativeLimitSignal'
        $task = $this.GetMethodTask($methodName)
        if ($null -eq $task) { return }
        $task.Dispose()
        $this.DeleteMethodTask($methodName)
    }

    # Refer: POU/FunctionBlock/ModelTest_BasicMCControllerModel/FireEmergencyStopSignal
    [void] EnableEmergencyStopSignal([ISession]$Session) {
        $methodName = 'FireEmergencyStopSignal'
        $task = $this.GetMethodTask($methodName)
        if ($null -eq $task) {
            $methodContext = $this.GetMethodContext($methodName)
            if ($null -eq $methodContext) {
                $this.DefineEnableMethod(@{
                    Name = $methodName
                    InParams = @()
                    OutParams = @()
                    InProcessor = {}
                    OutProcessor = {}
                    OnCalled = { Start-Sleep -Milliseconds 20 }
                })
                $methodContext = $this.GetMethodContext($methodName)
            }
            $task = $this.CreateEnableMethodTask($Session, $methodContext)
            if (-not $task.Enable()) {
                $task.Dispose()
                throw 'Failed to fire EmergencyStopSignal.'
            }
            $this.SetMethodTask($methodName, $task)
        }
        if (-not $task.CheckBusy()) { throw "The $methodName task exists, but it is not busy." }
    }

    # Refer: POU/FunctionBlock/ModelTest_BasicMCControllerModel/FireEmergencyStopSignal
    [void] DisableEmergencyStopSignal() {
        $methodName = 'FireEmergencyStopSignal'
        $task = $this.GetMethodTask($methodName)
        if ($null -eq $task) { return }
        $task.Dispose()
        $this.DeleteMethodTask($methodName)
    }

    [void] DisposeAllMethodTasks() {
        $this.MethodTasks.Values
            | Where-Object { $null -ne $_ }
            | ForEach-Object { $_.Dispose() }
        $this.MethodTasks.Clear()
    }

    # Refer: POU/FunctionBlock/ModelTest_BasicMCControllerModel/TearDown
    [void] TearDown([ISession]$Session) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName)
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineStrictExecuteMethod(@{
                Name = $methodName
                InParams = @()
                OutParams = @()
                InProcessor = {}
                OutProcessor = {}
            })
            $methodContext = $this.GetMethodContext($methodName)
        }

        $this.DisposeAllMethodTasks()
        $this.CallMethod($Session, $methodContext)
            | Out-Null
    }
}

class ModelTestControllerMethodCallException : System.Exception {
    [hashtable]$CallInfo
    ModelTestControllerMethodCallException([string]$Message, [hashtable]$CallInfo) : base($Message) {
        $this.CallInfo = $CallInfo
    }
}

class ModelTestControllerEnableMethodTask {
    [ISession] $Session
    [hashtable] $Context
    [object] $Status
    [bool] $IsEnabled
    [bool] $IsCleared

    ModelTestControllerEnableMethodTask([ISession]$Session, [hashtable]$Context) {
        $this.Session = $Session
        $this.Context = $Context
        $this.Status = $null
        $this.IsEnabled = $false
        $this.IsCleared = $false
    }

    [object] GetStatus() { return $this.Status }

    [bool] Enable() {
        if ($this.IsCleared) { return $false }

        $results = $null
        $diagnosticInfos = $null 
        $exception = $null
        if ($null -ne $this.Context.CheckCallableParams) {
            $results= [DataValueCollection]::new()
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

        $this.IsEnabled = $true

        return $true
    }

    [bool] CheckBusy() {
        if (-not $this.IsEnabled) { return $false }

        $results = [DataValueCollection]::new()
        $diagnosticInfos = [DiagnosticInfoCollection]::new()
        
        $response = $this.Session.Read(
            $null,
            [double]0,
            [TimestampsToReturn]::Both,
            $this.Context.BusyParams,
            [ref]$results,
            [ref]$diagnosticInfos
        )
        if ($null -ne ($exception = $this.ValidateResponse(
                    $response,
                    $results,
                    $diagnosticInfos,
                    $this.Context.BusyParams,
                    'Failed to get status parameters.'))
        ) {
            throw $exception
        }

        if ($results.Count -lt 1 -or -not $results[0].Value) {
            return $false
        }

        if ($null -ne $this.Context.OnBusy) {
            (& $this.Context.OnBusy $response $results $diagnosticInfos $this.Context)
        }

        $outs = New-Object System.Collections.ArrayList
        foreach ($r in $results | Select-Object -Skip 1) {
            $outs.Add($r.Value)
        }

        $this.Status = (& $this.Context.OutProcessor $outs $this.Context)

        return $true
    }

    [void] Disable() {
        $this.ClearParams()
    }

    hidden [void] ClearParams() {
        if (-not $this.IsEnabled -or $this.IsCleared) { return }

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
                    'Failed to clear enable parameters.'))
        ) {
            throw $_exception
        }

        if ($null -ne $this.Context.OnCleared) {
            (& $this.Context.OnCleared $response $results $diagnosticInfos $this.Context)
        }

        if ($null -eq $this.Context.CheckClearedParams) { return }

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

    [void] Dispose() {
        $this.ClearParams()
        $this.Session = $null
        $this.Context = $null
        $this.Status = $null
    }

    hidden [Object] ValidateResponse($Response, $Results, $DiagnosticInfos, $Requests, $ExceptionMessage) {
        if (($Results
                | Where-Object { $_ -is [StatusCode] }
                | ForEach-Object { [ServiceResult]::IsNotGood($_) }
            ) -contains $true `
                -or ($Results.Count -ne $Requests.Count)
        ) {
            return [ModelTestControllerMethodCallException]::new($ExceptionMessage, @{
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