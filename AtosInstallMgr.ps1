<#
' // ***************************************************************************
' // 
' // FileName:  InstallMgr.ps1
' //            
' // Version:   1.00
' //            
' // Usage:     powershell.exe -executionpolicy bypass -file AtosInstallMgr.ps1
' //          
' //
' //            
' // Created:   2018.04.09
' //            Brandon Hilgeman
' //            brandon.hilgeman@gmail.com
' // ***************************************************************************
#>


<#-------------------------------------------------------------------------------
'---    Initialize Objects
'-------------------------------------------------------------------------------#>

$Global:sArgs = $args[0]
$Global:ScriptName = $MyInvocation.MyCommand.Name

<#-------------------------------------------------------------------------------
'---    Configure
'-------------------------------------------------------------------------------#>

$Publisher = ""
$ProductName = ""
$ProductVersion = ""
$ProductSearch = ""

<#-------------------------------------------------------------------------------
'---    Install
'-------------------------------------------------------------------------------#>


Function Start-Install {

    Get-XAML -Path "$PSScriptRoot\AtosInstallMgr\MainWindow.xaml" -bvariables $True
       
}


<#-------------------------------------------------------------------------------
'---    UnInstall
'-------------------------------------------------------------------------------#>

Function Start-Uninstall{

    Run-Uninstall -Name $ProductSearch -Version $ProductVersion
}

<#-------------------------------------------------------------------------------
'---    Functions
'-------------------------------------------------------------------------------#>

Function Start-WPFApp{
    
    $XMLPath = "$PSScriptRoot\Test.xml"
   
    $Global:SettingsFile = Get-IniContent "$PSScriptRoot\Config.ini"

    $WPFtextbox_Text.text = $SettingsFile["Settings"]["InputLabel"]
    
    $DS = New-Object System.Data.Dataset
    $DS.ReadXml($XMLPath) | Out-Null
    $Global:DataTable = $DS.Tables[0].DefaultView
    $WPFDataGrid.ItemsSource = $DataTable
    
    $WPFdataGrid.Columns[0].Header = $SettingsFile["Columns"]["Column0Header"]
    $WPFdataGrid.Columns[1].Header = $SettingsFile["Columns"]["Column1Header"]
    $WPFdataGrid.Columns[2].Header = $SettingsFile["Columns"]["Column2Header"]
    $WPFdataGrid.Columns[3].Header = $SettingsFile["Columns"]["Column3Header"]
    $WPFdataGrid.Columns[4].Header = $SettingsFile["Columns"]["Column4Header"]
    $WPFdataGrid.Columns[5].Header = $SettingsFile["Columns"]["Column5Header"]
    $WPFdataGrid.Columns[6].Header = $SettingsFile["Columns"]["Column6Header"]
    $WPFdataGrid.Columns[7].Header = $SettingsFile["Columns"]["Column7Header"]
    $WPFdataGrid.Columns[8].Header = $SettingsFile["Columns"]["Column8Header"]
    $WPFdataGrid.Columns[9].Header = $SettingsFile["Columns"]["Column9Header"]
    $WPFdataGrid.Columns[10].Header = $SettingsFile["Columns"]["Column10Header"]
    $WPFdataGrid.Columns[11].Header = $SettingsFile["Columns"]["Column11Header"]

    $WPFdataGrid.Columns[0].Visibility = $SettingsFile["Columns"]["Column0Visibility"]
    $WPFdataGrid.Columns[1].Visibility = $SettingsFile["Columns"]["Column1Visibility"]
    $WPFdataGrid.Columns[2].Visibility = $SettingsFile["Columns"]["Column2Visibility"]
    $WPFdataGrid.Columns[3].Visibility = $SettingsFile["Columns"]["Column3Visibility"]
    $WPFdataGrid.Columns[4].Visibility = $SettingsFile["Columns"]["Column4Visibility"]
    $WPFdataGrid.Columns[5].Visibility = $SettingsFile["Columns"]["Column5Visibility"]
    $WPFdataGrid.Columns[6].Visibility = $SettingsFile["Columns"]["Column6Visibility"]
    $WPFdataGrid.Columns[7].Visibility = $SettingsFile["Columns"]["Column7Visibility"]
    $WPFdataGrid.Columns[8].Visibility = $SettingsFile["Columns"]["Column8Visibility"]
    $WPFdataGrid.Columns[9].Visibility = $SettingsFile["Columns"]["Column9Visibility"]
    $WPFdataGrid.Columns[10].Visibility = $SettingsFile["Columns"]["Column10Visibility"]
    $WPFdataGrid.Columns[11].Visibility = $SettingsFile["Columns"]["Column11Visibility"]

    $WPFtextbox_SearchText.Add_TextChanged({
        If($WPFtextbox_SearchText.text){
            $InputText = $WPFtextbox_SearchText.text
            $NewDataTable = $DataTable
            $NewDataTable.Rowfilter = "name = $InputText"
            $WPFDataGrid.ItemsSource = $DataTable.ToTable()
        }
        Else{
            Start-WPFApp
        }
    })

    $WPFbutton_Install.Add_Click({
        If($WPFDataGrid.SelectedItem.Row.ItemArray.Count -lt 1){
            MsgBox -Message "Select an application from the list"
            Return $Null
        }
        $ApplicationName = $WPFDataGrid.SelectedItem.Row.ItemArray[1]
        $InstallConfirm = MsgBox -Message "Are you sure you want to install $ApplicationName ?" -Buttons 4
        If($InstallConfirm -eq "Yes"){
            MsgBox -Message $WPFDataGrid.SelectedItem.Row.ItemArray[6]
        }
        Else{
            Return
        }        
        #Write-Host $WPFDataGrid.Items.IndexOf($WPFDataGrid.SelectedItem)
    })

    $WPFbutton_Uninstall.Add_Click({
        If($WPFDataGrid.SelectedItem.Row.ItemArray.Count -lt 1){
            MsgBox -Message "Select an application from the list"
            Return $Null
        }
        $ApplicationName = $WPFDataGrid.SelectedItem.Row.ItemArray[1]
        $InstallConfirm = MsgBox -Message "Are you sure you want to install $ApplicationName ?" -Buttons 4
        If($InstallConfirm -eq "Yes"){
            MsgBox -Message $WPFDataGrid.SelectedItem.Row.ItemArray[7]
        }
        Else{
            Return
        } 
    })
    $WPFbutton_Documentation.Add_Click({
        If($WPFDataGrid.SelectedItem.Row.ItemArray.Count -lt 1){
            MsgBox -Message "Select an application from the list"
            Return $Null
        }
        #MsgBox -Message $WPFDataGrid.SelectedItem.Row.ItemArray[8]
        Start-Process "Explorer.exe" -ArgumentList $WPFDataGrid.SelectedItem.Row.ItemArray[8]
    })

    

    
}


<#-------------------------------------------------------------------------------
'---    Start
'-------------------------------------------------------------------------------#>

Import-Module -WarningAction SilentlyContinue "$PSScriptRoot\ScriptLibrary1.18.psm1"
Set-GlobalVariables
Start-Log
Write-Log "  Runtime: $Runtime" -Type 1
Set-Mode
$WPFimage_logo.Source = "$PSScriptRoot\Images\Logo.bmp"
$Form.Icon = "$PSScriptRoot\Images\Atoslogo_rgb.ico"
$Null = $Form.ShowDialog() #Uncomment for WPF Apps
End-Log


<#-------------------------------------------------------------------------------
'---    Function Templates
'-------------------------------------------------------------------------------#>

#IsSoftwareInstalled -Product "Microsoft*" -Version "*"

#Get-ComputerName

#MsgBox -Message "" -Title "" -Buttons ""

#Test-Ping -Hostname ""

#Run-Install -CMD """$PSScriptRoot\Source\Example.exe""" -Arg "/silent /noreboot"

#Run-Install -CMD """$PSScriptRoot\Source\Example.msi""" -Arg "/qn /norestart"

#Copy-File -Source "$PSSCriptRoot\Install\Example.txt" -Destination "C:\Users\Public\Desktop\Example.txt"

#Copy-Folder -Source "$PSSCriptRoot\Install\Example\" -Destination "C:\Users\Public\Desktop\Example\"

#Delete-Object -Path "C:\Users\Public\Desktop\Example.url"

#Delete-Object -Path "C:\Users\Public\Desktop\Example"

#AD_ManageGroupADSI -Domain "contoso.org" -Function "Add" -Type "User" -Name "czt20b" -Group "GROUP_1" -ADUser "contoso\abc123a" -ADPass "P@ssw0rd"

#Get-XAML -Path "$PSScriptRoot\Example\MainWindow.xaml"
