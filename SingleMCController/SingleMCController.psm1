<#
.SYNOPSIS
    このスクリプトをインポートすることで、SingleMCControllerの使用に必要な一連のスクリプトをセッションにロードします。
    PwshOpcUaClientは、セットアップ済みであることが前提です。
.EXAMPLE
    Import-Module ./SingleMCController
#>

. "$PSScriptRoot/Import-Env.ps1"
. "$PSScriptRoot/PwshOpcUaClient/PwshOpcUaClient.ps1"
. "$PSScriptRoot/MethodCallException.ps1"
. "$PSScriptRoot/BasicMCController.ps1"
. "$PSScriptRoot/SingleMCController.ps1"
. "$PSScriptRoot/New-SingleMCController.ps1"

Export-ModuleMember -Function New-SingleMCController, Import-Env
