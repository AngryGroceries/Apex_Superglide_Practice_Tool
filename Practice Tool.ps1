# Authors 
# JayTheYggdrasil @ https://github.com/JayTheYggdrasil
# AngryGroceries  @ https://github.com/AngryGroceries 

$loop = "true"
$startTime = Get-Date
$secondtime = Get-Date
$resetkey = "r"
$summarykey = "t"
#$optionskey = "o"

#Stats 
$FailCount = 0
$SuccessCount = 0
$WrongOrderCount = 0
$WrongButtonCount = 0
$PercentileBracketArray = @(25,50,75,100)
$PercentileCountArray = Foreach($element in $PercentileBracketArray){
   0
}
$PercentileEarlyCount = Foreach($element in $PercentileBracketArray){
   0
}
$PercentileLateCount = Foreach($element in $PercentileBracketArray){
   0
}

$chanceSide = 0

#Percentile_array_iterator
$j = 0

enum states {
   Ready      # Initial State
   Jump       # Partial Sequence
   JumpWarned # Multi-Jump Warning Sent
   Crouch     # Incorrect Sequence, let it play out for a bit
}

$state = [states]::Ready
$lastState = [states]::Jump

"!! Use CTRL+C to quit !!" 
"!!  !!" 
"!! Use T to show a summary screen !!" 
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



("Use 'r' for a quick reset") | Write-Host -ForegroundColor Yellow
("Use 't' to show a summary screen") | Write-Host -ForegroundColor Yellow
#("Use 'o' to access the options screen") | Write-Host -ForegroundColor Yellow

#Doesnt really matter to add this, but removes the order dependancy of the below logic if these keys are double-bound
if($jumpkey.Character -eq $resetkey -Or $duckkey.Character -eq $resetkey) {
   $resetkey = ""
}
if($jumpkey.Character -eq $summarykey -Or $duckkey.Character -eq $summarykey) {
   $summarykey = ""
}
#if($jumpkey.Character -eq $optionskey -Or $duckkey.Character -eq $optionskey) {
#   $optionskey = ""
#}


write-host -nonewline "Jump + crouch must be exactly 1 frame apart for the highest chance at superglide success."



$frameTime = 1 / $targetfps

" "
"--------------------------------------------------"

# Send Initial Status
$attempt = 0
$cumlative = 0
$chance = 0

while ($loop -eq "true") {
   
   # Status Update(s) - only on state change
   if(!($lastState -eq $state)) {
      if($state -eq [states]::Jump) {
         Write-Host -ForegroundColor DarkGray "Awaiting Crouch..."
      }

      if($state -eq [states]::Ready) {

         #Add to failcount if chance = 0

         #Loop to the proper percentile
         While($chance -gt $PercentileBracketArray[$j]){
                  $j = $j + 1 
            }
         #Add the count in corresponding percentile count array.

         If ($chance -eq 0){
            $Failcount = $FailCount + 1
            } else {
               $SuccessCount = $SuccessCount + 1
               $PercentileCountArray[$j] = $PercentileCountArray[$j] + 1
               If ($chanceSide -eq 1){
                  $PercentileEarlyCount[$j] = $PercentileEarlyCount[$j] + 1
               } elseIf ($chanceSide -eq 2){
                  $PercentileLateCount[$j] = $PercentileLateCount[$j] + 1
               }
            }

         #reset the loop after the calculation
         $j = 0

         $chanceSide = 1
         $cumlative = $cumlative + $chance

         if (!($attempt -eq 0)) {
            " "
            "--------------------------------------------------"
            $average = $cumlative / $attempt
            "###### Attempt {0:n0} - Average: {1:n2}% ######" -f $attempt, $average
            Write-Host -ForegroundColor DarkGray "Awaiting Jump..."
         } else {
            "###### Attempt 0 - Average: NA ######"
            Write-Host -ForegroundColor DarkGray "Awaiting Jump..."
         }

         $attempt = $attempt + 1      
      }
   }
   
   $lastState = $state
   $chanceSide = 0

   # Get input
   $key = $Host.UI.RawUI.ReadKey()

   # State Transitions
   if ($key -eq $duckkey) {
      if($state -eq [states]::Ready) {
         # Crouched First
         Write-Host -ForegroundColor Yellow " Key Pressed (Crouch)"
         $startTime = Get-Date
         $state = [states]::Crouch
      } elseif(($state -eq [states]::Jump) -or ($state -eq [states]::JumpWarned)) {
         # Happy Path
         Write-Host -ForegroundColor Green " Key Pressed (Crouch)"
         
         $now = Get-Date
         $calculated = $now - $startTime
         $elapsedFrames = $calculated.TotalSeconds / $frameTime
         $differenceSeconds = $frameTime - $calculated.TotalSeconds

         if($elapsedFrames -lt 1) {
            $chance = $elapsedFrames * 100
            $chanceSide = 1
            $message = "Crouch slightly *later* by {0:n5} seconds" -f $differenceSeconds + " to improve."
         }  
         elseif ($elapsedFrames -lt 2) {
            $chance = ( (2 - $elapsedFrames) ) * 100
            $chanceSide = 2
            $message = "Crouch slightly *sooner* by {0:n5} seconds" -f ($differenceSeconds * -1) + " to improve."
         } 
         else {
            $message = "Crouched too late by {0:n5} seconds" -f ($differenceSeconds * -1)
            $chance = 0
         }

         ("{0:n1} frames have passed." -f $elapsedFrames.ToString()) | Write-Host
         
         
         
         
         if($chance -gt 0) {
            ("{0:n1}% chance to hit." -f $chance.ToString()) | Write-Host -ForegroundColor Green
         } else {
            "0% chance to hit." | Write-Host -ForegroundColor Red
         }

         $message | Write-Host -ForegroundColor Yellow

         $state = [states]::Ready
      } elseif ($state -eq [states]::Crouch) {
         # Double Crouch
         Write-Host -ForegroundColor Yellow " Key Pressed (Crouch)"
         Write-Host -ForegroundColor Red " Double Crouch Input, Resetting"
         $attempt = $attempt - 1
         $chance = 0
         $WrongButtonCount = $WrongButtonCount + 1
         $state = [states]::Ready
      }
   } elseif($key -eq $jumpkey) {
      if($state -eq [states]::Ready) {
         # Happy Path
         Write-Host -ForegroundColor Green " Key Pressed (Jump)"
         $startTime = Get-Date
         $state = [states]::Jump
      } elseif($state -eq [states]::Jump) {
         # Multi Jump Input.
         Write-Host -ForegroundColor DarkGray " Key Pressed (Jump) - Ignored"
         $state = [states]::JumpWarned
         Write-Host -ForegroundColor Yellow "Warning: Multiple jumps detected, results may not reflect ingame behavior."
      } elseif ($state -eq [states]::JumpWarned) {
         # Multi Jump input, already warned.
         Write-Host -ForegroundColor DarkGray " Key Pressed (Jump) - Ignored"
         $state = [states]::JumpWarned
      } elseif ($state -eq [states]::Crouch) {
         Write-Host -ForegroundColor Yellow " Key Pressed (Jump)"
         Write-Host -ForegroundColor Red "0% chance to hit"
         Write-Host -ForegroundColor Red "- You must jump before you crouch"

         
         # Difference in time between inputs + 1 frameTime for the offset.
         $now = Get-Date
         $delta = ($now - $starTtime).TotalSeconds + $frameTime
         $earlyBy = $delta / $frameTime

         $chance = 0
         $WrongOrderCount = $WrongOrderCount + 1

         ("Press crouch later by {0:n2} frames ({1:n5}s)" -f $earlyBy, $delta) | Write-Host -ForegroundColor Yellow
         $state = [states]::Ready
      }
   } elseif($key.Character -eq $resetkey){
      $state = [states]::Ready
      $lastState = [states]::Jump
      write-host -nonewline " Resetting..." -ForegroundColor Yellow


   } elseif($key.Character -eq $summarykey){
      $state = [states]::Ready
      $lastState = [states]::Jump
      $PercentileBracketArraylower = Foreach($element in $PercentileBracketArray){
         ($element - $PercentileBracketArray[0])
      }

      $PercentileStringArray = Foreach($element in $PercentileBracketArraylower){
         $element.ToString() + "%"
      }
      $PercentileStringArray += "100%"
      ""
      
      "--------------------------------------------------"
      write-host "Summary Screen" -ForegroundColor Yellow
      $attempt = $attempt - 1
      #iterator 
      ""
      "Count by Percentile"
      for ($i = 0; $i -le ($PercentileStringArray.length - 2); $i += 1) {
         Write-Host -nonewline -ForegroundColor DarkGray "("
         ($PercentileStringArray[$i] + "-" + $PercentileStringArray[$i + 1]) | Write-Host -nonewline -ForegroundColor DarkGray
         Write-Host -nonewline -ForegroundColor DarkGray "): "
         "Total : " + $PercentileCountArray[$i] + " | " | Write-Host -nonewline
         "Too Early : " + $PercentileEarlyCount[$i] + " | " | Write-Host -nonewline -ForegroundColor Yellow
         "Too Late : " + $PercentileLateCount[$i] + " | " | Write-Host -nonewline -ForegroundColor Cyan
         ""
       }

      ""
      "Stats"
      Write-Host -nonewline -ForegroundColor DarkGray "Average:------- "
      "{0:n2}%" -f $average
      Write-Host -nonewline -ForegroundColor DarkGray "Attempts:------ "
      Write-Host $attempt
      Write-Host -nonewline -ForegroundColor DarkGray "Missed:-------- " 
      Write-Host -ForegroundColor Red $FailCount
      Write-Host -nonewline -ForegroundColor DarkGray "In Range:------ " 
      Write-Host -ForegroundColor Green $SuccessCount

      #Write-Host -nonewline -ForegroundColor DarkGray "Wrong Order:--- " 
      #Write-Host -ForegroundColor DarkGray $WrongOrderCount
      #Write-Host -nonewline -ForegroundColor DarkGray "Wrong Button:-- " 
      #Write-Host -ForegroundColor DarkGray $WrongButtonCount

   }
   
   else {
      Write-Host -ForegroundColor DarkGray " Key Pressed (and Ignored)"
      $WrongButtonCount = $WrongButtonCount + 1
   }

}
