<#
GNU General Public License, Version 2.0

Copyright (C) 2025 KITA Munemitsu
https://github.com/kmu2030/RingBufferOpcUaExtensionLib

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

class RingBuffer {
    [hashtable] $Methods = $null
    [string] $BaseNodeId = ''
    [string] $NodeSeparator = '.'

    RingBuffer([string]$BaseNodeId) {
        $this.Init($BaseNodeId, '.')
    }

    RingBuffer([string]$BaseNodeId, [string]$NodeSeparator) {
        $this.Init($BaseNodeId, $NodeSeparator)
    }

    hidden [void] Init([string]$BaseNodeId, [string]$NodeSeparator) {
        $this.BaseNodeId = $BaseNodeId
        $this.NodeSeparator = $NodeSeparator
        $this.Methods = @{}
    }

    hidden [void] DefineMethod([hashtable]$MethodDefine) {
        $methodName = $MethodDefine.Name

        $callParams = [WriteValueCollection]::new()
        foreach ($p in $MethodDefine.InParams) {
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
        foreach ($p in $MethodDefine.OutParams) {
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
            InProcessor = $MethodDefine.InProcessor
            OutProcessor = $MethodDefine.OutProcessor
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
        }
    }

    hidden [Object] ValidateResponse($Response, $Results, $DiagnosticInfos, $Requests, $ExceptionMessage) {
        if (($Results
                | Where-Object { $_ -is [StatusCode]}
                | ForEach-Object { [ServiceResult]::IsNotGood($_) }
            ) -contains $true `
            -or ($Results.Count -ne $Requests.Count)
        ) {
            return [MethodCallException]::new($ExceptionMessage, @{
                Response = $Response
                Results = $Results
                DiagnosticInfos = $DiagnosticInfos
            })
        } else {
            return $null
        }
    }

    hidden [hashtable] GetMethodContext([string]$Name) {
        if ($null -eq $this.Methods.$Name) {
            return $null
        }

        return @{
            CallParams = $this.Methods.$Name.CallParams.Clone()
            DoneParams = $this.Methods.$Name.DoneParams.Clone()
            ClearParams = $this.Methods.$Name.ClearParams.Clone()
            InProcessor = $this.Methods.$Name.InProcessor
            OutProcessor = $this.Methods.$Name.OutProcessor
        }
    }

    [hashtable] Read([ISession]$Session, [UInt16]$Size = 0) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName);
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineMethod(@{
                Name = $methodName
                InParams = @('Size')
                OutParams = @('Out', 'ReadSize', 'Overflow')
                InProcessor = {
                    param($CallArgs, $Context)
                    $Context.CallParams[0].Value.Value = [UInt16]$CallArgs[0]
                }
                OutProcessor = {
                    param($Outs, $Context)
                    return @{
                        Out = $Outs[0]
                        ReadSize = $Outs[1]
                        Overflow = $Outs[2]
                    }
                }
            })
            $methodContext = $this.GetMethodContext($methodName);
        }

        return [hashtable]$this.CallMethod($Session, $methodContext, @($Size))
    }

    [hashtable] ReadFully([ISession]$Session) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName);
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineMethod(@{
                Name = $methodName
                InParams = @()
                OutParams = @('Out', 'ReadSize', 'Overflow')
                InProcessor = {}
                OutProcessor = {
                    param($Outs, $Context)
                    return @{
                        Out = $Outs[0]
                        ReadSize = $Outs[1]
                        Overflow = $Outs[2]
                    }
                }
            })
            $methodContext = $this.GetMethodContext($methodName);
        }

        return [hashtable]$this.CallMethod($Session, $methodContext)
    }

    [hashtable] Peek([ISession]$Session, [UInt16]$Size = 0) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName);
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineMethod(@{
                Name = $methodName 
                InParams = @('Size')
                OutParams = @('Out', 'ReadSize', 'Overflow')
                InProcessor = {
                    param($CallArgs, $Context)
                    $Context.CallParams[0].Value.Value = [UInt16]$CallArgs[0]
                }
                OutProcessor = {
                    param($Outs, $Context)
                    return @{
                        Out = $Outs[0]
                        ReadSize = $Outs[1]
                        Overflow = $Outs[2]
                    }
                }
            })
            $methodContext = $this.GetMethodContext($methodName);
        }

        return [hashtable]$this.CallMethod($Session, $methodContext, @($Size))
    }

    [hashtable] PeekFully([ISession]$Session) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName);
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineMethod(@{
                Name = $methodName
                InParams = @()
                OutParams = @('Out', 'ReadSize', 'Overflow')
                InProcessor = {}
                OutProcessor = {
                    param($Outs, $Context)
                    return @{
                        Out = $Outs[0]
                        ReadSize = $Outs[1]
                        Overflow = $Outs[2]
                    }
                }
            })
            $methodContext = $this.GetMethodContext($methodName);
        }

        return [hashtable]$this.CallMethod($Session, $methodContext)
    }

    [hashtable] Write([ISession]$Session, [byte[]]$In) {
        return $this.Write($Session, $In, $false)
    }

    [hashtable] Write([ISession]$Session, [byte[]]$In, [bool]$AllowOverwrite = $false) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName);
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineMethod(@{
                Name = $methodName
                InParams = @('In', 'Size', 'AllowOverwrite')
                OutParams = @('WriteSize')
                InProcessor = {
                    param($CallArgs, $Context)
                    $Context.CallParams[0].Value.Value = [byte[]]::new(8192)
                    [System.Array]::Copy($CallArgs[0], 0, $Context.CallParams[0].Value.Value, 0, $CallArgs[0].Length)
                    $Context.CallParams[1].Value.Value = [UInt16]$CallArgs[0].Length
                    $Context.CallParams[2].Value.Value = [bool]$CallArgs[1]
                }
                OutProcessor = {
                    param($Outs, $Context)
                    return @{
                        WriteSize = $Outs[0]
                    }
                }
            })
            $methodContext = $this.GetMethodContext($methodName);
        }

        return [hashtable]$this.CallMethod($Session, $methodContext, @($In, $AllowOverwrite))
    }

    [hashtable] WriteFully([ISession]$Session, [byte[]]$In) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName);
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineMethod(@{
                Name = $methodName
                InParams = @('In', 'Size')
                OutParams = @('WriteSize')
                InProcessor = {
                    param($CallArgs, $Context)
                    $Context.CallParams[0].Value.Value = [byte[]]::new(8192)
                    [System.Array]::Copy($CallArgs[0], 0, $Context.CallParams[0].Value.Value, 0, $CallArgs[0].Length)
                    $Context.CallParams[1].Value.Value = [UInt16]$CallArgs[0].Length
                }
                OutProcessor = {
                    param($Outs, $Context)
                    return @{
                        WriteSize = $Outs[0]
                    }
                }
            })
            $methodContext = $this.GetMethodContext($methodName);
        }

        return [hashtable]$this.CallMethod($Session, $methodContext, @(, $In))
    }

    [bool] Consume([ISession]$Session, [UInt16]$Size = 0) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName);
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineMethod(@{
                Name = $methodName
                InParams = @('Size')
                OutParams = @('Ok')
                InProcessor = {
                    param($CallArgs, $Context)
                    $Context.CallParams[0].Value.Value = $CallArgs[0]
                }
                OutProcessor = {
                    param($Outs, $Context)
                    return $Outs[0]
                }
            })
            $methodContext = $this.GetMethodContext($methodName);
        }

        return [bool]$this.CallMethod($Session, $methodContext, @($Size))
    }

    [bool] ClearBuffer([ISession]$Session) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName);
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineMethod(@{
                Name = $methodName
                InParams = @()
                OutParams = @('Ok')
                InProcessor = {}
                OutProcessor = {
                    param($Outs, $Context)
                    return $Outs[0]
                }
            })
            $methodContext = $this.GetMethodContext($methodName);
        }

        return [bool]$this.CallMethod($Session, $methodContext)
    }

    [UInt16] GetReadableSize([ISession]$Session) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName);
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineMethod(@{
                Name = $methodName
                InParams = @()
                OutParams = @('Size')
                InProcessor = {}
                OutProcessor = {
                    param($Outs, $Context)
                    return $Outs[0]
                }
            })
            $methodContext = $this.GetMethodContext($methodName);
        }

        return [UInt16]$this.CallMethod($Session, $methodContext)
    }

    [UInt16] GetWritableSize([ISession]$Session) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName);
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineMethod(@{
                Name = $methodName
                InParams = @()
                OutParams = @('Size')
                InProcessor = {}
                OutProcessor = {
                    param($Outs, $Context)
                    return $Outs[0]
                }
            })
            $methodContext = $this.GetMethodContext($methodName);
        }

        return [UInt16]$this.CallMethod($Session, $methodContext)
    }

    [hashtable] GetStat([ISession]$Session) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName);
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineMethod(@{
                Name = $methodName
                InParams = @()
                OutParams = @('WritableSize', 'ReadableSize', 'Overflow')
                InProcessor = {}
                OutProcessor = {
                    param($Outs, $Context)
                    return @{
                        WritableSize = $Outs[0]
                        ReadableSize = $Outs[1]
                        Overflow = $Outs[2]
                    }
                }
            })
            $methodContext = $this.GetMethodContext($methodName);
        }

        return [hashtable]$this.CallMethod($Session, $methodContext)
    }

    [bool] IsOverflow([ISession]$Session) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName);
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineMethod(@{
                Name = $methodName
                InParams = @()
                OutParams = @('Overflow')
                InProcessor = {}
                OutProcessor = {
                    param($Outs, $Context)
                    return $Outs[0]
                }
            })
            $methodContext = $this.GetMethodContext($methodName);
        }

        return [bool]$this.CallMethod($Session, $methodContext)
    }

    [bool] IsReadable([ISession]$Session) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName);
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineMethod(@{
                Name = $methodName
                InParams = @()
                OutParams = @('Readable')
                InProcessor = {}
                OutProcessor = {
                    param($Outs, $Context)
                    return $Outs[0]
                }
            })
            $methodContext = $this.GetMethodContext($methodName);
        }

        return [bool]$this.CallMethod($Session, $methodContext)
    }

    [bool] IsWritable([ISession]$Session) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName);
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineMethod(@{
                Name = $methodName
                InParams = @()
                OutParams = @('Writable')
                InProcessor = {}
                OutProcessor = {
                    param($Outs, $Context)
                    return $Outs[0]
                }
            })
            $methodContext = $this.GetMethodContext($methodName);
        }
        
        return [bool]$this.CallMethod($Session, $methodContext)
    }

    [Object] GetContext([ISession]$Session) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName);
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineMethod(@{
                Name = $methodName
                InParams = @()
                OutParams = @('Context')
                InProcessor = {}
                OutProcessor = {
                    param($Outs, $Context)
                    return $Outs[0].Body
                }
            })
            $methodContext = $this.GetMethodContext($methodName);
        }

        return $this.CallMethod($Session, $methodContext)
    }

    [hashtable] DiffWrite([ISession]$Session, $RefContext) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName);
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineMethod(@{
                Name = $methodName
                InParams = @('RefContext')
                OutParams = @('Out', 'Size', 'Missing', 'ComparedContext')
                InProcessor = {
                    param($CallArgs, $Context)
                    $Context.CallParams[0].Value.Value = $CallArgs[0].Clone()
                }
                OutProcessor = {
                    param($Outs, $Context)
                    return @{
                        Out = $Outs[0]
                        Size = $Outs[1]
                        Missing = $Outs[2]
                        ComparedContext = $Outs[3].Body
                    }
                }
            })
            $methodContext = $this.GetMethodContext($methodName);
        }
        
        return [hashtable]$this.CallMethod($Session, $methodContext, @($RefContext))
    }

    [hashtable] DiffRead([ISession]$Session, $RefContext) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName);
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineMethod(@{
                Name = $methodName
                InParams = @('RefContext')
                OutParams = @('Out', 'Size', 'Missing', 'Overflow', 'ComparedContext')
                InProcessor = {
                    param($CallArgs, $Context)
                    $Context.CallParams[0].Value.Value = $CallArgs[0].Clone()
                }
                OutProcessor = {
                    param($Outs, $Context)
                    return @{
                        Out = $Outs[0]
                        Size = $Outs[1]
                        Missing = $Outs[2]
                        Overflow = $Outs[3]
                        ComparedContext = $Outs[4].Body
                    }
                }
            })
            $methodContext = $this.GetMethodContext($methodName);
        }
        
        return [hashtable]$this.CallMethod($Session, $methodContext, @($RefContext))
    }

    [hashtable] Diff([ISession]$Session, $RefContext) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName);
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineMethod(@{
                Name = $methodName
                InParams = @('RefContext')
                OutParams = @(
                    'DiffWrite', 'DiffWriteSize', 'DiffWriteMissing', 'DiffWriteValid',
                    'DiffRead', 'DiffReadSize', 'DiffReadMissing', 'DiffReadValid',
                    'Overflow', 'ComparedContext'
                )
                InProcessor = {
                    param($CallArgs, $Context)
                    $Context.CallParams[0].Value.Value = $CallArgs[0].Clone()
                }
                OutProcessor = {
                    param($Outs, $Context)
                    return @{
                        DiffWrite = $Outs[0]
                        DiffWriteSize = $Outs[1]
                        DiffWriteMissing = $Outs[2]
                        DiffWriteValid = $Outs[3]
                        DiffRead = $Outs[4]
                        DiffReadSize = $Outs[5]
                        DiffReadMissing = $Outs[6]
                        DiffReadValid = $Outs[7]
                        Overflow = $Outs[8]
                        ComparedContext = $Outs[9].Body
                    }
                }
            })
            $methodContext = $this.GetMethodContext($methodName);
        }
        
        return [hashtable]$this.CallMethod($Session, $methodContext, @($RefContext))
    }

    [hashtable] GetDiffStat([ISession]$Session, $RefContext) {
        $methodContext = $this.GetMethodContext((Get-PSCallStack)[0].FunctionName);
        if ($null -eq $methodContext) {
            $methodName = (Get-PSCallStack)[0].FunctionName
            $this.DefineMethod(@{
                Name = $methodName
                InParams = @('RefContext')
                OutParams = @(
                    'DiffWriteSize', 'DiffWriteMissing',
                    'DiffReadSize', 'DiffReadMissing', 
                    'Overflow', 'ComparedContext'
                )
                InProcessor = {
                    param($CallArgs, $Context)
                    $Context.CallParams[0].Value.Value = $CallArgs[0]
                }
                OutProcessor = {
                    param($Outs, $Context)
                    return @{
                        DiffWriteSize = $Outs[0]
                        DiffWriteMissing = $Outs[1]
                        DiffReadSize = $Outs[2]
                        DiffReadMissing = $Outs[3]
                        Overflow = $Outs[4]
                        ComparedContext = $Outs[5].Body
                    }
                }
            })
            $methodContext = $this.GetMethodContext($methodName);
        }
        
        return [hashtable]$this.CallMethod($Session, $methodContext, @($RefContext))
    }
}

class MethodCallException : System.Exception {
    [hashtable]$CallInfo
    MethodCallException([string]$Message, [hashtable]$CallInfo) : base($Message) {
        $this.CallInfo = $CallInfo
    }
}
