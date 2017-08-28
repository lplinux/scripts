$now_date= Get-Date -UFormat "%Y%m%d"
$ABBY_ocr_log="c:\ocr_output\ocr logs.txt"
$ocr_folder="c:\ocr"
$ocr_log_age=5
$ocr_max_running_time=10
$exitcode=0
$statustxtocr=""


$ocr_log_last_write_time = [datetime](Get-ItemProperty -Path $ABBY_ocr_log -Name LastWriteTime).lastwritetime
$time = Get-Date
$ocr_log_time_difference_in_minutes = (New-TimeSpan -Start $ocr_log_last_write_time -End $time).TotalMinutes

   
If ($ocr_log_time_difference_in_minutes -gt $ocr_log_age)
{
    
    $pdf_count = Get-ChildItem $ocr_folder | Measure-Object
    
    If ($pdf_count.count -gt 0)
    {
        
        $pdf_size = (Get-ChildItem $ocr_folder | Measure-Object -property length -sum) 
        $ocr_max_running_time = ($pdf_size / 10485760)
        $ocr_max_running_time = [int]$ocr_max_running_time
        
        If ($ocr_log_time_difference_in_minutes -gt $ocr_max_running_time)
        {
            $statustxtocr = "There is a PDF running for " + $ocr_log_time_difference_in_minutes + " minutes. Check the server. " + $statustxtocr + ""
            $exitcode = [int]$exitcode + 2
        }
        Else
        {
            $statustxtocr = "There is a PDF running for " + $ocr_log_time_difference_in_minutes + " minutes. Wait a little bit longer. " + $statustxtocr + ""
            $exitcode = [int]$exitcode + 0
        }
    }
    Else
    {
        $statustxtocr = "The ocr process is not running since $ocr_log_time_difference_in_minutes minutes" + $statustxtocr + ""
        $exitcode = [int]$exitcode + 2
    }
    
}
Else
{
    $statustxtocr =  "The ocr process is running OK" + $statustxtocr + ""
    $exitcode = [int]$exitcode + 0
}


If ($exitcode -eq 0)
{
    echo "$exitcode Check_ABBY_ocr_logs - OK - $statustxtocr"
}

elseif ($exitcode -gt 0)
{
    $exitcode = 2
    echo "$exitcode Check_ABBY_ocr_logs - CRITICAL - $statustxtocr"
}
