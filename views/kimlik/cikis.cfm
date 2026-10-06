<cfif structKeyExists(COOKIE,"beniHatirla") AND len(trim(COOKIE.beniHatirla))>
    <cfquery datasource="#application.DSN#">
        UPDATE Oturumlar
        SET aktifMi=0
        WHERE sessionToken=<cfqueryparam value="#COOKIE.beniHatirla#" cfsqltype="cf_sql_nvarchar">
    </cfquery>
    
    <cfcookie name="beniHatirla" value="" expires="now" httponly="true" secure="true">
</cfif>

<cfset structClear(SESSION)>
<cfset sessionInvalidate()>

<cflocation url="#application.kokYol#/views/kimlik/giris.cfm" addtoken="false">