<cfif structKeyExists(SESSION,"kullaniciID") AND val(SESSION.kullaniciID)>
    <cflocation url="#application.kokYol#/anaSayfa.cfm" addtoken="false">
<cfelse>
    <cflocation url="#application.kokYol#/views/kimlik/giris.cfm" addtoken="false">
</cfif>