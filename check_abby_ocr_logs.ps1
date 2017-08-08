$now_date= Get-Date -UFormat "%Y%m%d"
$ABBY_ocr_log="c:\ocr_output\ocr logs.txt"
$temp_ocr_log="c:\ocr_output\ocr_temp_log.txt"
$diff_ocr_log="c:\ocr_output\ocr_diff_log.txt"
$ocr_log_age=5
$ocr_max_running_time=10
$exitcode=0
$replace_temp_file=0
$statustxtocr=""

Compare-Object (Get-Content $ABBY_ocr_log) (Get-Content $temp_ocr_log) | %{$_.Inputobject + $_.SideIndicator} |  ft -auto| Out-File $diff_ocr_log

$running_count = Get-ChildItem -Path $diff_ocr_log -recurse | Select-String -Pattern "Running" | Measure-Object -line


If ($running_count.Lines -eq 0)
{
    $completed_count = Get-ChildItem -Path $diff_ocr_log -recurse | Select-String -Pattern "Completed" | Select-Object -last 1
    
    $ocr_log_last_write_time = [datetime](Get-ItemProperty -Path $ABBY_ocr_log -Name LastWriteTime).lastwritetime
    $time = Get-Date
    $ocr_log_time_difference_in_minutes = (New-TimeSpan -Start $ocr_log_last_write_time -End $time).TotalMinutes
    
    If ($ocr_log_time_difference_in_minutes -gt $ocr_log_age)
    {
        $statustxtocr = "The ocr process is not running since $ocr_log_time_difference_in_minutes minutes" + $statustxtocr + ""
        $exitcode = [int]$exitcode + 2
        $replace_temp_file=1
    }
    else
    {
        $statustxtocr =  "The ocr process is running OK" + $statustxtocr + ""
        $exitcode = [int]$exitcode + 0
        $replace_temp_file=1
    }
}

Else
{
    $recognition_time_count = Get-ChildItem -Path $diff_ocr_log -recurse | Select-String -Pattern "Recognition Time" | Measure-Object -line
    If ($running_count.Lines -eq $recognition_time_count.Lines)
    {
        $error_count = Get-ChildItem -Path $diff_ocr_log -recurse | Select-String -Pattern "Errors/Warnings" | Select-Object -last 1 | Out-String
        $error_count = $error_count.Split(':')[4]
        $error_count = $error_count.Split('/')[0]
        $error_count = $error_count.Trim()
        
        If ($error_count -gt 0)
        {
            $statustxtocr = "The last PDF had " + $error_count + " errors. Check the server. " + $statustxtocr + ""
            $exitcode = [int]$exitcode + 2
            $replace_temp_file=1
        }
        Else
        {
            $statustxtocr = "The last PDF had " + $error_count + " errors. " + $statustxtocr + ""
            $exitcode = [int]$exitcode + 0
            $replace_temp_file=1
        }
    }
    Else
    {
        $running_time = Get-ChildItem -Path $diff_ocr_log -recurse | Select-String -Pattern "Running" | Select-Object -last 1 | Out-String
        $running_time = $running_time.Split(':',4)[3]
        $running_time = $running_time.Split(' ')[0..3] -join ' '
        $running_time = [datetime](Get-Date $running_time)
        
        $time = Get-Date
        $running_time_difference_in_minutes = (New-TimeSpan -Start $running_time -End $time).TotalMinutes

        
        If ($running_time_difference_in_minutes -gt $ocr_max_running_time)
        {
            $statustxtocr = "There is a PDF running for " + $running_time_difference_in_minutes + " minutes. Check the server. " + $statustxtocr + ""
            $exitcode = [int]$exitcode + 2
            $replace_temp_file = 0
        }
        Else
        {
            $statustxtocr = "There is a PDF running for " + $running_time_difference_in_minutes + " minutes. Wait a little bit longer. " + $statustxtocr + ""
            $exitcode = [int]$exitcode + 0
            $replace_temp_file = 0
        }
    }
}


If ($exitcode -eq 0)
{
    If ($replace_temp_file -eq 1)
    {
        Copy-Item $ABBY_ocr_log $temp_ocr_log
    }
    echo "$exitcode Check_ABBY_ocr_logs - OK - $statustxtocr"
}

elseif ($exitcode -gt 0)
{
    If ($replace_temp_file -eq 1)
    {
        Copy-Item $ABBY_ocr_log $temp_ocr_log
    }
    $exitcode = 2
    echo "$exitcode Check_ABBY_ocr_logs - CRITICAL - $statustxtocr"
}
