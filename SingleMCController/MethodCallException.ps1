<#
.SYNOPSIS
    メソッド呼び出し時の例外です。
#>
class MethodCallException : System.Exception {
    [hashtable]$CallInfo
    MethodCallException([string]$Message, [hashtable]$CallInfo) : base($Message) {
        $this.CallInfo = $CallInfo
    }
}
