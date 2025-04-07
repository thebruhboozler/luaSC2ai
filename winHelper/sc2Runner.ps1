if ($args.Length -ne 2){
	Write-Host "Usage: .\script.ps1 <IP> <Port>"
	exit
}

$ip = $args[0]
$port = $args[1]

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://${ip}:${port}/")
$listener.Start()

while ($listener.IsListening) {
	$context = $listener.GetContext()
	$request = $context.Request
	$response = $context.Response

	if ($request.HttpMethod -eq "GET"){
		$sc2Path = "C:\Program Files (x86)\StarCraft II\Support64\SC2Switcher_x64.exe"
		$launchArgs = "-sso=1 -listen 172.19.64.1 -port 5000 -launch -uid s2"
		Start-Process -FilePath $sc2Path -ArgumentList $launchArgs
		$response.StatusCode = 200
	} else {
		$response.StatusCode = 400
	}
	$response.OutputStream.Close()
}
