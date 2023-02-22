# Authors 
# JayTheYggdrasil @ https://github.com/JayTheYggdrasil
# AngryGroceries  @ https://github.com/AngryGroceries 


$loop = "true"
$currenttime = Get-Date
$secondtime = Get-Date
$presscount = 0
$evenodd = $presscount % 2

"!! Use CTRL+C to quit !!" 
"-- Setup --"
"Press the key you use for jump."
$jumpkey = $Host.UI.RawUI.ReadKey()
""
"Press the key you use for crouch."
$duckkey = $Host.UI.RawUI.ReadKey()
""

write-host -nonewline "Enter your framrate: "
  $inputString = read-host
  $targetfps = $inputString -as [Double]

write-host -nonewline "Jump + crouch must be exactly 1 frame apart for the highest chance at superglide success."

$frametime = 1 / $targetfps

" "
"--------------------------------------------------"



while ($loop -eq "true") {

   if ($evenodd -eq 0) {
      "Press Jump..."
      $key = $Host.UI.RawUI.ReadKey()
      
      if($key -eq $jumpkey) {
         $currenttime = Get-Date

         " (Jump) Key Pressed"
         $presscount = $presscount + 1
         $evenodd = $presscount % 2
      } else {
         " that's not jump..."
      }
   }

   if ($evenodd -eq 1) {
      "Press Crouch..."
      $key = $Host.UI.RawUI.ReadKey()

      if($key -eq $duckkey) {
         " (Crouch) Key Pressed"

         $secondtime = Get-Date
         $calculated = $secondtime - $currenttime
         $elapsedFrames = $calculated.TotalSeconds / $frametime
	      $differenceSeconds = $frametime - $calculated.TotalSeconds

         if($elapsedFrames -lt 1) {
            $chance = $elapsedFrames * 100
            $message = "Crouch slightly *later* by {0:n5} seconds" -f $differenceSeconds + " to improve."
         } elseif ($elapsedFrames -lt 2) {
            $chance = ( (2 - $elapsedFrames) ) * 100
            $message = "Crouch slightly *sooner* by {0:n5} seconds" -f ($differenceSeconds * -1) + " to improve."
         } else {
            $message = "Crouched too late by " + ($elapsedFrames - 1).ToString("###") + " frames."
            $chance = 0
         }

	      ("{0:n3} frames have passed." -f $elapsedFrames.ToString()) | Write-Host
	 
         ( "{0:n4} % chance to hit." -f $chance.ToString() ) | Write-Host

         $message | Write-Host

         $presscount = $presscount + 1
         $evenodd = $presscount % 2
         "--------------------------------------------------"
      } else {
         " that's not crouch..."
      }
   }
}
