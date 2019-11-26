<#
Used Sources:
https://www.tarlogic.com/en/blog/how-to-create-keylogger-in-powershell
#>

<#
Version 1.1:
    Replaced Screenshot function with pure .Net in Powershell.
    Added an option to draw a circle around the mouse location.

TODO:
    
#>
param(
    [string]$ScreenshotsPath = "C:\Tools\PoshScreenRecorder\$([datetime]::Now.ToShortDateString().Replace('/','.')).$([datetime]::Now.ToLongTimeString().Replace(':','_'))",
    [string]$ScreenshotsPrefix = 'PoshSR-',
    [array]$KeysToCapture = (13, 32, 1, 27, 19),
    [int]$SleepTimeout = 1,
    [bool]$MarkMousePositionOnClick = $true
)

function Get-ScreenShot {
    param (
        [Drawing.Rectangle]$Bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds,
        [bool]$MarkMousePositionOnClick,
        [string]$Path
    )



    $BMP = New-Object Drawing.Bitmap $Bounds.Width, $Bounds.Height
    $Graphics = [Drawing.Graphics]::FromImage($BMP)

    $Graphics.CopyFromScreen($Bounds.Location, [Drawing.Point]::Empty, $Bounds.Size)
    If ($MarkMousePositionOnClick) {
        $Graphics.DrawEllipse([System.Drawing.Pen]::new([System.Drawing.Color]::LightGreen,4), [System.Windows.Forms.Cursor]::Position.X - 10, [System.Windows.Forms.Cursor]::Position.Y - 10, 20, 20)
    }

    $BMP.Save($Path,[System.Drawing.Imaging.ImageFormat]::Png)

    $Graphics.Dispose()
    $BMP.Dispose()
}

[Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[Reflection.Assembly]::LoadWithPartialName("System.Drawing")

$Signature = @"
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)]
public static extern short GetAsyncKeyState(int virtualKeyCode);
"@
$GetKeyState = Add-Type -MemberDefinition $Signature -Name "Newtype" -Namespace newnamespace -PassThru
$Check = 0
$ScreenshotCounter = 0

Write-Host $ScreenshotsPath

If (!(Test-Path $ScreenshotsPath)) {
    New-Item -Path (Split-Path -Path $ScreenshotsPath -Parent) -Name (Split-Path -Path $ScreenshotsPath -Leaf) -ItemType Directory
}

While ($true) {
    Start-Sleep -Milliseconds $SleepTimeout
    $Logged = ''  
    #13 = Enter, 32 = Space, 1 = Left Mouse, 27 = Escape, 19 = Pause
    ForEach ($Key In $KeysToCapture) {
        $Logged = $GetKeyState::GetAsyncKeyState($Key)
        If ($Logged -eq -32767) {
            If ($Key -eq 19) { #Pause has been pressed
                Write-Host 'Pausing screen recording'
                Read-Host -Prompt 'Press enter to continue'
            } Else {
                $ScreenshotCounter = $ScreenshotCounter + 1
                If ($Key -eq 1) {
                    #Draw a circle only when clicking the mouse
                    Get-ScreenShot -MarkMousePositionOnClick $MarkMousePositionOnClick -Path "$ScreenshotsPath\$ScreenshotsPrefix$ScreenshotCounter.png" | Out-Null
                } Else {
                    Get-ScreenShot -MarkMousePositionOnClick $MarkMousePositionOnClick -Path "$ScreenshotsPath\$ScreenshotsPrefix$ScreenshotCounter.png" | Out-Null
                }
            }
        }
    }
}
