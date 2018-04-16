<# 
        Script Library
  
        File:       ScriptLibrary1.18.psm1
    
        Purpose:    Contains common functions and routines useful in other scripts

        Author: Brandon Hilgeman 
                brandon.hilgeman@gmail.com

#>

Function Set-GlobalVariables{
    $Global:ComputerName = $env:computername
    $Global:WindowsPath = $env:windir+"\"
    $Global:DefaultLogPath = $WindowsPath+"_BPH\"
    $Global:DefaultLog = $DefaultLogPath+$ScriptName+".log"
    $Global:MaxLogSizeInKB = 1024*20
    $Global:TempPath = $env:TEMP+"\"
    $Global:ScriptStatus = 'Success'
    Detect-Runtime
}

Function Detect-Runtime{

    $IsInTS = $True
    Try{
        $oENV = New-Object -COMObject Microsoft.SMS.TSEnvironment
    }
    Catch{
        $IsInTS = $False
    }
    
    If($IsInTS -eq $True){

        If($oENV.Value("DEPLOYMENTMETHOD").ToUpper() -eq "SCCM"){
                $Global:RunTime = "SCCM"
        }
        ElseIf($oENV.Value("DEPLOYMENTMETHOD").ToUpper() -eq "MDT" -or $oENV.Value("DEPLOYMENTMETHOD").ToUpper() -eq "UNC" -or $oENV.Value("DEPLOYMENTMETHOD").ToUpper() -eq "MEDIA"){
            $Global:RunTime = "MDT"
        }
        Else{
            $Global:RunTime = "UNKNOWN"
        }
    }
    Else{
        $Global:RunTime = "STANDALONE"
    }

    If($Runtime -eq "SCCM"){
        $Global:Log = $oENV.Value("LogPath")+"\"+$ScriptName+".log"
        $Global:LogPath = $oENV.Value("LogPath")+"\"
        $DeployRoot = $oENV.Value("DeployRoot")+"\"
        $ScriptRoot = $oENV.Value("ScriptRoot")+"\"
    }
    ElseIf($Runtime -eq "MDT"){
        $Global:Log = $oENV.Value("LogPath")+"\"+$ScriptName+".log"
        $Global:LogPath = $oENV.Value("LogPath")+"\"
        $DeployRoot = $oENV.Value("DeployRoot")+"\"
        $ScriptRoot = $oENV.Value("ScriptRoot")+"\"
    }
    ElseIf($Runtime -eq "STANDALONE"){
        $Global:Log = $DefaultLog
        $Global:LogPath = $DefaultLogPath
    }
    Else{
        $Global:Log = $TempPath+$ScriptName+".log"
        $Global:LogPath = $TempPath
    }

    If(($IsInTS -eq $False) -and ($WindowsPath.substring(0,3) -eq "X:\")){
        $Global:RunTime = "MDT"
        $Global:Log = "X:\MININT\SMSOSD\OSDLOGS\$ScriptName.log"
        $Global:LogPath = "X:\MININT\SMSOSD\OSDLOGS\"
        $Global:BackupLog = $TempPath+$ScriptName+".log"
    }

}

Function Write-Log {
    Param (
        [Parameter(Mandatory=$true)]
        $Message,
        [Parameter(Mandatory=$false)]
        $ErrorMessage,
        [Parameter(Mandatory=$false)]
        $Component,
        [Parameter(Mandatory=$false)]
        [int]$Type,
        [Parameter(Mandatory=$false)]
        $LogFile
    )

    $Time = Get-Date -Format "HH:mm:ss.ffffff"
    $Date = Get-Date -Format "MM-dd-yyyy"
 
    If($ErrorMessage -ne $null){
        $Type = 3
    }
    If($Component -eq $null){
        $Component = $ScriptName
    }
    If($Type -eq $null){
        $Type = 1
    }
    If($LogFile -eq $null){
        $LogFile = $Log
    }

    If(!(Test-Path -Path $LogPath)){
        MkDir $LogPath | Out-Null
    }
 
    $LogMessage = "<![LOG[$Message $ErrorMessage" + "]LOG]!><time=`"$Time`" date=`"$Date`" component=`"$Component`" context=`"`" type=`"$Type`" thread=`"`" file=`"`">"
    $LogMessage | Out-File -Append -Encoding UTF8 -FilePath $Log

    If ((Get-Item $Log).Length/1KB -gt $MaxLogSizeInKB){
        $log = $Log
        Remove-Item ($log.Replace(".log", ".lo_"))
        Rename-Item $Log($log.Replace(".log", ".lo_")) -Force
    }
}

Function Start-Log {
    $StartDate = ((get-date).toShortDateString() + " " + (get-date).toShortTimeString())
    $global:ScriptStart = get-date
    Write-Log -Message ("-" * 10 + "  Start Script: $ScriptName " + $StartDate + " " + "-" * 10)
}

Function End-Log {
    $EndDate = ((get-date).toShortDateString() + " " + (get-date).toShortTimeString())
    $ScriptEnd = get-date
    #$RunTime = ($ScriptEnd.Minute - $ScriptStart.Minute)
    $RunTime = ($ScriptEnd - $ScriptStart)
    $RunTime = $RunTime.TotalMinutes
    $RunTime = [math]::round($Runtime , 0 )
    Write-Log -Message ("-" * 10 + "  End Script: " + $EndDate + "   RunTime: " + $RunTime + " Minute(s) " + "-" * 10)
}

Function Scan-Args {

}

Function Set-Mode {
    If($sArgs -eq "/Uninstall" -or $sArgs -eq "-Uninstall"){
        Write-Log "  $($MyInvocation.MyCommand.Name):: UNINSTALL"
        Start-Uninstall
    }
    Else{
        Write-Log "  $($MyInvocation.MyCommand.Name):: INSTALL"
        Start-Install
    }
}






<#'-------------------------------------------------------------------------------
  '---    GUI
  '-------------------------------------------------------------------------------#>


Function MsgBox {
    <#
        Buttons = AbortRetryIgnore, OK, OKCancel, RetryCancel, YesNo, YesNoCancel
        Icons = Asterisk, Error, Exclamation, Hand, Information, None, Question, Stop, Warning
    #>
    Param(
        [Parameter(Mandatory=$True)]
        [String]$Message,
        [Parameter(Mandatory=$False)]
        [String]$Title,
        [Parameter(Mandatory=$False)]
        $Buttons,
        [Parameter(Mandatory=$False)]
        [String]$Icon
    )

    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

    If($Buttons -eq $null){
        $Buttons = 0
    }
    If($Icon -eq ""){
        $Icon = 'Exclamation'
    }

    Write-Log -Message ("  $($MyInvocation.MyCommand.Name):: ""$Message"", ""$Title"", ""$Buttons""") -Type 1
    
    $MsgBox = [System.Windows.Forms.MessageBox]::Show("$Message", "$Title", $Buttons, $Icon)

    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $MsgBox pressed" -Type 1

    Return $MsgBox

}


Function Get-XAML{
    Param(
        [Parameter(Mandatory=$True)]
        $Path,
        [Parameter(Mandatory=$False)]
        $bVariables
    )

    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $Path"

    Try{
        $InputXML = Get-Content $Path
    }
    Catch{
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Unable to locate XAML file at: $Path" -Type 3
    }
    $InputXML = $InputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N'  -replace '^<Win.*', '<Window'
 
    [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
    [xml]$XAML = $InputXML
    #Read XAML
 
    $Reader = (New-Object System.Xml.XmlNodeReader $XAML)
    Try{
        $Global:Form=[Windows.Markup.XamlReader]::Load( $Reader )
    }
    Catch{
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed." -Type 3
    }
 
    $XAML.SelectNodes("//*[@Name]") | %{Set-Variable -Name "WPF$($_.Name)" -Value $Global:Form.FindName($_.Name) -Scope Global}
    #$WPFimage_logo.Source = "$PSScriptRoot\Images\Logo.bmp"
     
    If($bVariables){
        Get-FormVariables
    }

    Start-WPFApp
}


Function Get-FormVariables{
    If ($Global:ReadmeDisplay -ne $True){
        Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true
    }
    Write-Host "Found the following interactable elements from our form" -ForegroundColor Cyan
    Get-Variable WPF*
}


Function Show-GUI{
    Param(
        [Parameter(Mandatory=$False)]
        $WPFVariable
    )

    Try{
        $WPFVariable.Visibility = "Visible"
    }
    Catch{
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Unable to show: $WPFVariable"
    }
}


Function Hide-GUI{
    Param(
        [Parameter(Mandatory=$False)]
        $WPFVariable
    )

    Try{
        $WPFVariable.Visibility = "Hidden"
    }
    Catch{
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Unable to hide: $WPFVariable"
    }
}


Function Enable-GUI{
    Param(
        [Parameter(Mandatory=$False)]
        $WPFVariable
    )

    Try{
        $WPFVariable.IsEnabled = $True
    }
    Catch{
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Unable to Enable: $WPFVariable"
    }
}


Function Disable-GUI{
    Param(
        [Parameter(Mandatory=$False)]
        $WPFVariable
    )

    Try{
        $WPFVariable.IsEnabled = $False
    }
    Catch{
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Unable to Disable: $WPFVariable"
    }
}


Function Clear-GUI{
    Param(
        [Parameter(Mandatory=$False)]
        $WPFVariable,
        [Parameter(Mandatory=$False)]
        $Type
    )

    If($Type -eq "text"){
        Try{$WPFVariable.Clear()}
        Catch{}
    }
    ElseIf($Type -eq "combo"){
        Try{
            $WPFVariable.Items.Clear()
        }
        Catch{}
    }
}

Function Add-GUIText{
    Param(
        [Parameter(Mandatory=$False)]
        $WPFVariable,
        [Parameter(Mandatory=$False)]
        $Text
    )
    Try{
        $WPFVariable.AddText($Text)
    }
    Catch{
        Write-Log "  $($MyInvocation.MyCommand.Name):: Failed to add text to: $WPFVariable"
    }
}


Function Show-BalloonTip{          
   s
}



<#'-------------------------------------------------------------------------------
  '---    Systems
  '-------------------------------------------------------------------------------#>


Function Test-Ping{
    Param(
        [Parameter(Mandatory=$True)]
        $HostName
    )
    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $HostName"

    $TestPing = Test-Connection -ComputerName $HostName -ErrorAction SilentlyContinue -ErrorVariable iErr;
    If($iErr){
        Write-Log -Message "  $($MyInvocation.MyCommand.Name)::ERROR Unable to Ping: $HostName" -Type 3
        $TestPing = $False
    }
    Else{
        Write-Log "  $($MyInvocation.MyCommand.Name):: $HostName SUCCESS"
        $TestPing = $True
        Return $TestPing
    }
}

Function Get-ComputerName {
    Write-Log "  $($MyInvocation.MyCommand.Name)::"

    $GetComputerName = $env:computername

    Write-Log "  $($MyInvocation.MyCommand.Name)::$GetComputerName"

    Return $GetComputerName
}

Function Get-Make{
    Write-Log "  $($MyInvocation.MyCommand.Name)::"

    Try{
        $GetMake = (Get-WmiObject -Class Win32_ComputerSystem).Manufacturer
    }
    Catch{
        Write-Log "  $($MyInvocation.MyCommand.Name)::Unable to find Manufacturer" -Type 3
    }

    Write-Log "  $($MyInvocation.MyCommand.Name):: '$GetMake'"
    Return $GetMake
}



Function Get-Model{
    Write-Log "  $($MyInvocation.MyCommand.Name)::"

    Try{
        $GetModel = (Get-WmiObject -Class Win32_ComputerSystem).Model
    }
    Catch{
        Write-Log "  $($MyInvocation.MyCommand.Name)::Unable to find Model" -Type 3
    }

    Write-Log "  $($MyInvocation.MyCommand.Name):: '$GetModel'"
    Return $GetModel
}

Function Get-CurrentUser{
    Write-Log "  $($MyInvocation.MyCommand.Name)::"

    Try{
        $GetUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    }
    Catch{
        Write-Log "  $($MyInvocation.MyCommand.Name)::Unable to find Logged on user" -Type 3
    }

    Write-Log "  $($MyInvocation.MyCommand.Name):: '$GetUser'"
    Return $GetUser
}




<#'-------------------------------------------------------------------------------
  '---    Processes
  '-------------------------------------------------------------------------------#>

Function Is-ProcessRunning{

    Param(
        [Parameter(Mandatory=$True)]
        $Process
    )
    Write-Log "  $($MyInvocation.MyCommand.Name)::"
    
    If($Process -contains '"'){
        $Process = $Process -replace '"',''
    }
    If($Process.substring($Process.length - 4,4) -eq ".exe"){
        $Process = $Process -replace '.exe',''
    }

    $IsProcessRunning = Get-Process $Process -ErrorAction SilentlyContinue
    #$IsProcessRunning
    If ($IsProcessRunning){
        $RunningProcess = $True
    }
    Else{
        $RunningProcess = $False
    }
    Write-Log "  $($MyInvocation.MyCommand.Name)::'$Process' Returned: $RunningProcess"
    Return $RunningProcess 

}


Function End-Process{

    Param(
        [Parameter(Mandatory=$True)]
        $Process
    )

    Write-Log "  $($MyInvocation.MyCommand.Name)::$Process"
    
    If($Process -contains '"'){
        $Process = $Process -replace '"',''
    }
    If($Process -contains '"'){
        $Process = $Process -replace '"',''
    }
    If($Process.substring($Process.length - 4,4) -eq ".exe"){
        $Process = $Process -replace '.exe',''
    }

    $RunningProcess = Get-Process $Process -ErrorAction SilentlyContinue

    If(Is-ProcessRunning -sProcess $Process){
        $RunningProcess.CloseMainWindow()
        Sleep 3
    }
    Else{
        Write-Log "  $($MyInvocation.MyCommand.Name)::'$Process' is not running"
        Return
    }
    
    If (!$RunningProcess.HasExited){
        $RunningProcess | Stop-Process -Force
        Sleep 3
    }
    
    If(Is-ProcessRunning -sProcess $Process){
        Write-Log "  $($MyInvocation.MyCommand.Name)::'$Process' UnSuccessfully terminated"
    }
    Else{
        Write-Log "  $($MyInvocation.MyCommand.Name)::'$Process' Successfully terminated"
    }

}


<#'-------------------------------------------------------------------------------
  '---    Software
  '-------------------------------------------------------------------------------#>

Function Run-Install {
    Param(
        [Parameter(Mandatory=$True)]
        [String]$CMD,
        [String]$Parameter
     )

    Write-Log -Message "  $($MyInvocation.MyCommand.Name)::"

    $ENV:SEE_MASK_NOZONECHECKS = 1

    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: ""$CMD"" $Parameter" -type 1

    $RunInstall = Start-Process $CMD -ArgumentList $Parameter -PassThru -Wait
    $ErrorCode = $RunInstall.ExitCode

    If($ErrorCode -ne 0){
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Command Completed with Error: $ErrorCode" -Type 3
    }
    Else{
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Command Completed Successfully RETURN CODE: $ErrorCode" -Type 1
    }
    
    $ENV:SEE_MASK_NOZONECHECKS = 0

    Return $ErrorCode | Out-Null

}


 Function Run-Uninstall {
    Param(
        [Parameter(Mandatory=$True)]
        $Name,
        [Parameter(Mandatory=$True)]
        $Version
    )
  
    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: ""$Name"", ""$Version"""
    $cItems = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE '$Name' And Version Like '$Version'"
    If(!$cItems){
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Application: ""$Name"" Version: ""$Version"" - Not found on system"
        Return
    }
    ForEach($oItem in $cItems){
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: "($oItem.Name + ", " + $oItem.Version) -Type 1
        Try{
            $RunUninstall = $oItem.Uninstall()
        }
        Catch{
            Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Uninstall Completed with Error: "$RunUninstall.ExitCode -Type 3
        }
        Write-Log  -Message "  $($MyInvocation.MyCommand.Name):: Uninstall Completed Successfully" -Type 1
    }
 }

 <#Function Run-UnInstall {
    Param(
        [Parameter(Mandatory=$True)]
        [String]$CMD,
        [String]$Parameter
     )
    
    Write-Log -Message "  $($MyInvocation.MyCommand.Name)::"

    $ENV:SEE_MASK_NOZONECHECKS = 1

    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $CMD $Parameter"

    $RunUnInstall = Start-Process $CMD -ArgumentList $Parameter -PassThru -Wait
    $ErrorCode = $RunUnInstall.ExitCode

    If($ErrorCode -ne 0){
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Command Completed with Error: $ErrorCode" -Type 3
    }
    Else{
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Command Completed Successfully RETURN CODE: $ErrorCode" -Type 1
    }

    $ENV:SEE_MASK_NOZONECHECKS = 0

    Return $ErrorCode
}#>



 Function Log-InstalledApps {
    Write-Log "  $($MyInvocation.MyCommand.Name)::"
    $UninstallRegKeys=@("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall", "SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall")           
    ForEach($Computer in $ComputerName){
        If(Test-Connection -ComputerName $Computer -Count 1 -ea 0) {
            ForEach($UninstallRegKey in $UninstallRegKeys){
                Try {            
                    $HKLM   = [microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$computer)
                    $UninstallRef  = $HKLM.OpenSubKey($UninstallRegKey)
                    $Applications = $UninstallRef.GetSubKeyNames()
                }
                Catch {            
                    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Failed to read $UninstallRegKey"          
                    Continue
                }
            }
        }
    }
            
    ForEach ($App in $Applications) {
        $AppRegistryKey  = $UninstallRegKey + "\\" + $App
        $AppDetails   = $HKLM.OpenSubKey($AppRegistryKey)
        $AppGUID   = $App
        $AppDisplayName  = $($AppDetails.GetValue("DisplayName"))
        $AppVersion   = $($AppDetails.GetValue("DisplayVersion"))
        $AppPublisher  = $($AppDetails.GetValue("Publisher"))
        $AppInstalledDate = $($AppDetails.GetValue("InstallDate"))
        $AppUninstall  = $($AppDetails.GetValue("UninstallString"))
           If($UninstallRegKey -match "Wow6432Node"){
            $Softwarearchitecture = "x86"
           }
           Else {
                $Softwarearchitecture = "x64"
           }
           If(!$AppDisplayName){
            continue
           }
           Write-Log -Message "  $($MyInvocation.MyCommand.Name):: ""$AppDisplayName""  Version: ""$AppVersion"""
    }
}

Function Is-SoftwareInstalled {
    Param(
        [Parameter(Mandatory=$True)]
        $Product,
        [Parameter(Mandatory=$True)]
        $Version
    )
    $IsSoftwareInstalled = $False

    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: ""$Product"" ""$Version"""

    $UninstallRegKeys=@("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall", "SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall")           

    ForEach($Computer in $ComputerName) {
        If(Test-Connection -ComputerName $Computer -Count 1 -ErrorAction 0) {
            ForEach($UninstallRegKey in $UninstallRegKeys) {
                Try {      
                    [hashtable]$Return = @{}      
                    $HKLM   = [microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$computer)            
                    $UninstallRef  = $HKLM.OpenSubKey($UninstallRegKey)            
                    $Applications = $UninstallRef.GetSubKeyNames()
                    ForEach ($App in $Applications){
                        $AppRegistryKey  = $UninstallRegKey + "\\" + $App
                        $AppDetails   = $HKLM.OpenSubKey($AppRegistryKey)
                        $AppGUID   = $App
                        $AppDisplayName  = $($AppDetails.GetValue("DisplayName"))
                        $AppVersion   = $($AppDetails.GetValue("DisplayVersion"))
                        $AppPublisher  = $($AppDetails.GetValue("Publisher"))
                        $AppInstalledDate = $($AppDetails.GetValue("InstallDate"))
                        $AppUninstall  = $($AppDetails.GetValue("UninstallString"))
                        If($UninstallRegKey -match "Wow6432Node"){
                            $Softwarearchitecture = "x86"
                        }
                        Else{
                            $Softwarearchitecture = "x64"
                        }
                        If(!$AppDisplayName){
                            Continue
                        }
                        If(($AppDisplayName -like $Product) -and ($AppVersion -like $Version)){
                            $Return.AppDisplayName = $AppDisplayName
                            $Return.AppVersion = $AppVersion
                            $IsSoftwareInstalled = $True
                            $Return.IsSoftwareInstalled = $IsSoftwareInstalled
                            Write-Log -Message "  $($MyInvocation.MyCommand.Name)::  ""$AppDisplayName"" ""$AppVersion"""
                            Return $IsSoftwareInstalled
                        }
    }          
                }
                Catch {            
                    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Failed to read $UninstallRegKey" -Type 3
                    Continue
                }
            }
        }
    }
}

 <#'-------------------------------------------------------------------------------
   '---    File System
   '-------------------------------------------------------------------------------#>

Function Create-Folder {
    Param(
        [Parameter(Mandatory=$True)]
        $Path
        )
    Write-Log "  $($MyInvocation.MyCommand.Name):: Function started"
    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $Path"
    If(!(Test-Path -Path $Path)){
        $CreateFolder = New-Item -ItemType directory -Path $Path -Force -ErrorAction SilentlyContinue -ErrorVariable iErr;
        If($iErr){
            Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Could not create directory: ""$Path""" -Type 3
        }
        Else{
            Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Created directory: ""$Path"""
        }
    }
    Else{
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: ""$Path"" already exists"
        }
}

Function Copy-File {
    Param(
        [Parameter(Mandatory=$True)]
        [String]$Source,
        [Parameter(Mandatory=$True)]
        [String]$Destination
    )
    Write-Log "  $($MyInvocation.MyCommand.Name):: Function started"
    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $Source, $Destination"
    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Source: $Source"
    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Destination: $Destination"

    If(!(Test-Path -Path $Destination)){
        New-Item -ItemType File -Path $Destination -Force
    }

    If(!(Test-Path -Path $Source)){
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Unsucessful (Invalid Source Path)" -Type 3
    }
    Else{
        $CopyFile = Copy-Item -Path $Source -Destination $Destination -Force -ErrorAction SilentlyContinue -ErrorVariable iErr;
        If($iErr){
            Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Unsucessful" -Type 3
        }
        Else {
            Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Success" -Type 1
        }
    }
}

Function Copy-Folder{
    Param(
        [Parameter(Mandatory=$True)]
        [String]$Source,
        [Parameter(Mandatory=$True)]
        [String]$Destination
    )
    Write-Log "  $($MyInvocation.MyCommand.Name):: Function started"
    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $Source, $Destination"
    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Source: $Source"
    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Destination: $Destination"

    If(!(Test-Path -Path $Destination)){
        Create-Folder $Destination
    }
    
    If(!(Test-Path -Path $Source)){
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Unsucessful (Invalid Source Path)" -Type 3
    }
    Else{
        $CopyFolder = Copy-Item -Path $Source -Destination $Destination -Force -Recurse -ErrorAction SilentlyContinue -ErrorVariable iErr;
        If ($iErr){
            Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Unsucessful" -Type 3
        }
        Else{
            Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Success" -Type 1
        }
    }
}

Function Delete-Object {
    Param(
        [Parameter(Mandatory=$True)]
        $Path
    )
    Write-Log "  $($MyInvocation.MyCommand.Name):: Function started"
    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $Path"

    If(!(Test-Path -Path $Path)){
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $Path does not exist" -Type 3
    }
    Else{
        $DeleteObject = Remove-Item $Path -Force -Recurse -ErrorAction SilentlyContinue -ErrorVariable iErr;
        If($iErr){
            Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Object Deletion Failed" -Type 3
        }
        Else{
            Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Object Deletion Completed Successfully"
        }
    }
}


Function Get-IniContent {  
    [CmdletBinding()]  
    Param(  
        [ValidateNotNullOrEmpty()]  
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq ".ini")})]  
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)]  
        [string]$FilePath  
    )  
      
    Begin{
        Write-Log "  $($MyInvocation.MyCommand.Name):: Function started"
    }  
          
    Process{  
        Write-Log "  $($MyInvocation.MyCommand.Name):: Processing file: $Filepath"  
              
        $ini = @{}  
        Switch -Regex -File $FilePath  
        {  
            "^\[(.+)\]$" # Section  
            {  
                $section = $matches[1]  
                $ini[$section] = @{}  
                $CommentCount = 0  
            }  
            "^(;.*)$" # Comment  
            {  
                If (!($section))  
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
        Write-Log "  $($MyInvocation.MyCommand.Name):: Finished Processing file: $FilePath"  
        Return $ini  
    }  
          
    End{
        Write-Log "  $($MyInvocation.MyCommand.Name):: Function ended"
    }
} 

Function Out-IniFile {
      
    [CmdletBinding()]  
    Param(  
        [switch]$Append,  
          
        [ValidateSet("Unicode","UTF7","UTF8","UTF32","ASCII","BigEndianUnicode","Default","OEM")]  
        [Parameter()]  
        [string]$Encoding = "Unicode",  
 
          
        [ValidateNotNullOrEmpty()]  
        [ValidatePattern('^([a-zA-Z]\:)?.+\.ini$')]  
        [Parameter(Mandatory=$True)]  
        [string]$FilePath,  
          
        [switch]$Force,  
          
        [ValidateNotNullOrEmpty()]  
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)]  
        [Hashtable]$InputObject,  
          
        [switch]$Passthru  
    )  
      
    Begin{
        Write-Log "  $($MyInvocation.MyCommand.Name):: Function started"
    }  
          
    Process{  
        Write-Log "  $($MyInvocation.MyCommand.Name):: Writing to file: $Filepath"  
          
        If ($append){
            $outfile = Get-Item $FilePath
        }  
        Else{
            $outFile = New-Item -ItemType file -Path $Filepath -Force:$Force
        }  
        If(!($outFile)){
            Throw "Could not create File"
        }  
        Foreach($i in $InputObject.keys){  
            If (!($($InputObject[$i].GetType().Name) -eq "Hashtable")){  
                #No Sections  
                Write-Log "  $($MyInvocation.MyCommand.Name):: Writing key: $i"  
                Add-Content -Path $outFile -Value "$i=$($InputObject[$i])" -Encoding $Encoding  
            }
            Else{  
                #Sections  
                Write-Log "  $($MyInvocation.MyCommand.Name):: Writing Section: [$i]"  
                Add-Content -Path $outFile -Value "[$i]" -Encoding $Encoding  
                Foreach ($j in $($InputObject[$i].keys | Sort-Object))  
                {  
                    If($j -match "^Comment[\d]+"){  
                        Write-Log "  $($MyInvocation.MyCommand.Name):: Writing comment: $j"  
                        Add-Content -Path $outFile -Value "$($InputObject[$i][$j])" -Encoding $Encoding  
                    } 
                    Else{
                        Write-Log "  $($MyInvocation.MyCommand.Name):: Writing key: $j"  
                        Add-Content -Path $outFile -Value "$j=$($InputObject[$i][$j])" -Encoding $Encoding  
                    }  
                      
                }  
                Add-Content -Path $outFile -Value "" -Encoding $Encoding  
            }  
        }  
        Write-Log "  $($MyInvocation.MyCommand.Name):: Finished Writing to file: $Filepath"  
        If($PassThru){
            Return $outFile
        }  
    }  
          
    End{
            Write-Log "  $($MyInvocation.MyCommand.Name):: Function ended"
        }  
} 



<#'-------------------------------------------------------------------------------
  '---    Operating System
  '-------------------------------------------------------------------------------#>

Function Get-OSArchitecture{

    Write-Log -Message "  $($MyInvocation.MyCommand.Name)::"
    
    $GetOSArchitecture = (Get-WmiObject Win32_OperatingSystem -computername $env:COMPUTERNAME).OSArchitecture

    If($GetOSArchitecture -eq "64-BIT"){
        $GetOSArchitecture = "64"
    }
    Else{
        $GetOSArchitecture = "32"
    }

    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: ""$GetOSArchitecture"""

    Return $GetOSArchitecture.ToString()
}


Function Get-OSName{
    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Function Started"
    $OSName = Get-Itemproperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName.ProductName
    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $OSName"

    Return $OSName

}


<#'-------------------------------------------------------------------------------
  '---    Registry
  '-------------------------------------------------------------------------------#>


Function Read-Registry {
    Param(
        [Parameter(Mandatory=$True)]
        $Path,
        [Parameter(Mandatory=$True)]
        $Name
    )

    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $Path\$Name"
    
    If(!(Test-Path -Path $Path)){
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Registry Path Not Found" -Type 3
        Return
    }

    $ReadRegistry = Get-ItemProperty -Path $Path -Name $Key -ErrorAction SilentlyContinue -ErrorVariable iErr | ForEach-Object {$_.$Name}

    If($iErr){
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Unable to read registry" -Type 3
    }

    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: '$ReadRegistry'"

    Return $ReadRegistry
}


Function Write-Registry{
    Param(
        [Parameter(Mandatory=$True)]
        $Path, #Ex "HKLM:\SOFTWARE\Wow6432Node"
        [Parameter(Mandatory=$True)]
        $Name, #Ex "Adobe"
        [Parameter(Mandatory=$False)]
        $Type, #Ex "String"
        [Parameter(Mandatory=$True)]
        $Value, #Ex "1.1.2.0"
        [Parameter(Mandatory=$True)]
        $Force
    )

    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $Path : $Name : $Type : $Value"
    
    If(!(Test-Path -Path $Path)){
        $CMD = New-Item -Path $Path -ErrorAction SilentlyContinue -ErrorVariable iErr;

        If($iErr){
            Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Unable to write to registry" -Type 3
            Return.$CMD
        }
    }
    
    If((Read-Registry -sPath $Path -sName $Name) -eq $Value){
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Registry Key Already Exists"
        Return
    }
    If($Force -eq $True){
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Registry Key will be forcefully overwritten"
    }
    Else{
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Registry Key will not be overwritten, use -Force $True to forcefully overwrite"
        Return
    }
   
    $WriteRegistry = New-ItemProperty -Path $Path -Name $Name -PropertyType $Type -Value $Value -Force

    If((Get-ItemProperty $Path -Name $Name -ErrorAction SilentlyContinue).$Name){
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Registry key Written successfully"
    }
    Else{
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Failed to write registry key"
        Return.$WriteRegistry
    }
}



<#'-------------------------------------------------------------------------------
 '---    Active Directory
 '-------------------------------------------------------------------------------#>


Function AD_ManageGroup{
    Param(
        [Parameter(Mandatory=$False)]
        $Domain,
        [Parameter(Mandatory=$True)]
        $Function,
        [Parameter(Mandatory=$True)]
        $Type,
        [Parameter(Mandatory=$True)]
        $Name,
        [Parameter(Mandatory=$True)]
        $Group,
        [Parameter(Mandatory=$False)]
        $ADUser,
        [Parameter(Mandatory=$False)]
        $ADPass
    )

    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: '$Domain', '$Function', '$Type', '$Name', '$Group', '$ADUser', '$ADPass'"
    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Importing Active Directory Module"
    
    $ImportModule = (Import-Module ActiveDirectory -PassThru -ErrorAction SilentlyContinue -ErrorVariable iErr).ExitCode
    
    If($iErr){Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Unable to import AD Module Error: $ImportModule" -type 3
        Return}
    Else{
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Imported AD Module"
    }

    If($Type -eq "User"){
        $GetUser = Get-ADUser -Identity $Name -Properties MemberOf,sAMAccountName -ErrorAction SilentlyContinue -ErrorVariable iErr | Select-Object MemberOf,sAMAccountName

        If($iErr){
            Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Unable to locate $Type : '$Name' in AD" -Type 3
            Return
        }

        If($Function -eq "Add"){
            If ($GetUser.MemberOf -match $Group){
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: '$Name' is already a member of '$Group'"
                Return}
            Else{
                $CMD = Add-ADGroupMember -Identity "$Group" -Members "$Name" -Confirm:$False -ErrorAction SilentlyContinue -ErrorVariable iErr;
                If($iErr){
                    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Adding '$Name' to '$Group' failed" -type 3
                    Return
                } 
                Else{
                    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Added '$Name' to '$Group' successfully"
                }
            }
        }
        ElseIf($Function -eq "Remove"){
            If (!($GetUser.MemberOf -match $Group)){
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: '$Name' is already not a member of '$Group'"
                Return
            }
            $CMD = Remove-ADGroupMember -Identity "$Group" -Members "$Name" -Confirm:$False -ErrorAction SilentlyContinue -ErrorVariable iErr;
            If($iErr){
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Removing '$Name' from '$Group' failed" -type 3
                Return
            } 
            Else{
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Removed '$Name' from '$Group' successfully"
            }
        }
        ElseIf($Function -eq "Query"){
            If ($GetUser.MemberOf -match $Group){
                    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: '$Name' is a member of '$Group'"
                    Return}
            Else{
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: '$Name' is NOT a member of '$Group'"
            }
        }
     }


     If($Type -eq "Computer"){
        $GetComputer = Get-ADComputer $Name -Properties MemberOf -ErrorAction SilentlyContinue -ErrorVariable iErr

        If($iErr){
            Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Unable to locate $Type : '$Name' in AD" -Type 3
            Return
        }


        If($Function -eq "Add"){
            If ($GetComputer.MemberOf -match $Group){
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: '$Name' is already a member of '$Group'"
                Return}
            Else{
                $CMD = Add-ADGroupMember -Identity "$Group" -Members "$Name$" -Confirm:$False -ErrorAction SilentlyContinue -ErrorVariable iErr;
                If($iErr){
                    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Adding '$Name' to '$Group' failed" -type 3
                    Return
                } 
                Else{
                    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Added '$Name' to '$Group' successfully"
                }
            }
        }
        ElseIf($Function -eq "Remove"){
            If (!($GetComputer.Memberof -match $Group)){
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: '$Name' is already not a member of '$Group'"
                Return
            }
            $CMD = Remove-ADGroupMember -Identity "$Group" -Members "$Name$" -Confirm:$False -ErrorAction SilentlyContinue -ErrorVariable iErr;
            If($iErr){
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Removing '$Name' from '$Group' failed" -type 3
                Return
            } 
            Else{
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Removed '$Name' from '$Group' successfully"
            }
        }
        ElseIf($Function -eq "Query"){
            If ($GetComputer.Memberof -Match $Group){
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: '$Name' is a member of '$Group'"
                Return
            }
            Else{
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: '$Name' is NOT a member of '$Group'"
            }
        }
     } 


     If($Type -eq "Group"){
        $GetGroup = (Get-ADGroup -Identity $Name -Properties MemberOf -ErrorAction SilentlyContinue -ErrorVariable iErr | Select-Object MemberOf)
        If($iErr){
            Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Unable to locate $Type : '$Name' in AD" -Type 3
            Return
        }

        If($Function -eq "Add"){
            If ($GetGroup.MemberOf -match $Group){
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: '$Name' is already a member of '$Group'"
                Return
            }
            Else{
                $CMD = Add-ADGroupMember -Identity "$Group" -Members "$Name" -Confirm:$False -ErrorAction SilentlyContinue -ErrorVariable iErr;
                If($iErr){
                    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Adding '$Name' to '$Group' failed" -type 3
                    Return
                } 
                Else{
                    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Added '$Name' to '$Group' successfully"
                }
            }
        }
        ElseIf($Function -eq "Remove"){
            If (!($GetGroup.MemberOf -match $Group)){
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: '$Name' is already not a member of '$Group'"
                Return
            }
            $CMD = Remove-ADGroupMember -Identity "$Group" -Members "$Name" -Confirm:$False -ErrorAction SilentlyContinue -ErrorVariable iErr;
            If($iErr){
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Removing '$Name' from '$Group' failed" -type 3
                Return
            } 
            Else{
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Removed '$Name' from '$Group' successfully"
            }
        }
        ElseIf($Function -eq "Query"){
            If ($GetGroup.MemberOf -match $Group){
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: '$Name' is a member of '$Group'"
                Return
            }
            Else{
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: '$Name' is NOT a member of '$Group'"
            }
        }
     } 
}

Function AD_ManageGroupADSI{
<#
  .SYNOPSIS
    Adds/Removes Users/Computers/Groups To/From Groups
  .DESCRIPTION
    Does not require the Active Directory module and allows you to pass alternate credentials to run under.
    sFunction Options Are: Add or Remove
    sType Options Are: User, Computer, or Group
    sADUser and sADPass are optional and are only needed when alternate credentials need supplied
  .EXAMPLE
    AD_ManageGroupADSI -sDomain "contoso.org" -sFunction "Add" -sType "User" -sName "abc20a" -sGroup "GROUP_1"
  .EXAMPLE
    AD_ManageGroupADSI -sDomain "contoso.org" -sFunction "Add" -sType "Computer" -sName "DT12345678" -sGroup "GROUP_1" -sADUser "abc123a" -sADPass "P@ssw0rd"
  .EXAMPLE
    AD_ManageGroupADSI -sDomain "contoso.org" -sFunction "Remove" -sType "Computer" -sName "DT12345678" -sGroup "GROUP_1" -sADUser "abc123a" -sADPass "P@ssw0rd"
  .EXAMPLE
    AD_ManageGroupADSI -sDomain "contoso.org" -sFunction "Add" -sType "User" -sName "czt20b" -sGroup "GROUP_1" -sADUser "abc123a" -sADPass "P@ssw0rd"
  .EXAMPLE
    AD_ManageGroupADSI -sDomain "contoso.org" -sFunction "Add" -sType "Group" -sName "GROUP_42" -sGroup "GROUP_1" -sADUser "abc123a" -sADPass "P@ssw0rd"
  #>
    Param(
        [Parameter(Mandatory=$False)]
        $Domain,
        [Parameter(Mandatory=$True)]
        $Function,
        [Parameter(Mandatory=$True)]
        $Type,
        [Parameter(Mandatory=$True)]
        $Name,
        [Parameter(Mandatory=$True)]
        $Group,
        [Parameter(Mandatory=$False)]
        $ADUser,
        [Parameter(Mandatory=$False)]
        $ADPass
    )

    [int]$ADS_PROPERTY_APPEND = 3

    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Function Started"

    $GroupPath = Get-ADSPath -sDomain $Domain -sType "Group" -sName $Group -sADUser $ADUser -sADPass $ADPass
    $ObjectPath = Get-ADSPath -sDomain $Domain -sType $Type -sName $Name -sADUser $ADUser -sADPass $ADPass

    If($GroupPath -eq $Null){
        Return
    }
    If($ObjectPath -eq $Null){
        Return
    }

    $ObjectDN = $ObjectPath.adspath.Replace("$Domain/", "")
    #$ObjectDN = $ObjectPath.Replace("$Domain/", "")
    #Write-Log -Message "  DN: $ObjectDN"

    $ObjectCN = $ObjectPath.adspath.Replace("LDAP://$Domain/", "")
    #$ObjectCN = $ObjectPath.Replace("LDAP://$Domain/", "")
    #Write-Log -Message "  CN: $ObjectCN"

    $GroupDN = $GroupPath.adspath.Replace("$Domain/", "")
    #$GroupDN = $GroupPath.Replace("$Domain/", "")
    #Write-Log -Message "  DN: $GroupDN"
    
    If($ADUser -and $ADPass){
        $oGroup = New-Object DirectoryServices.DirectoryEntry($GroupDN,$ADUser,$ADPass)
    }
	Else{
        $oGroup = [ADSI]$GroupDN
    }

    $oComputer = [ADSI]$ObjectDN

    If($Function -eq "Add"){
        Try{
	        #Verify if the computer is a member of the Group
	        If ($oGroup.ismember($oComputer.adspath) -eq $False){
		        #Add the the computer to the specified group
		        $oGroup.PutEx($ADS_PROPERTY_APPEND,"member",@("$ObjectCN"))
		        $oGroup.setinfo()
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Added $Name to $Group"
	        }
            Else{
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $Name is already a member of $Group"
            }
        }
        Catch{
            Write-Log -Message "  $($MyInvocation.MyCommand.Name)::  Unable to query $Group for membership status. If credentials were passed check that credentials are valid" -Type 3
            Return}
    }

    If($Function -eq "Remove"){
        Try{
            #Verify if the computer is a member of the Group
	        If ($oGroup.ismember($oComputer.adspath) -eq $False){
		        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $Name is not a member of $Group"
	        }
            Else{
                #Add the the computer to the specified group
		        $oGroup.Member.Remove($ObjectCN)
		        $oGroup.setinfo()
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Removed $Name from $Group"
            }
        }
        Catch{
            Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Unable to query $Group for membership status. If credentials were passed check that credentials are valid" -Type 3
            Return
        }
    }
}#End Function


Function AD_ManageComputers{
    Param(
        [Parameter(Mandatory=$True)]
        $Path,
        [Parameter(Mandatory=$False)]
        $Function,
        [Parameter(Mandatory=$False)]
        $DaysInactive
        )

        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $Path, $Function, $DaysInactive"

        $ImportModule = (Import-Module ActiveDirectory -PassThru -ErrorAction SilentlyContinue -ErrorVariable iErr).ExitCode
    
            If($iErr){
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Unable to import AD Module Error: $ImportModule" -type 3
                Return
            }
            Else{
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Imported AD Module"
            }

        If($Function -eq "Disable"){
            
            $Machines = Get-Content -Path $Path -ErrorAction SilentlyContinue -ErrorVariable iErr;

            If($iErr){
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Unable to locate or open $Path"
                Return
            }
            Else{
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Machine List Loaded Sucessfully."
            }

            $Machines | foreach {
                Try{
                   $DisablePC =  Get-ADComputer -Identity $_ -ErrorAction SilentlyContinue | Disable-ADAccount -Confirm:$false -ErrorAction SilentlyContinue
                    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $_ Sucessfully Disabled in Active Directory."
                }
    
                Catch{
                    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: ($_) Does not exist in Active Directory." -Type 3
                }
            }
        }

         If($Function -eq "Delete"){
       
            $Machines = Get-Content -Path $Path -ErrorAction SilentlyContinue -ErrorVariable iErr;

            If($iErr){
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Unable to locate or open $Path"
                Return
            }
            Else{
                Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Machine List Loaded Sucessfully."
            }

            $Machines | ForEach {
                Try{
                   $DisablePC =  Get-ADComputer -Identity $_ -ErrorAction SilentlyContinue | Delete-ADAccount -Confirm:$false -ErrorAction SilentlyContinue
                    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $_ Sucessfully Disabled in Active Directory."
                }
    
                Catch{
                    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: ($_) Does not exist in Active Directory." -Type 3
                }
            }
        }

        If($Function -eq "QueryInactive"){

            $Time = (Get-Date).Adddays(-($DaysInactive))
 
            # Get all AD computers with lastLogonTimestamp less than our time
            Get-ADComputer -server "ghs.org" -Filter {LastLogonTimeStamp -lt $Time} -Properties LastLogonTimeStamp |
 
            # Output hostname and lastLogonTimestamp into CSV
            select-object Name | export-csv $Path -notypeinformation
        }
}



Function Get-ADSPath{
    Param(
        [Parameter(Mandatory = $True)]
            [String]$Domain,
        [Parameter(Mandatory = $True)]
            [String]$Name,
        [Parameter(Mandatory = $True)]
            [String]$Type,
        [Parameter(Mandatory = $False)]
            [String]$ADUser,
        [Parameter(Mandatory = $False)]
            [String]$ADPass
    )

    If($ADUser -and $ADPass){
        $Domain = New-Object -TypeName System.DirectoryServices.DirectoryEntry("LDAP://$Domain", $ADUser, $ADPass)
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Credentials supplied for: $ADUser"
    }
    Else{$Domain = New-Object -TypeName System.DirectoryServices.DirectoryEntry("LDAP://$Domain")
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Running as invoked user"
    }

    If($Type -eq "User"){
        $Searcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher($Domain,"(&(objectCategory=User)(sAMAccountname=$Name))")
        $Searcher.SearchScope = "Subtree"
        $Searcher.SizeLimit = '5000'
        $ADOQuery = $Searcher.FindAll()
        $ADSPath = $ADOQuery.Path
        $ADOProperties = $ADOQuery.Properties
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $Name ADSPath: $ADSPath"
        Return $ADOProperties
    }
    ElseIf($Type -eq "Group"){
        $Searcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher($Domain,"(&(objectCategory=Group)(name=$Name))")
        $Searcher.SearchScope = "Subtree"
        $Searcher.SizeLimit = '5000'
        $ADOQuery = $Searcher.FindAll().Path
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $Name ADSPath: $ADOQuery"
        Return [ADSI]$ADOQuery
    }
    ElseIf($Type -eq "Computer"){
        $Searcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher($Domain,"(&(objectCategory=Computer)(name=$Name))")
        $Searcher.SearchScope = "Subtree"
        $Searcher.SizeLimit = '5000'
        $ADOQuery = $Searcher.FindAll().Path
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $Name ADSPath: $ADOQuery"
        Return [ADSI]$ADOQuery
    }
}




Function Set-AdUserPasswordADSI{ 
    Param(
        [Parameter(Mandatory = $True)]
            [String]$Domain,
        [Parameter(Mandatory = $True)]
            [String]$User,
        [Parameter(Mandatory = $False)]
            [String]$NewPassword,
        [Parameter(Mandatory = $False)]
            [String]$ADUser,
        [Parameter(Mandatory = $False)]
            [String]$ADPass
    )

    $oUser = Get-ADOProperty -sDomain $Domain -sName "$User" -sType "User" -sADUser $ADUser -sADPass $ADPass
    $oUserDN = $oUser.distinguishedname
    $oUserFullDN = [ADSI]"LDAP://$oUserDN"
    $oUserFullDN.psbase.invoke("SetPassword",$NewPassword)
    $oUserFullDN.psbase.CommitChanges()

} # end unction Set-AdUserPassword


Function Get-GroupMembershipADSI{
    Param(
        [Parameter(Mandatory = $True)]
            [String]$Domain,
        [Parameter(Mandatory = $True)]
            [String]$Name,
        [Parameter(Mandatory = $True)]
            [String]$Type,
        [Parameter(Mandatory = $False)]
            [String]$ADUser,
        [Parameter(Mandatory = $False)]
            [String]$ADPass
    )

    Write-Log "  $($MyInvocation.MyCommand.Name):: $Name"

    $oADObject = Get-ADSPath -sDomain "ghs.org" -sName $Name -sType $Type -sADUser $ADUser -sADPass $ADPass
    $Groups =  $oADObject.memberof | ForEach-Object {[ADSI]"LDAP://$_"}
    
    Return $Groups
}

Function Get-GroupMembership{
    Param(
        [Parameter(Mandatory=$True)]
        $User
    )

    ForEach ($U in $User){
        $UN = Get-ADUser $U -Properties MemberOf
        $Groups = ForEach ($Group in ($UN.MemberOf)){
            (Get-ADGroup $Group).Name
        }
        $Groups = $Groups | Sort
        ForEach ($Group in $Groups){
            New-Object PSObject -Property @{
                Name = $UN.Name
                Group = $Group
            }
        }
    }
}



<#Function Get-ADSPath{
    Param(
        [Parameter(Mandatory = $True)]
            [String]$Domain,
        [Parameter(Mandatory = $True)]
            [String]$Name,
        [Parameter(Mandatory = $True)]
            [String]$Type,
        [Parameter(Mandatory = $False)]
            [String]$ADUser,
        [Parameter(Mandatory = $False)]
            [String]$ADPass,
        [Parameter(Mandatory = $False)]
            [String]$Properties
    )

    If($Domain -eq $null -or $Name -eq $null -or $Type -eq $null -or $Name -eq $null){
        Write-Log -Message "  Invalid Parameters Passed" -Type 3
        Return}

    [int] $ADS_PROPERTY_APPEND = 3
    $ADS_SECURE_AUTHENTICATION = '&H1'
    $ADS_SERVER_BIND = '&H200'
    [int] $ADS_SCOPE_SUBTREE = 2
    If($ADUser -and $ADPass){
        $DomainIP = (Test-Connection -ComputerName "$Domain" -Count 1).IPV4Address.IPAddressToString
    
        If($ADUser -and $ADPass){
            $Domain = New-Object -TypeName System.DirectoryServices.DirectoryEntry("LDAP://$DomainIP", $ADUser, $ADPass)
        }
        Else{$Domain = New-Object -TypeName System.DirectoryServices.DirectoryEntry("LDAP://$DomainIP")}

        If($Type -eq "User"){
            $Searcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher($Domain,"(&(objectCategory=User)(sAMAccountname=$Name))")
            $Searcher.SearchScope = "Subtree"
            $Searcher.SizeLimit = '5000'
            $ADOQuery = $Searcher.FindAll()
            $ADOProperties = $ADOQuery.Properties
            Return $ADOProperties
        }
        ElseIf($Type -eq "Group"){
            $Searcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher($Domain,"(&(objectCategory=Group)(name=$Name))")
            $Searcher.SearchScope = "Subtree"
            $Searcher.SizeLimit = '5000'
            $ADOQuery = $Searcher.FindAll().Path
            Return [ADSI]$ADOQuery
        }
        ElseIf($Type -eq "Computer"){
            $Searcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher($Domain,"(&(objectCategory=Computer)(name=$Name))")
            $Searcher.SearchScope = "Subtree"
            $Searcher.SizeLimit = '5000'
            $ADOQuery = $Searcher.FindAll().Path
            Return [ADSI]$ADOQuery
        }
    }
    Else{
        #Create ADODB connection
	    $oAD = New-Object -ComObject "ADODB.Connection"
	    $oAD.Provider = "ADsDSOObject"

	    $oAD.Open("Active Directory Provider")

        Write-Log -Message "  Connecting to AD"
	
        If($Type -eq "User"){
            $Query = "SELECT ADsPath,cn,sAMAccountName,manager FROM 'LDAP://$Domain' WHERE objectCategory='$Type' AND  sAMAccountName='$Name'"}
        ElseIf($Type -eq "Computer" -or $Type -eq "Group"){
		    $Query = "SELECT ADsPath,cn,sAMAccountName FROM 'LDAP://$Domain' WHERE objectCategory='$Type' AND  Name='$Name'"}
        Else{Write-Log -Message "  Invalid Object parameter passed. Must be User, Group, CustomUser, or Computer" -Type 3
            Return}

        Try{$oRS = $oAD.Execute($Query)}
        Catch{Write-Log -Message "  Unable to connect to AD" -Type 3
            Return}
        Finally{}

	    If (!$oRs.EOF)
	    {
            $DomainsPath = $oRs.Fields("ADsPath").value
            $CN = $oRs.Fields("cn").value
            Write-Log -Message "  CN: $CN"
            Write-Log -Message "  ADsPath: $DomainsPath"
	    }
        If($DomainsPath -eq $null){
            Write-Log -Message "  Unable to locate $Type : $Name in Active Directory" -Type 3
            Return}

        Return $oRS
    }
}#End Get-ADSPath
#>






<#'-------------------------------------------------------------------------------
  '---    SCCM
  '-------------------------------------------------------------------------------#>

Function Is-InTS{
    Try{
        $Global:oENV = New-Object -COMObject Microsoft.SMS.TSEnvironment
    }
    Catch{
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $False"
        Return $False
    }
    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $True"
    Return $True
}


Function Hide-TSProgress{
    Write-Log -Message "  $($MyInvocation.MyCommand.Name)::"
    Try{
        $TSProgressUI = New-Object -COMObject Microsoft.SMS.TSProgressUI
        $TSProgressUI.CloseProgressDialog()
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Hid TS Progress Window"
    }
    Catch{
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Unable to hide TS Progress Window" -Type 3
    }
 }


 Function Get-TSVar{
    Param(
        [Parameter(Mandatory=$True)]
        [String]$Variable
    )
    Write-Log "  $($MyInvocation.MyCommand.Name)::$Variable"

    Try{
        $TSENV = New-Object -COMObject Microsoft.SMS.TSEnvironment
        $TSVariable = $TSENV.Value($Variable)
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $Variable = $TSVariable"
    }
    Catch{
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Failed to get value of $Variable" -Type 3
    }

    Return $TSVariable
}

Function Set-TSVar{
    Param(
        [Parameter(Mandatory=$True)]
        [String]$Variable,
        [Parameter(Mandatory=$True)]
        [String]$Value
    )
    Write-Log -Message "  $($MyInvocation.MyCommand.Name)::$Variable=$Value"

    Try{
        $oENV = New-Object -COMObject Microsoft.SMS.TSEnvironment
    }
    Catch{}

    Try{
        $oENV.Value($Variable) = $Value
    }
    Catch{
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Failed to Set Variable" -Type 3
        Return
    }
    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Successfully Set Variable"
}

Function Add-ComputerToCollection {
     Param(
        [Parameter(Mandatory=$True)]
        $ComputerName,
        [Parameter(Mandatory=$True)]
        $CollectionID,
        [Parameter(Mandatory=$True)]
        $CollectionName,
        [Parameter(Mandatory=$True)]
        $SMSServer
        )

    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: $ComputerName,$CollectionID,$CollectionName,$SMSServer"
    
	$RulesToSkip = $null
	$strMessage = "Do you want to add '$ComputerName' to '$CollectionName'"
	    
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Connecting to Site Server: $SMSServer"
        Try{
            $sccmProviderLocation = Get-WmiObject -query "select * from SMS_ProviderLocation where ProviderForLocalSite = true" -Namespace "root\sms" -computername $SMSServer
        }
        Catch{
            Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Unable to connect to Site Server: $SMSServer"
            Return
        }
        Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Successfully connected to Site Server: $SMSServer"
        $SiteCode = $sccmProviderLocation.SiteCode
        $Namespace = "root\sms\site_$SiteCode"

        Write-Log -Message "  Query $SMSServer for CollectionID: $CollectionID"
		$strQuery = "Select * from SMS_Collection where CollectionID = '$CollectionID'"
		$Collection = Get-WmiObject -query $strQuery -ComputerName $SMSServer -Namespace $Namespace
		$Collection.Get()

		If($ComputerName -ne $null){
			$strQuery = "Select * from SMS_R_System where Name like '$ComputerName'"
			Get-WmiObject -Query $strQuery -Namespace $Namespace -ComputerName $SMSServer | ForEach-Object {
			    $ResourceID = $_.ResourceID
			    $RuleName = $_.Name
			    $ComputerName = $RuleName
			    If($ResourceID -ne $null){
				    $Error.Clear()
				    $Collection=[WMI]"\\$($SMSServer)\$($Namespace):SMS_Collection.CollectionID='$CollectionID'"
				    $RuleClass = [wmiclass]"\\$($SMSServer)\$($NameSpace):SMS_CollectionRuleDirect"
				    $newRule = $ruleClass.CreateInstance()
				    $newRule.RuleName = $RuleName
				    $newRule.ResourceClassName = "SMS_R_System"
				    $newRule.ResourceID = $ResourceID
				    $Collection.AddMembershipRule($newRule)
				    If ($Error[0]) {
					    Write-Log -Message "Error adding $ComputerName - $Error"
					    $ErrorMessage = "$Error"
					    $ErrorMessage = $ErrorMessage.Replace("`n","")
				    }
				    Else {
					    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Successfully added $ComputerName"
                        Return $True
				    }
			    }
			    Else {
				    Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Could not find $ComputerName - No rule added" -Type 2
			    }
			}#End For-Each
			If($ResourceID -eq $null){
				Write-Log -Message "  $($MyInvocation.MyCommand.Name):: Could not find $ComputerName - No rule added" -Type 2
			}
		}
}

