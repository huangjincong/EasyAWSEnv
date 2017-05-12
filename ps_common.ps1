function Change-Runas{
    param(
        $runas,
        $password
    )
    if($runas -eq "system"){
        [Environment]::SetEnvironmentVariable('run_as','','Machine')
        [Environment]::SetEnvironmentVariable('run_pwd','','Machine')
    }
    else{
        [Environment]::SetEnvironmentVariable('run_as',$runas,'Machine')
        [Environment]::SetEnvironmentVariable('run_pwd',$password,'Machine')
        $RegPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
	    Set-ItemProperty $RegPath 'AutoAdminLogon' -Value '1' -type String
	    Set-ItemProperty $RegPath 'DefaultUsername' -Value $runas -type String
	    Set-ItemProperty $RegPath 'DefaultPassword' -Value $password -type String
    }
}