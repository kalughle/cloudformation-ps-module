$a = Get-CFNStackEvent -StackName "cf-usw2-test01-vpc01"
Start-Sleep -Seconds 5
$b = Get-CFNStackEvent -StackName "cf-usw2-test01-vpc01"
Start-Sleep -Seconds 10
$c = Get-CFNStackEvent -StackName "cf-usw2-test01-vpc01"
Start-Sleep -Seconds 20
$d = Get-CFNStackEvent -StackName "cf-usw2-test01-vpc01"
Start-Sleep -Seconds 30
$e = Get-CFNStackEvent -StackName "cf-usw2-test01-vpc01"