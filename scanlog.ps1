$path_to_log="PATH_TO_LOGS"
$info_age=10
$exitcode = 0

# Current timestamp
$now_date = Get-Date -UFormat "%Y%m%d"

$error_file = "$path_to_log\" + $now_date + "_error.txt"
$temp_error_file = "$path_to_log\temp_error.log"

$info_file = "$path_to_log\" + $now_date + "_info.txt"
$temp_info_file = "$path_to_log\temp_info.log"

　
If ((test-path $error_file))
{

    $last_error_line = Get-Content $error_file | Select-Object -last 1
    $last_temp_error_line = Get-Content $temp_error_file | Select-Object -last 1

    $error_diff = $last_error_line.equals($last_temp_error_line)

}

If ((test-path $info_file))
{

    $last_info_line = Get-Content $info_file | Select-Object -last 1
    $last_temp_info_line = Get-Content $temp_info_file | Select-Object -last 1

    $info_diff = $last_info_line.equals($last_temp_info_line)

}

　
If ((test-path $info_file))
{
        If ($error_diff -eq $false)
        {
            $statustxterror = "There is a new error."
            Write-Output $last_error_line  | Out-File $temp_error_file
            $exitcode = [int]$exitcode + 2
        }
        else
        {
            $statustxterror = "There are no new errors."
            $exitcode = [int]$exitcode + 0
        }

　
        $info_last_write_time = [datetime](Get-ItemProperty -Path $info_file -Name LastWriteTime).lastwritetime
        $time = Get-Date

        $info_time_difference_in_minutes = (NEW-TIMESPAN -Start $info_last_write_time -End $time).TotalMinutes
        $info_time_difference_in_minutes = [math]::Round($info_time_difference_in_minutes)
    
        If ($info_time_difference_in_minutes -gt $info_age)
        {
            $statustxtinfo = "The logfile had no new logs entry during the last $info_age minutes."
            $exitcode = [int]$exitcode + 2
        }

        If ($info_diff -eq $false)
        {
            Write-Output $last_info_line  | Out-File $temp_info_file
            $exitcode = [int]$exitcode + 0
        }

        If ($exitcode -eq 0)
        {
            echo "$exitcode Check_HIQ_logs - OK - $statustxtinfo $statustxterror"
        }
        elseif ($exitcode -gt 0)
        {
            $exitcode = 2
            echo "$exitcode Check_HIQ_logs - CRITICAL - $statustxtinfo $statustxterror"
        }
    
}
else
{
        $exitcode = [int]$exitcode + 2
        echo "$exitcode Check_HIQ_logs - CRITICAL - There are no logs for today"
}

# end of program

 
