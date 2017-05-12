Param(
  [string]
  $step_file="c:\setup\steps.xml"
)

function log($item){
$time=Get-Date -format "yyyy-MM-dd HH:mm:ss"
"$time $item"|out-file $logfile -Append
}

$basedir=Split-Path $step_file
if(-not (Test-Path $step_file)){
$step_xml=[xml]"<steps></steps>"
$top=$step_xml.SelectSingleNode("//steps")
Get-ChildItem env:|?{$_.name -match "step\d*"}|Sort-Object {[float]$_.name.substring(4)}|%{$e = $step_xml.CreateElement($_.name);$e.InnerText=$_.value;$top.AppendChild($e)}
$step_xml.save($step_file)
}
$logfile="$basedir\setup.log"

log "processing setup sripts..." 
$steps=[xml](get-content $step_file)
$allSteps=$steps.steps.ChildNodes
$currentStep=($AllSteps | ? {$_.status -eq "complete"}).count + 1
foreach($step in $allSteps){
    if($step.status -eq "complete"){
        continue
    }
    $cmd=$step.innerText
    log ("="*50+"Processing: $currentStep/$($allSteps.count)"+"="*50)
    log "processing setup sripts:$cmd"
    $currentStep++
    if($cmd -eq 'Restart-Computer'){
        $step.SetAttribute("status","complete")
        $steps.Save($step_file)
		shutdown /r
		exit
    }
    else{
            log (iex $cmd -ErrorVariable currenterror| Out-String)
            if($currenterror.Count -gt 0){log ("#"*10+"errors for this step"+"#"*10);log $currenterror}
    }
    
$step.SetAttribute("status","complete")
$steps.Save($step_file)
}
log "processing setup sripts completed"