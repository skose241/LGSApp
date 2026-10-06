<cfif NOT structKeyExists(SESSION,"kullaniciID") OR NOT val(SESSION.kullaniciID)>
    <cfset donusAdresi=cgi.script_name>
    <cfif len(trim(cgi.query_string))>
        <cfset donusAdresi=donusAdresi & "?" & cgi.query_string>
    </cfif>
    
    <cflocation url="#application.kokYol#/views/kimlik/giris.cfm?donus=#urlEncodedFormat(donusAdresi)#" addtoken="false">
</cfif>

<cfif NOT structKeyExists(SESSION,"rol")>
    <cfset SESSION.rol=application.rol.ogrenci>
</cfif>