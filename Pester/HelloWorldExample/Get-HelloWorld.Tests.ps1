$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Get-HelloWorld" {
    It "outputs 'Hello world!'" {
        Get-HelloWorld | Should Be 'Hello world!'
    }
}

Describe "Get Dir1" {
    $result = Test-Path -Path C:\Temp\Dir1
    It "outputs 'Dir1 Works'" {
        $result | Should be $true
    }
}

Describe "Get Dir2" {
    $result = Test-Path -Path C:\Temp\Dir2
    It "outputs 'Dir2 Works'" {
        $result | Should be $true
    }
}

Describe "Get Dir3" {
    $result = Test-Path -Path C:\Temp\Dir3
    It "outputs 'Dir3 Works'" {
        $result | Should be $true
    }
}

Describe "Get Dir4" {
    $result = Test-Path -Path C:\Temp\Dir4
    It "outputs 'Dir4 Works'" {
        $result | Should be $true
    }
}

Describe "Get Dir5" {
    $result = Test-Path -Path C:\Temp\Dir5
    It "outputs 'Dir5 Works'" {
        $result | Should be $true
    }
}