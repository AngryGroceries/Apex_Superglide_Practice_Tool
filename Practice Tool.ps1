# Authors 
# JayTheYggdrasil @ https://github.com/JayTheYggdrasil
# AngryGroceries  @ https://github.com/AngryGroceries 

$loop = "true"
$currenttime = Get-Date
$secondtime = Get-Date
$presscount = 0
$evenodd = $presscount % 2
$jumpfirst = 0
$removespam = 0

"!! Use CTRL+C to quit !!" 
"-- Setup --"
"Press the key you use for jump."
$jumpkey = $Host.UI.RawUI.ReadKey()
""
"Press the key you use for crouch."
$duckkey = $Host.UI.RawUI.ReadKey()
""

write-host -nonewline "Enter your framerate: "
$inputString = read-host
$targetfps = $inputString -as [Double]

write-host -nonewline "Jump + crouch must be exactly 1 frame apart for the highest chance at superglide success."

$frametime = 1 / $targetfps

" "
"--------------------------------------------------"



while ($loop -eq "true") {

   if ($evenodd -eq 0) {
      if ($removespam -eq 0){
	      "Press Jump..."
      }

      $key = $Host.UI.RawUI.ReadKey()
      
      if($key -eq $jumpkey) {
         $currenttime = Get-Date

         " (Jump) Key Pressed"
         $presscount = $presscount + 1
         $evenodd = $presscount % 2
         $jumpfirst = 1
      }  
         elseif ($key -eq $duckkey) {
             $currenttime = Get-Date

            " (Crouch) Key Pressed"
            $presscount = $presscount + 1
            $evenodd = $presscount % 2
      }  
         else {
	         " Pressed. Did not hit the (Jump) key."
	         $removespam = 1
         }
   }

   if ($evenodd -eq 1) {
      $removespam = 0
      "Press Crouch..."
      $key = $Host.UI.RawUI.ReadKey()

      if($key -eq $duckkey -And $jumpfirst -eq 1) {
         " (Crouch) Key Pressed"

         $secondtime = Get-Date
         $calculated = $secondtime - $currenttime
         $elapsedFrames = $calculated.TotalSeconds / $frametime
         $differenceSeconds = $frametime - $calculated.TotalSeconds

         if($elapsedFrames -lt 1) {
            $chance = $elapsedFrames * 100
            $message = "Crouch slightly *later* by {0:n5} seconds" -f $differenceSeconds + " to improve."
         }  
            elseif ($elapsedFrames -lt 2) {
            $chance = ( (2 - $elapsedFrames) ) * 100
            $message = "Crouch slightly *sooner* by {0:n5} seconds" -f ($differenceSeconds * -1) + " to improve."
            } 
            else {
            $message = "Crouched too late by {0:n5} seconds" -f ($differenceSeconds * -1)
            $chance = 0
            }

         ("{0:n3} frames have passed." -f $elapsedFrames.ToString()) | Write-Host
         
         ("{0:n4} % chance to hit." -f $chance.ToString()) | Write-Host

         $message | Write-Host

         $presscount = $presscount + 1
         $evenodd = $presscount % 2
         "--------------------------------------------------"
      }  
         else {
		      $secondtime = Get-Date
         	$calculated = $secondtime - $currenttime
         	$elapsedFrames = $calculated.TotalSeconds / $frametime
	 	      $differenceSeconds = $frametime + $calculated.TotalSeconds
		      $chance = 0
		      $message = "Oops! Wrong key order by {0:n5} seconds or {1:n3} frames. " -f $calculated.TotalSeconds, $elapsedFrames

		
		      if($key -eq $jumpkey -And $jumpfirst -eq 1){
			      " (Jump) Key double-tapped."
				}
		         elseif($key -eq $duckkey) {
			      " (Crouch) Key double-tapped."
				} 	
		         elseif($key -eq $jumpkey) {
			      " (Jump) Key Pressed."
				} 		
		         else{
			      " Key Pressed." | Write-Host
		      }		
		 
	         ( "{0:n4} % chance to hit." -f $chance.ToString() ) | Write-Host
	         $message | Write-Host

            $presscount = $presscount + 1
            $evenodd = $presscount % 2
	         "--------------------------------------------------"


         }
   }
   $jumpfirst = 0
	Start-Sleep -Milliseconds 125
	$HOST.UI.RawUI.Flushinputbuffer()
}
