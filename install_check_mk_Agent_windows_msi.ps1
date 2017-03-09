    param ([string]$nagiosip), [string]$subnet)


    $Username = 'agents'
    $Password = '4g3nt5'
    $Url = "http://$nagiosip/mk_agents/check_mk_agent.msi"
    $Path = "C:\Windows\Temp\check_mk_agent.msi"
    $WebClient = New-Object System.Net.WebClient
    $WebClient.Credentials = New-Object System.Net.Networkcredential($Username, $Password)
    $WebClient.DownloadFile( $url, $path )


    $msifile= 'C:\Windows\Temp\check_mk_agent.msi' 
    $arguments= ' /qn /l*v C:\Windows\Temp\check_mk_agent_install.log' 

Start-Process `
     -file  $msifile `
     -arg $arguments `
     -passthru | wait-process


New-NetFirewallRule -DisplayName "Allow inbound ICMPv4" -Direction Inbound -Protocol ICMPv4 -IcmpType 8 -RemoteAddress $subnet/24 -Action Allow
New-NetFirewallRule -Name "Check_MK_Agent_Port" -Description "Check_MK_Agent_Port" -DisplayName "Check_MK_Agent_Port" -Enabled:True -Direction Inbound -Action Allow -Protocol TCP -LocalPort 6556 -RemoteAddress $nagiosip
