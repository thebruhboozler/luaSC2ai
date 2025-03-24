$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Parse("172.19.64.1"),4999)

$listener.start()


while($true){
	$client = $listener.AcceptTcpClient()
	$sc2Path = "C:\Program Files (x86)\StarCraft II\Support64\SC2Switcher_x64.exe"
	$launchArgs = "-sso=1 -listen 172.19.64.1 -port 5000 -launch -uid s2"
	Start-Process -FilePath $sc2Path -ArgumentList $launchArgs
	$client.Close()
}
