function Convert-NetworkAddressToLong () {  
    param ($ip)  
    
    $octets = $ip.split(".")  
    return [int64]([int64]$octets[0] * 16777216 + [int64]$octets[1] * 65536 + [int64]$octets[2] * 256 + [int64]$octets[3])  
}  


function Convert-LongToNetworkAddress() {  
    param ([int64]$int)  

    return (([math]::truncate($int / 16777216)).tostring() + "." + ([math]::truncate(($int % 16777216) / 65536)).tostring() + "." + ([math]::truncate(($int % 65536) / 256)).tostring() + "." + ([math]::truncate($int % 256)).tostring() ) 
}