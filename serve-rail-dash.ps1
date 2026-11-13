$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSCommandPath
$gameFile = Join-Path $root 'index.html'
$address = 'http://127.0.0.1:8765/'
$listener = New-Object System.Net.HttpListener

try {
    if (-not (Test-Path -LiteralPath $gameFile -PathType Leaf)) {
        throw 'index.html não foi encontrado nesta pasta.'
    }

    $listener.Prefixes.Add($address)
    $listener.Start()
    Write-Host 'Run-Surf aberto no navegador. Mantenha esta janela aberta.'
    Write-Host 'Pressione Ctrl+C para encerrar o servidor.'
    Start-Process $address

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        try {
            $path = $context.Request.Url.AbsolutePath.Trim('/')
            if ($context.Request.HttpMethod -notin @('GET', 'HEAD') -or
                ($path -ne '' -and $path -ne 'index.html')) {
                $context.Response.StatusCode = 404
                $context.Response.Close()
                continue
            }

            $bytes = [System.IO.File]::ReadAllBytes($gameFile)
            $context.Response.StatusCode = 200
            $context.Response.ContentType = 'text/html; charset=utf-8'
            $context.Response.ContentLength64 = $bytes.Length
            if ($context.Request.HttpMethod -ne 'HEAD') {
                $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
            }
            $context.Response.Close()
        }
        catch {
            $context.Response.Close()
            throw
        }
    }
}
catch {
    Write-Host ('Não foi possível iniciar o jogo: ' + $_.Exception.Message) -ForegroundColor Red
    Read-Host 'Pressione Enter para fechar'
}
finally {
    if ($listener.IsListening) {
        $listener.Stop()
    }
    $listener.Close()
}
