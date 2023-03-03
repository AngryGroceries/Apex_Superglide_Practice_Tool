# Authors 
# JayTheYggdrasil @ https://github.com/JayTheYggdrasil
# AngryGroceries  @ https://github.com/AngryGroceries 

$loop = "true"
$startTime = Get-Date
$secondtime = Get-Date

enum states {
   Ready,      # Initial State
   Jump,       # Partial Sequence
   JumpWarned, # Multi-Jump Warning Sent
   Crouch,     # Incorrect Sequence, let it play out for a bit
}

$state = [states]::Ready

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

$frameTime = 1 / $targetfps

" "
"--------------------------------------------------"

# Send Initial Status
$attempt = 0
$cumlative = 0
$chance = 0
"###### Attempt 0 - Average: NA ######"
"Awaiting Jump..."

Function ReadyUp() {
   $attempt = $attempt + 1
   $cumlative = $cumlative + $chance

   $average = $cumlative - $attempt
   "###### Attempt {0:n4} - Average: {0:n2} ######" -f $attempt, $average
   Write-Host -ForegroundColor Gray "Awaiting Jump..."
   $state = [states]::Ready
}

while ($loop -eq "true") {
      # Get keys

      if($state -eq [states]::Jump) {
         Write-Host -ForegroundColor Gray "Awaiting Crouch..."
      }

      $key = $Host.UI.RawUI.ReadKey()

      if ($key -eq $duckkey) {
         if($state -eq [states]::Ready) {
            # Crouched First.
            Write-Host -ForegroundColor Yellow " Key Pressed (Crouch)"
            $startTime = Get-Date
            $state = [states]::Crouch
         } elseif(($state -eq [states]::Jump) -or ($state -eq [states]::JumpWarned)) {
            # Happy Path
            Write-Host -ForegroundColor Green " Key Pressed (Crouch)"
            
            $calculated = Get-Date - $startTime
            $elapsedFrames = $calculated.TotalSeconds / $frameTime
            $differenceSeconds = $frameTime - $calculated.TotalSeconds

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

            ("{0:n1} frames have passed." -f $elapsedFrames.ToString()) | Write-Host
            
            ("{0:n1} % chance to hit." -f $chance.ToString()) | Write-Host
            
            
            if($chance -gt 0) {
               $message | Write-Host -ForegroundColor Green
            } else {
               $message | Write-Host -ForegroundColor Yellow
            }

            ReadyUp
         } elseif ($state -eq [states]::Crouch) {
            # Double Crouch
            Write-Host -ForegroundColor Yellow " Key Pressed (Crouch)"
            Write-Host -ForegroundColor Red " Double Crouch Input, Resetting"
            $attempt = $attempt - 1
            $chance = 0
            ReadyUp
         }
      } elseif($key -eq $jumpkey) {
         if($state -eq [states]::Ready) {
            # Happy Path
            Write-Host -ForegroundColor Green " Key Pressed (Jump)"
            $startTime = Get-Date
            $state = [states]::Jump
         } elseif($state -eq [states]::Jump) {
            # Multi Jump Input.
            Write-Host -ForegroundColor Gray " Key Pressed (Jump) - Ignored"
            $state = [states]::JumpWarned
            Write-Host -ForegroundColor Yellow "Warning: Multiple jumps detected, results may not reflect ingame behavior."
         } elseif ($state -eq [states]::JumpWarned) {
            # Multi Jump input, already warned.
            Write-Host -ForegroundColor Gray " Key Pressed (Jump) - Ignored"
            $state = [states]::JumpWarned
         } elseif ($state -eq [states]::Crouch) {
            Write-Host -ForegroundColor Yellow "0% chance to hit, jump must come 1 frame before crouch."
            # Difference in time between inputs + 1 frameTime for the offset.
            $delta = (Get-Date - $startTime).TotalSeconds + $frameTime
            $earlyBy = $delta.TotalSeconds / $frameTime

            $chance = 0

            "Press crouch later by {0:n2} frames ({0:n2}s)" - f $earlyBy, delta
            ReadyUp
         }
      } else {
         Write-Host -ForegroundColor Gray " Key Pressed (and Ignored)"
      }
   }

   
	# Start-Sleep -Milliseconds 125
	# $HOST.UI.RawUI.Flushinputbuffer()
}
