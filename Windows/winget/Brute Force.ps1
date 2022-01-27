$validChars = ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','1','2','3','4','5','6','7','8','9','0')
foreach($a in $validChars){
    foreach($b in $validChars){
        foreach($c in $validChars){
            foreach($d in $validChars){
                foreach($e in $validChars){
                    foreach($f in $validChars){
                        foreach($g in $validChars){
                            foreach($h in $validChars){
                                foreach($i in $validChars){
                                    foreach($j in $validChars){
                                        foreach($k in $validChars){
                                            foreach($l in $validChars){
                                                foreach($m in $validChars){
                                                    foreach($n in $validChars){
                                                        $searchTerm = $a+$b+$c+$d+$e+$f+$g+$h+$i+$j+$k+$l+$m+$n
                                                        Write-Host $searchTerm
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}