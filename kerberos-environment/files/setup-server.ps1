<script>
sc query adws
net start adws
</script>

<powershell>
$privateIP=((ipconfig | findstr [0-9].\.)[0]).Split()[-1]
$subnet=((ipconfig | findstr [0-9].\.)[1]).Split()[-1]
$gw=((ipconfig | findstr [0-9].\.)[2]).Split()[-1]
$dns=(netsh interface ip show dnsservers | findstr [0-9].\.).Split()[-1]

Get-ADDomain -Current LocalComputer

# this user is already created and exist here
# we only need to add it to Domain Admins so we can remotely loggin with it
net group "Domain Admins" ${SERVER_ADMIN_USERNAME}  /add

Write-Host "Sucessfully added ${SERVER_ADMIN_USERNAME} to Domain Admins"

$domain = "${DOMAIN}.${HOSTED_ZONE}"
$domain_array = $domain.split('.')
$domain_path = "cn=Users"

#Set domain path on which users are created E.g "cn=Users,dc=alfresco,dc=com"
foreach ($domcomp in $domain_array) {
   $domain_path = "$domain_path,dc=$domcomp"
}

Write-Host "Preparing $domain_path users..."

try {
   Get-ADDomain -Current LocalComputer
   Write-Output "AD running"
 }
 catch {
   Write-Output "AD not running, sleeping for 60 seconds.."
   start-sleep -Seconds 60
 }

# somethimes this starts slow
 try {
   Get-ADDomain -Current LocalComputer
   Write-Output "AD running"
 }
 catch {
   Write-Output "AD not running, sleeping for 60 seconds.."
   start-sleep -Seconds 60
 }

start-sleep -Seconds 300

#Create kerberos authentication user used for creating keytabs
Write-Host "Creating KERBEROS_ADMIN_USERNAME: [${KERBEROS_ADMIN_USERNAME}] in domain: [$domain_path]"
$kerbauth_pwd_secure = ConvertTo-SecureString ${KERBEROS_ADMIN_PASSWORD} -AsPlainText -Force

New-ADUser -Server $privateIP -Name "${KERBEROS_ADMIN_USERNAME}" -DisplayName "Kerberos Auth" -GivenName Kerberos -Surname Auth -TrustedForDelegation 1 -Path "$domain_path" -ChangePasswordAtLogon 0 -AccountPassword $kerbauth_pwd_secure -PasswordNeverExpires 1 -Enabled 1

Set-ADAccountControl -Identity "${KERBEROS_ADMIN_USERNAME}" -DoesNotRequirePreAuth:$true

net group "Domain Admins" ${KERBEROS_ADMIN_USERNAME}  /add
Write-Host "Successfully added  KERBEROS_ADMIN_USERNAME: [${KERBEROS_ADMIN_USERNAME}] in Domain Admins group"

$krbtest_pwd_secure = ConvertTo-SecureString ${KERBEROS_TEST_PASSWORD} -AsPlainText -Force
New-ADUser -Server $privateIP -Name "${KERBEROS_TEST_USERNAME}" -DisplayName "Kerberos TestUser" -GivenName Kerberos -Surname TestUser -TrustedForDelegation 1 -Path "$domain_path" -ChangePasswordAtLogon 0 -AccountPassword $krbtest_pwd_secure -PasswordNeverExpires 1 -Enabled 1
net group "Domain Admins" ${KERBEROS_TEST_USERNAME}  /add
Write-Host  "Successfully added KERBEROS_TEST_USERNAME : [${KERBEROS_TEST_USERNAME}]"

# # generate kerberos keys
# # https://docs.alfresco.com/5.1/tasks/auth-kerberos-cross-domain.html
$REALM="${DOMAIN}.${HOSTED_ZONE}".ToUpper()
$NETBIOSNAME = "${DOMAIN}".ToUpper()

ktpass -princ HTTP/$FQDN@$REALM -pass ${KERBEROS_ADMIN_PASSWORD} -mapuser $NETBIOSNAME\${KERBEROS_ADMIN_USERNAME} -crypto all -ptype KRB5_NT_PRINCIPAL -out c:\httpkerberos.keytab -kvno 0
setspn -a HTTP/$FQDN ${KERBEROS_ADMIN_USERNAME}

netsh interface ip set dns "Ethernet" static "127.0.0.1"
netsh interface ip add dns name="Ethernet" addr=$dns index=2
netsh interface ip set address "Ethernet" static $privateIP $subnet $gw

netsh advfirewall firewall set rule group=”network discovery” new enable=yes

</powershell>
