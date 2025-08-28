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
This script is an example of `OpcUaRingBuffer.ps1`.
It connects to an OPC UA server running on a controller or simulator and reads and writes to the `RingBuffer`.
`ExampleOpcUaRingBuffer.smc2` runs the required programs by default.

## Usage Environment
Controllers: OMRON Co., Ltd. NX1 (Ver. 1.64 or later), NX5 (Ver. 1.64 or later), NX7 (Ver. 1.35 or later), NJ5 (Ver. 1.63 or later)
IDE        : Sysmac Studio Ver.1.62 or later
PowerShell : PowerShell 7.5 or later

## Usage Steps (Simulator)
1.  Run `../PwshOpcUaClient/setup.ps1`.
    This retrieves the assemblies required by `PwshOpcUaClient` using NuGet.
2.  Open `ExampleOpcUaRingBuffer.smc2` in Sysmac Studio.
3.  Start the simulator and the OPC UA server for simulator.
4.  Generate a certificate on the OPC UA server for simulator.   
    This step is unnecessary if a certificate has already been generated.
5.  Register a user and password for the OPC UA server for simulator.   
    This step is unnecessary if a user has already been registered.
6.  Run `./ExampleOpcUaRingBufferDiff.ps1`.
7.  Trust the server certificate in `PwshOpcUaClient`.
    Move the rejected server certificate from `../PwshOpcUaClient/pki/rejected/certs` to `../PwshOpcUaClient/pki/trusted/certs`.
8.  Run `./ExampleOpcUaRingBufferDiff.ps1`.

## Usage Steps (Controller)
1.  Run `../PwshOpcUaClient/setup.ps1`.
    This retrieves the assemblies required by `PwshOpcUaClient` using NuGet.
2.  Open `ExampleOpcUaRingBuffer.smc2` in Sysmac Studio.
3.  Adjust the project's configuration and settings to match the controller you are using.
4.  Transfer the project to the controller.
5.  Generate a certificate on the controller's OPC UA server.   
    This step is unnecessary if a certificate has already been generated.
6.  Register a user and password for the controller's OPC UA server.   
    This step is unnecessary if a user has already been registered.
7.  Run `./ExampleOpcUaRingBufferDiff.ps1`.
8.  Trust the client certificate on the controller's OPC UA server. Trust the rejected client certificate.   
    This step is unnecessary if you are using anonymous access without signing or encryption for message exchange.
9.  Trust the server certificate in `PwshOpcUaClient`.
    Move the rejected server certificate from `../PwshOpcUaClient/pki/rejected/certs` to `../PwshOpcUaClient/pki/trusted/certs`.
10.  Run `./ExampleOpcUaRingBufferDiff.ps1`.


# このスクリプトについて
このスクリプトは、`OpcUaRingBuffer.ps1`の例示です。
コントローラまたは、シミュレータで動作するOPC UAサーバに接続し、`RingBuffer`の読み出しと書き込みを行います。
`ExampleOpcUaRingBuffer.smc2`は、デフォルトで必要なプログラムが動作します。

## 使用環境
コントローラ: OMRON社製 NX1(Ver.1.64以降), NX5(Ver.1.64以降), NX7(Ver.1.35以降), NJ5(Ver.1.63以降)
IDE        : Sysmac Studio Ver.1.62以降
PowerShell : PowerShell 7.5以降

## 使用手順 (シミュレータ)
1.  `../PwshOpcUaClient/setup.ps1`を実行
    `PwshOpcUaClient`が必要とするアセンブリをNuGetで取得。
2.  Sysmac Studioで`ExampleOpcUaRingBuffer.smc2`を開く
3.  シミュレータとシミュレータ用OPC UAサーバを起動
4.  シミュレータ用OPC UAサーバで証明書を生成
    既に生成してある場合は不要。
5.  シミュレータ用OPC UAサーバへユーザーとパスワードを登録
    既に登録してある場合は不要。
6.  `./ExampleOpcUaRingBufferDiff.ps1`を実行
7.  `PwshOpcUaClient`でサーバ証明書を信頼
    `../PwshOpcUaClient/pki/rejected/certs`にある拒否したサーバ証明書を`../PwshOpcUaClient/pki/trusted/certs`に移動。
8.  `./ExampleOpcUaRingBufferDiff.ps1`を実行

## 使用手順 (コントローラ)
1.  `../PwshOpcUaClient/setup.ps1`を実行
    `PwshOpcUaClient`が必要とするアセンブリをNuGetで取得。
2.  Sysmac Studioで`ExampleOpcUaRingBuffer.smc2`を開く
3.  プロジェクトの構成と設定を使用するコントローラに合わせる
4.  プロジェクトをコントローラに転送
5.  コントローラのOPC UAサーバで証明書を生成
    既に生成してある場合は不要。
6.  コントローラのOPC UAサーバへユーザーとパスワードを登録
    既に登録してある場合は不要。
7.  `./ExampleOpcUaRingBufferDiff.ps1`を実行
8.  コントローラのOPC UAサーバでクライアント証明書の信頼
    拒否されたクライアント証明書を信頼する。
    Anonymousでメッセージ交換に署名も暗号化も使用しないのであれば不要。
9.  `PwshOpcUaClient`でサーバ証明書を信頼
    `../PwshOpcUaClient/pki/rejected/certs`にある拒否したサーバ証明書を`../PwshOpcUaClient/pki/trusted/certs`に移動。
10.  `./ExampleOpcUaRingBufferDiff.ps1`を実行
#>

using namespace Opc.Ua
param(
    [bool]$UseSimulator = $true,
    [string]$ServerUrl = 'opc.tcp://localhost:4840',
    [bool]$UseSecurity = $true,
    [string]$UserName = 'taker',
    [string]$UserPassword = 'chocolatepancakes',
    [double]$Interval = 0.05
)
. "$PSScriptRoot/../PwshOpcUaClient/PwshOpcUaClient.ps1"
. "$PSScriptRoot/../OpcUaRingBuffer.ps1"

function Main () {
    try {
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

        # Create the RingBuffer object.
        $separator = $UseSimulator ? '.' : '/'
        $loggerBuffer = [RingBuffer]::new(
            "ns=$($UseSimulator ? '2;Programs.' : '4;')Models${separator}LoggerBuffer",
            $separator
        )

        $decoder = [System.Text.Encoding]::UTF8.GetDecoder()
        $diffContext = $loggerBuffer.GetContext($client.Session)
        While ($true) {
            # Get a write diff from the buffer.
            # This contains this client wrotes.
            $diffWrite = $loggerBuffer.DiffWrite($client.Session, $diffContext)
            if ($diffWrite.Size -gt 0) {
                $chars = [char[]]::new($decoder.GetCharCount($diffWrite.Out, 0, $diffWrite.Size, $false))
                $decoder.GetChars($diffWrite.Out, 0, $diffWrite.Size, $chars, 0, $false)
                    | Out-Null
                $chars -join "" | Write-Host -NoNewline
            }
            $diffContext = $diffWrite.ComparedContext

            # Write a client timestamp to the buffer
            $msg = "client=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fffffff00')`n"
            $binMsg = [System.Text.Encoding]::UTF8.GetBytes($msg)
            $loggerBuffer.Write($client.Session, $binMsg, $true)
                | Out-Null

            Start-Sleep -Seconds $Interval
        }
    }
    catch {
        $_.Exception
    }
    finally {
        Dispose-PwsOpcUaClient -Client $client
    }
}

Main
