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

<#
# About This Script
This script is a test of `OpcUaRingBuffer.ps1` using `Pester`.
Run the information model test (`ModelTest_OpcUaRingBuffer`) on the controller or simulator,
and use it to make it accessible via OPC UA.
The information model test runs on `RingBufferOpcUaExtensionLib.smc2` by default.

## Usage Environment
Controllers: OMRON Co., Ltd. NX1 (Ver. 1.64 or later), NX5 (Ver. 1.64 or later), NX7 (Ver. 1.35 or later), NJ5 (Ver. 1.63 or later)
IDE:Sysmac Studio Ver.1.62 or later
PowerShell: PowerShell 7.5 or later
Pester     : 5.7.1

## Usage Steps (Simulator)
1.  Run `./PwshOpcUaClient/setup.ps1`.
    This retrieves the assemblies required by `PwshOpcUaClient` using NuGet.
2.  Open `RingBufferOpcUaExtensionLib.smc2` in Sysmac Studio.
3.  Start the simulator and the OPC UA server for simulator.
4.  Generate a certificate on the OPC UA server for simulator.   
    This step is unnecessary if a certificate has already been generated.
5.  Register a user and password for the OPC UA server for simulator.   
    This step is unnecessary if a user has already been registered.
6.  Run `Invoke-Pester`.
7.  Trust the server certificate in `PwshOpcUaClient`.
    Move the rejected server certificate from `PwshOpcUaClient/pki/rejected/certs` to `PwshOpcUaClient/pki/trusted/certs`.
8.  Run `Invoke-Pester`.

## Usage Steps (Controller)
1.  Run `./PwshOpcUaClient/setup.ps1`.
    This retrieves the assemblies required by `PwshOpcUaClient` using NuGet.
2.  Open `RingBufferOpcUaExtensionLib.smc2` in Sysmac Studio.
3.  Adjust the project's configuration and settings to match the controller you are using.
4.  Transfer the project to the controller.
5.  Generate a certificate on the controller's OPC UA server.   
    This step is unnecessary if a certificate has already been generated.
6.  Register a user and password for the controller's OPC UA server.   
    This step is unnecessary if a user has already been registered.
7.  Run Pester.
    Replace YOUR_SERVER_ENDPOINT with your controller's OPC UA server endpoint and run the following in PowerShell.
    ```powershell
    Invoke-Pester -Container $(New-PesterContainer -Path . -Data @{ UseSimulator=$false; ServerUrl=YOUR_SERVER_ENDPOINT })
    ```
8.  Trust the client certificate on the controller's OPC UA server. Trust the rejected client certificate.   
    This step is unnecessary if you are using anonymous access without signing or encryption for message exchange.
9.  Trust the server certificate in `PwshOpcUaClient`.
    Move the rejected server certificate from `PwshOpcUaClient/pki/rejected/certs` to `PwshOpcUaClient/pki/trusted/certs`.
10.  Run Pester.
    Replace YOUR_SERVER_ENDPOINT with your controller's OPC UA server endpoint and run the following in PowerShell.
    ```powershell
    Invoke-Pester -Container $(New-PesterContainer -Path . -Data @{ UseSimulator=$false; ServerUrl=YOUR_SERVER_ENDPOINT })
    ```

# このスクリプトについて
このスクリプトは`Pester`による`OpcUaRingBuffer.ps1`のテストです。
コントローラまたは、シミュレータで情報モデルテスト(`ModelTest_OpcUaRingBuffer`)を動作させ、
OPC UAでアクセスできる状態にして使用します。
`RingBufferOpcUaExtensionLib.smc2`は、デフォルトで情報モデルテストが動作します。

## 使用環境
コントローラ: OMRON社製 NX1(Ver.1.64以降), NX5(Ver.1.64以降), NX7(Ver.1.35以降), NJ5(Ver.1.63以降)
IDE        : Sysmac Studio Ver.1.62以降
PowerShell : PowerShell 7.5以降
Pester     : 5.7.1

## 使用手順 (シミュレータ)
1.  `./PwshOpcUaClient/setup.ps1`を実行
    `PwshOpcUaClient`が必要とするアセンブリをNuGetで取得。
2.  Sysmac Studioで`RingBufferOpcUaExtensionLib.smc2`を開く
3.  シミュレータとシミュレータ用OPC UAサーバを起動
4.  シミュレータ用OPC UAサーバで証明書を生成
    既に生成してある場合は不要。
5.  シミュレータ用OPC UAサーバへユーザーとパスワードを登録
    既に登録してある場合は不要。
6.  `Invoke-Pester`を実行
7.  `PwshOpcUaClient`でサーバ証明書を信頼
    `./PwshOpcUaClient/pki/rejected/certs`にある拒否したサーバ証明書を`./PwshOpcUaClient/pki/trusted/certs`に移動。
8.  `Invoke-Pester`を実行

## 使用手順 (コントローラ)
1.  `./PwshOpcUaClient/setup.ps1`を実行
    `PwshOpcUaClient`が必要とするアセンブリをNuGetで取得。
2.  Sysmac Studioで`RingBufferOpcUaExtensionLib.smc2`を開く
3.  プロジェクトの構成と設定を使用するコントローラに合わせる
4.  プロジェクトをコントローラに転送
5.  コントローラのOPC UAサーバで証明書を生成
    既に生成してある場合は不要。
6.  コントローラのOPC UAサーバへユーザーとパスワードを登録
    既に登録してある場合は不要。
7.  Pesterを実行
    以下の`YOUR_SERVER_ENDPOINT`をコントローラのOPC UAサーバのエンドポイントに置き換え実行。
    ```powershell
    Invoke-Pester -Container $(New-PesterContainer -Path . -Data @{ UseSimulator=$false; ServerUrl=YOUR_SERVER_ENDPOINT })
    ```
8.  コントローラのOPC UAサーバでクライアント証明書の信頼
    拒否されたクライアント証明書を信頼する。
    Anonymousでメッセージ交換に署名も暗号化も使用しないのであれば不要。
9.  `PwshOpcUaClient`でサーバ証明書を信頼
    `./PwshOpcUaClient/pki/rejected/certs`にある拒否したサーバ証明書を`./PwshOpcUaClient/pki/trusted/certs`に移動。
10.  Pesterを実行
    以下の`YOUR_SERVER_ENDPOINT`をコントローラのOPC UAサーバのエンドポイントに置き換え実行。
    ```powershell
    Invoke-Pester -Container $(New-PesterContainer -Path . -Data @{ UseSimulator=$false; ServerUrl=YOUR_SERVER_ENDPOINT })
    ```
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
    . "$PSScriptRoot/OpcUaRingBuffer.ps1"

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
    $testNode = "ns=$($UseSimulator ? '2;Programs.' : '4;')ModelTest${nodeSeparator}ModelTestOpcUaRingBuffer"

    $testController = [ModelTestController]::new($testNode, $nodeSeparator)
    $testController.Initialize($client.Session)

    $bufferCapacity = 65535
    $target = [RingBuffer]::new("${testNode}${nodeSeparator}Target", $nodeSeparator)
}

AfterAll {
    Dispose-PwsOpcUaClient -Client $client
}

Describe 'Read' {
    It 'バイト列を読み出す' {
        $msg = '12345'
        $binMsg = [System.Text.Encoding]::UTF8.GetBytes($msg)
        $target.Write($client.Session, $binMsg)

        $read = $target.Read($client.Session, $binMsg.Length)

        $read.ReadSize
            | Should -Be $binMsg.Length
        [System.Text.Encoding]::UTF8.GetString($read.Out, 0, $read.ReadSize)
            | Should -Be $msg
        $target.GetReadableSize($client.Session)
            | Should -Be 0
    }

    It 'Sessionが不正であるとき、例外が発生する' {
        { $target.Read($null, 100) }
            | Should -Throw
    }

    AfterEach {
        $testController.TearDown($client.Session)
    }
}

Describe 'ReadFully' {
    It '可能な限りバイト列を読み出す' {
        $msg = '12345'
        $binMsg = [System.Text.Encoding]::UTF8.GetBytes($msg)
        $target.Write($client.Session, $binMsg)

        $read = $target.ReadFully($client.Session)

        $read.ReadSize
            | Should -Be $binMsg.Length
        [System.Text.Encoding]::UTF8.GetString($read.Out, 0, $read.ReadSize)
            | Should -Be $msg
        $target.GetReadableSize($client.Session)
            | Should -Be 0
    }

    It 'Sessionが不正であるとき、例外が発生する' {
        { $target.ReadFully($null) }
            | Should -Throw
    }
        
    AfterEach {
        $testController.TearDown($client.Session)
    }
}

Describe 'Peek' {
    It 'バイト列を読み出すが、バッファの読み出し位置は変化しない' {
        $msg = '12345'
        $binMsg = [System.Text.Encoding]::UTF8.GetBytes($msg)
        $target.Write($client.Session, $binMsg)

        $read = $target.Peek($client.Session, $binMsg.Length)

        $read.ReadSize
            | Should -Be $binMsg.Length
        [System.Text.Encoding]::UTF8.GetString($read.Out, 0, $read.ReadSize)
            | Should -Be $msg
        $target.GetReadableSize($client.Session)
            | Should -Be $binMsg.Length
    }

    It 'Sessionが不正であるとき、例外が発生する' {
        { $target.Peek($null, 100) }
            | Should -Throw
    }
        
    AfterEach {
        $testController.TearDown($client.Session)
    }
}

Describe 'PeekFully' {
    It '可能な限りバイト列を読み出すが、バッファの読み出し位置は変化しない' {
        $msg = '12345'
        $binMsg = [System.Text.Encoding]::UTF8.GetBytes($msg)
        $target.Write($client.Session, $binMsg)

        $read = $target.PeekFully($client.Session)

        $read.ReadSize
            | Should -Be $binMsg.Length
        [System.Text.Encoding]::UTF8.GetString($read.Out, 0, $read.ReadSize)
            | Should -Be $msg
        $target.GetReadableSize($client.Session)
            | Should -Be $binMsg.Length
    }

    It 'Sessionが不正であるとき、例外が発生する' {
        { $target.PeekFully($null) }
            | Should -Throw
    }
        
    AfterEach {
        $testController.TearDown($client.Session)
    }
}

Describe 'Write' {
    It 'バイト列を書き込む' {
        $msg = '12345'
        $binMsg = [System.Text.Encoding]::UTF8.GetBytes($msg)

        $target.Write($client.Session, $binMsg)

        $target.GetReadableSize($client.Session)
            | Should -Be $binMsg.Length
        $read = $target.ReadFully($client.Session)
        $read.ReadSize
            | Should -Be $binMsg.Length
        [System.Text.Encoding]::UTF8.GetString($read.Out, 0, $read.ReadSize)
            | Should -Be $msg
    }

    It 'Sessionが不正であるとき、例外が発生する' {
        $msg = '12345'
        $binMsg = [System.Text.Encoding]::UTF8.GetBytes($msg)

        { $target.Write($null, $binMsg) }
            | Should -Throw
    }
        
    AfterEach {
        $testController.TearDown($client.Session)
    }
}

Describe 'WriteFully' {
    It '可能な限りバイト列を書き込む' {
        $msg = '12345'
        $binMsg = [System.Text.Encoding]::UTF8.GetBytes($msg)

        $target.WriteFully($client.Session, $binMsg)

        $target.GetReadableSize($client.Session)
            | Should -Be $binMsg.Length
        $read = $target.ReadFully($client.Session)
        $read.ReadSize
            | Should -Be $binMsg.Length
        [System.Text.Encoding]::UTF8.GetString($read.Out, 0, $read.ReadSize)
            | Should -Be $msg
    }

    It 'Sessionが不正であるとき、例外が発生する' {
        $msg = '12345'
        $binMsg = [System.Text.Encoding]::UTF8.GetBytes($msg)

        { $target.WriteFully($null, $binMsg) }
            | Should -Throw
    }
        
    AfterEach {
        $testController.TearDown($client.Session)
    }
}

Describe 'Consume' {
    It 'バイト列を消費する' {
        $msg = '12345'
        $binMsg = [System.Text.Encoding]::UTF8.GetBytes($msg)
        $target.Write($client.Session, $binMsg)
        $consumeSize = 2
        $expMsg = '345'

        $target.Consume($client.Session, $consumeSize)

        $target.GetReadableSize($client.Session)
            | Should -Be ($binMsg.Length - $consumeSize)
        $read = $target.ReadFully($client.Session)
        $read.ReadSize
            | Should -Be ($binMsg.Length - $consumeSize)
        [System.Text.Encoding]::UTF8.GetString($read.Out, 0, $read.ReadSize)
            | Should -Be $expMsg
    }

    It 'Sessionが不正であるとき、例外が発生する' {
        { $target.Consume($null, 100) }
            | Should -Throw
    }
        
    AfterEach {
        $testController.TearDown($client.Session)
    }
}

Describe 'ClearBuffer' {
    It 'バイト列をクリアする' {
        $msg = '12345'
        $binMsg = [System.Text.Encoding]::UTF8.GetBytes($msg)
        $target.Write($client.Session, $binMsg)

        $target.ClearBuffer($client.Session)

        $target.GetReadableSize($client.Session)
            | Should -Be 0
    }

    It 'Sessionが不正であるとき、例外が発生する' {
        { $target.ClearBuffer($null) }
            | Should -Throw
    }
        
    AfterEach {
        $testController.TearDown($client.Session)
    }
}

Describe 'GetWritableSize' {
    It '書き込み可能なサイズを返す' {
        $msg = '12345'
        $binMsg = [System.Text.Encoding]::UTF8.GetBytes($msg)
        $target.WriteFully($client.Session, $binMsg)

        $target.GetWritableSize($client.Session)
            | Should -Be ($bufferCapacity - $binMsg.Length)
    }
    
    It 'バイト列を保持していなければ、容量サイズに等しい' {
        $target.GetWritableSize($client.Session)
            | Should -Be $bufferCapacity
    }

    It 'Sessionが不正であるとき、例外が発生する' {
        { $target.GetWritableSize($null) }
            | Should -Throw
    }
    
    AfterEach {
        $testController.TearDown($client.Session)
    }
}

Describe 'GetReadableSize' {
    It '読み出し可能なサイズを返す' {
        $msg = '12345'
        $binMsg = [System.Text.Encoding]::UTF8.GetBytes($msg)
        $target.WriteFully($client.Session, $binMsg)

        $target.GetReadableSize($client.Session)
            | Should -Be $binMsg.Length
    }
    
    It 'バイト列を保持していなければ、ゼロを返す' {
        $target.GetReadableSize($client.Session)
            | Should -Be 0
    }

    It 'Sessionが不正であるとき、例外が発生する' {
        { $target.GetReadableSize($null) }
            | Should -Throw
    }
    
    AfterEach {
        $testController.TearDown($client.Session)
    }
}

Describe 'GetStat' {
    It 'バッファ情報を返す' {
        $msg = '12345'
        $binMsg = [System.Text.Encoding]::UTF8.GetBytes($msg)
        $target.WriteFully($client.Session, $binMsg)

        $stat = $target.GetStat($client.Session)
        $stat.WritableSize
            | Should -Be ($bufferCapacity - $binMsg.Length)
        $stat.ReadableSize
            | Should -Be $binMsg.Length
        $stat.IsOverflow
            | Should -BeFalse
    }

    It 'Sessionが不正であるとき、例外が発生する' {
        { $target.GetStat($null) }
            | Should -Throw
    }
        
    AfterEach {
        $testController.TearDown($client.Session)
    }
}

Describe 'IsOverflow' {
    It 'バッファがオーバーフローしているかを返す' {
        $msg = '12345'
        $binMsg = [System.Text.Encoding]::UTF8.GetBytes($msg)
        $target.WriteFully($client.Session, $binMsg)

        $target.IsOverflow($client.Session)
            | Should -BeFalse
    }

    It 'Sessionが不正であるとき、例外が発生する' {
        { $target.IsOverflow($null) }
            | Should -Throw
    }
        
    AfterEach {
        $testController.TearDown($client.Session)
    }
}

Describe 'IsReadable' {
    It '読み出し可能かを返す' {
        $msg = '12345'
        $binMsg = [System.Text.Encoding]::UTF8.GetBytes($msg)
        $target.WriteFully($client.Session, $binMsg)

        $target.IsReadable($client.Session)
            | Should -BeTrue
    }

    It 'バッファが空であるとき、falseを返す' {
        $target.IsReadable($client.Session)
            | Should -BeFalse
    }

    It 'Sessionが不正であるとき、例外が発生する' {
        { $target.IsReadable($null) }
            | Should -Throw
    }

    AfterEach {
        $testController.TearDown($client.Session)
    }
}

Describe 'IsWritable' {
    It '書き込み可能かを返す' {
        $msg = '12345'
        $binMsg = [System.Text.Encoding]::UTF8.GetBytes($msg)
        $target.WriteFully($client.Session, $binMsg)

        $target.IsWritable($client.Session)
            | Should -BeTrue
    }

    It 'Sessionが不正であるとき、例外が発生する' {
        { $target.IsWritable($null) }
            | Should -Throw
    }

    AfterEach {
        $testController.TearDown($client.Session)
    }
}

Describe 'GetContext' {
    It 'サーバで取得処理をした時点のバッファコンテクストを返す' {
        $target.GetContext($client.Session)
            | Should -Not -BeNullOrEmpty
    }

    It 'Sessionが不正であるとき、例外が発生する' {
        { $target.GetContext($null) }
            | Should -Throw
    }

    AfterEach {
        $testController.TearDown($client.Session)
    }
}

Describe 'DiffWrite' {
    It '現在のバッファコンテクストと引数のバッファコンテクストの書き込み差分を取得する' {
        $msg = '12345'
        $binMsg = [System.Text.Encoding]::UTF8.GetBytes($msg)
        $target.WriteFully($client.Session, $binMsg)
        $context = $target.GetContext($client.Session)
        $msg = '678'
        $binMsg = [System.Text.Encoding]::UTF8.GetBytes($msg)
        $target.WriteFully($client.Session, $binMsg)
            | Out-Null

        $diff = $target.DiffWrite($client.Session, $context)

        $diff.Size
            | Should -Be $binMsg.Length
        [System.Text.Encoding]::UTF8.GetString($diff.Out, 0, $diff.Size)
            | Should -Be $msg
        $diff.Missing
            | Should -BeFalse
        $context = $diff.ComparedContext

        Start-Sleep -Milliseconds 10
        $diff = $target.DiffWrite($client.Session, $context)

        $diff.Size
            | Should -Be 0
        $diff.Missing
            | Should -BeFalse
    }

    It 'Sessionが不正であるとき、例外が発生する' {
        $context = $target.GetContext($client.Session)

        { $target.DiffWrite($null, $context) }
            | Should -Throw
    }

    AfterEach {
        $testController.TearDown($client.Session)
    }
}

Describe 'DiffRead' {
    It '現在のバッファコンテクストと引数のバッファコンテクストの読み出し差分を取得する' {
        $expMsg = "12345"
        $expBinMsg = [System.Text.Encoding]::UTF8.GetBytes($expMsg)
        $target.WriteFully($client.Session, $expBinMsg)
        $context = $target.GetContext($client.Session)
        $target.Read($client.Session, $expBinMsg.Length)
        $msg = '678'
        $binMsg = [System.Text.Encoding]::UTF8.GetBytes($msg)
        $target.WriteFully($client.Session, $binMsg)
            | Out-Null

        $diff = $target.DiffRead($client.Session, $context)

        $diff.Size
            | Should -Be $expBinMsg.Length
        [System.Text.Encoding]::UTF8.GetString($diff.Out, 0, $diff.Size)
            | Should -Be $expMsg
        $diff.Missing
            | Should -BeFalse
        $diff.Overflow
            | Should -BeFalse
        $context = $diff.ComparedContext

        Start-Sleep -Milliseconds 10
        $diff = $target.DiffRead($client.Session, $context)

        $diff.Size
            | Should -Be 0
        $diff.Missing
            | Should -BeFalse
        $diff.Overflow
            | Should -BeFalse
    }
    
    It 'Sessionが不正であるとき、例外が発生する' {
        $context = $target.GetContext($client.Session)

        { $target.DiffRead($null, $context) }
            | Should -Throw
    }

    AfterEach {
        $testController.TearDown($client.Session)
    }
}

Describe 'Diff' {
    It '現在のバッファコンテクストと引数のバッファコンテクストの書き込み、読み出し差分を取得する' {
        $expReadMsg = '12345'
        $expReadBinMsg = [System.Text.Encoding]::UTF8.GetBytes($expReadMsg)
        $target.WriteFully($client.Session, $expReadBinMsg)
        $context = $target.GetContext($client.Session)
        $target.Read($client.Session, $expReadBinMsg.Length)
        $expWriteMsg = '678'
        $expWriteBinMsg = [System.Text.Encoding]::UTF8.GetBytes($expWriteMsg)
        $target.WriteFully($client.Session, $expWriteBinMsg)
            | Out-Null

        $diff = $target.Diff($client.Session, $context)

        $diff.DiffWriteSize
            | Should -Be $expWriteBinMsg.Length
        [System.Text.Encoding]::UTF8.GetString($diff.DiffWrite, 0, $diff.DiffWriteSize)
            | Should -Be $expWriteMsg
        $diff.DiffWriteMissing
            | Should -BeFalse
        $diff.DiffWriteValid
            | Should -BeTrue
        $diff.DiffReadSize
            | Should -Be $expReadBinMsg.Length
        [System.Text.Encoding]::UTF8.GetString($diff.DiffRead, 0, $diff.DiffReadSize)
            | Should -Be $expReadMsg
        $diff.DiffReadMissing
            | Should -BeFalse
        $diff.Overflow
            | Should -BeFalse
        $diff.DiffReadValid
            | Should -BeTrue
        $context = $diff.ComparedContext

        Start-Sleep -Milliseconds 10
        $diff = $target.Diff($client.Session, $context)

        $diff.DiffWriteSize
            | Should -Be 0
        $diff.DiffWriteMissing
            | Should -BeFalse
        $diff.DiffWriteValid
            | Should -BeTrue
        $diff.DiffReadSize
            | Should -Be 0
        $diff.DiffReadMissing
            | Should -BeFalse
        $diff.Overflow
            | Should -BeFalse
        $diff.DiffReadValid
            | Should -BeTrue
    }

    It 'Sessionが不正であるとき、例外が発生する' {
        $context = $target.GetContext($client.Session)

        { $target.Diff($null, $context) }
            | Should -Throw
    }

    AfterEach {
        $testController.TearDown($client.Session)
    }
}

Describe 'GetDiffStat' {
    It '現在のバッファコンテクストと引数のバッファコンテクストの書き込み、読み出し差分情報を取得する' {
        $expReadMsg = '12345'
        $expReadBinMsg = [System.Text.Encoding]::UTF8.GetBytes($expReadMsg)
        $target.WriteFully($client.Session, $expReadBinMsg)
        $context = $target.GetContext($client.Session)
        $target.Read($client.Session, $expReadBinMsg.Length)
        $expWriteMsg = '678'
        $expWriteBinMsg = [System.Text.Encoding]::UTF8.GetBytes($expWriteMsg)
        $target.WriteFully($client.Session, $expWriteBinMsg)
            | Out-Null

        $stat = $target.GetDiffStat($client.Session, $context)

        $stat.DiffWriteSize
            | Should -Be $expWriteBinMsg.Length
        $stat.DiffWriteMissing
            | Should -BeFalse
        $stat.DiffReadSize
            | Should -Be $expReadBinMsg.Length
        $stat.DiffReadMissing
            | Should -BeFalse
        $stat.Overflow
            | Should -BeFalse
        $context = $stat.ComparedContext

        Start-Sleep -Milliseconds 10
        $stat = $target.GetDiffStat($client.Session, $context)

        $stat.DiffWriteSize
            | Should -Be 0
        $stat.DiffWriteMissing
            | Should -BeFalse
        $stat.DiffReadSize
            | Should -Be 0
        $stat.DiffReadMissing
            | Should -BeFalse
        $stat.Overflow
            | Should -BeFalse
    }

    It 'Sessionが不正であるとき、例外が発生する' {
        $context = $target.GetContext($client.Session)

        { $target.GetDiffStat($null, $context) }
            | Should -Throw
    }

    AfterEach {
        $testController.TearDown($client.Session)
    }
}
