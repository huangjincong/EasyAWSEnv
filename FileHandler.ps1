Function Make-CfFile {
	[CmdletBinding()]  
    Param(  
        [ValidateNotNullOrEmpty()]  
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq ".json")})]  
        [Parameter(Mandatory=$True)]  
        [string]$Template,
        [Parameter(Mandatory=$True)]  
        [string]$IniFile
    )
    $iniContent=Get-IniContent D:\git\EasyAWSEnv\InstanceSample\MyInstances.ini
    $jsonContent=@{"AWSTemplateFormatVersion"="2010-09-09";"Description"="AT Template"}

    if($iniContent["GLOBAL"]){
        $globalContent=$iniContent["GLOBAL"]
        $iniContent.Remove("GLOBAL")
        foreach($k in $globalContent.keys){
            $iniContent.Keys|%{$iniContent[$_][$k]=$globalContent[$k]}
        }
    }

    foreach($k in $iniContent.Keys){
        Search-InstanceInfo -Type $iniContent[$k]["Role"] -values $iniContent[$k] -templatefile D:\git\EasyAWSEnv\cf_template.json
    }
}

Function Search-InstanceInfo{
    Param(
        [Parameter(Mandatory=$True)]  
        [string]$Type,
        [Parameter(Mandatory=$True)]  
        [string]$values,  
        [string]$templatefile=(split-path -parent $MyInvocation.MyCommand.Definition)+"cf_template.json"
    )
    ((get-content "D:\git\EasyAWSEnv\cf_template.json")|ConvertFrom-Json)["Resources"][$Type]
}

Function Get-IniContent {     
    [CmdletBinding()]  
    Param(  
        [ValidateNotNullOrEmpty()]  
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq ".ini")})]  
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)]  
        [string]$FilePath  
    )  
      
    Begin  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}  
          
    Process  
    {  
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"  
              
        $ini = @{}  
        switch -regex -file $FilePath  
        {  
            "^\[(.+)\]$" # Section  
            {  
                $section = $matches[1]  
                $ini[$section] = @{}  
                $CommentCount = 0  
            }  
            "^(;.*)$" # Comment  
            {  
                if (!($section))  
                {  
                    $section = "No-Section"  
                    $ini[$section] = @{}  
                }  
                $value = $matches[1]  
                $CommentCount = $CommentCount + 1  
                $name = "Comment" + $CommentCount  
                $ini[$section][$name] = $value  
            }   
            "(.+?)\s*=\s*(.*)" # Key  
            {  
                if (!($section))  
                {  
                    $section = "No-Section"  
                    $ini[$section] = @{}  
                }  
                $name,$value = $matches[1..2]  
                $ini[$section][$name] = $value  
            }  
        }  
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing file: $FilePath"  
        Return $ini  
    }  
          
    End  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}  
}