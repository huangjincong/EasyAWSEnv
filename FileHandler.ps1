Function Make-CfFile {
	[CmdletBinding()]  
    Param( 
        [Parameter(Mandatory=$True)]  
        [string]$IniFile,
        [Hashtable]$extraParam=@{},
        [string]$teamplatePath=$PSScriptRoot+"\templates"
    )
    $iniContent=Get-IniContent $IniFile
    $jsonContent=@()
    $jsonContent+='{'
    $jsonContent+='    "AWSTemplateFormatVersion": "2010-09-09",'
    $jsonContent+='    "Description": "",'
    $jsonContent+='    "Resources": {'
        
    if(-not $iniContent["GLOBAL"]){
        $iniContent["GLOBAL"]=@{}
    }
    if($extraParam.Count -gt 0){$extraParam.Keys|%{$iniContent["GLOBAL"][$_]=$extraParam[$_]}}
    $globalContent=$iniContent["GLOBAL"]
    $iniContent.Remove("GLOBAL")
    foreach($k in $globalContent.keys){
        $iniContent.Keys|%{$iniContent[$_][$k]=$globalContent[$k]}
    }

    foreach($k in $iniContent.Keys){
        try{
            $jsonContent+=(Collect-InstanceInfo -Section $iniContent[$k] -templatePath $teamplatePath)
        }
        catch [Exception]{
            $_.Exception.message

        }
    }
    $jsonContent[$jsonContent.Count-1]=$jsonContent[$jsonContent.Count-1].TrimEnd(",")
    $jsonContent+="    }"
    $jsonContent+="}"
    $jsonContent|Out-File D:\git\EasyAWSEnv\1.json
}

Function Collect-InstanceInfo{
    Param(
        [Parameter(Mandatory=$True)]
        [HashTable]$Section, 
        [string]$templatePath
    )
    $Section["ResourceName"]=($Section["ComputerName"]+$Section["Role"]).replace("._","")
    $templateContent=Get-Content "$templatePath\$($Section['Role'])"
    $Section.Keys|%{$key=$_;$templateContent=($templateContent|%{$_.replace("#{$key}",$Section[$key])})}
    $matchItems=$templateContent -join "`n"| select-string -Pattern "#\{(.*)\}" -AllMatches | % { $_.Matches } |%{$_.Groups[1].value}
    if($matchItems){
        throw "The following items need to be replaced in templates for $($Section["ComputerName"]) :$matchItems"
    }
    return $templateContent
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