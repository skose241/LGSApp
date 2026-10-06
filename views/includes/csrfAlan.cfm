<cfif NOT structKeyExists(SESSION,"csrf")>
    <cfset SESSION.csrf=hash(createUUID() & getTickCount(),"SHA-256")>
</cfif>

<cfoutput><input type="hidden" name="csrf" value="#SESSION.csrf#"></cfoutput>