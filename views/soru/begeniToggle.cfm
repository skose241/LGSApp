<cfinclude template="/lgs/views/includes/yetki.cfm">

<cfparam name="FORM.soruID" default="0">
<cfset soruID=val(FORM.soruID)>

<cfif NOT soruID OR cgi.request_method NEQ "POST" OR NOT structKeyExists(FORM,"csrf") OR compare(FORM.csrf,SESSION.csrf) NEQ 0>
    <cflocation url="#application.kokYol#/anaSayfa.cfm" addtoken="false">
</cfif>

<cfquery name="qVarMi" datasource="#application.DSN#">
    SELECT begeniID
    FROM Begeniler
    WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    AND kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
</cfquery>

<cftry>
    <cfif qVarMi.recordCount>
        <cfquery datasource="#application.DSN#">
            DELETE FROM Begeniler
            WHERE begeniID=<cfqueryparam value="#val(qVarMi.begeniID)#" cfsqltype="cf_sql_integer">
        </cfquery>
    <cfelse>
        <cfquery datasource="#application.DSN#">
            INSERT INTO Begeniler(soruID,kullaniciID)
            VALUES(
            <cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
            )
        </cfquery>
    </cfif>

    <cfcatch type="any"></cfcatch>
</cftry>

<cflocation url="#application.kokYol#/views/soru/soruDetay.cfm?id=#soruID#" addtoken="false">