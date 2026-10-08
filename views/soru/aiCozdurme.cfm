<cfsetting requesttimeout="120">
<cfinclude template="/lgs/views/includes/yetki.cfm">

<cfparam name="FORM.soruID" default="0">
<cfset soruID=val(FORM.soruID)>
<cfset donusAdresi="#application.kokYol#/views/soru/soruDetay.cfm?id=#soruID#">

<cfif NOT soruID OR cgi.request_method NEQ "POST" OR NOT structKeyExists(FORM,"csrf") OR compare(FORM.csrf,SESSION.csrf) NEQ 0>
    <cflocation url="#application.kokYol#/anaSayfa.cfm" addtoken="false">
</cfif>

<cfset ogretmenMi=(val(SESSION.rol) EQ application.rol.ogretmen OR val(SESSION.rol) EQ application.rol.mudur)>

<cfquery name="qYetki" datasource="#application.DSN#">
    SELECT cevapID AS kayit FROM Cevaplar
    WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    AND kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
    UNION ALL
    SELECT odevCevapID FROM OdevCevaplari
    WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    AND kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif NOT qYetki.recordCount AND NOT ogretmenMi>
    <cflocation url="#donusAdresi#&hata=yetkisiz" addtoken="false">
</cfif>

<cfif structKeyExists(SESSION,"aiSonIstek") AND isDate(SESSION.aiSonIstek) AND dateDiff("s",SESSION.aiSonIstek,now()) LT 10>
    <cflocation url="#donusAdresi#&hata=bekle" addtoken="false">
</cfif>

<cfset SESSION.aiSonIstek=now()>

<cfif NOT ogretmenMi>
    <cfquery name="qLimit" datasource="#application.DSN#">
        SELECT COUNT(*) AS adet
        FROM AILog
        WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
        AND islemTipi IN ('cozum','cozum_gecersiz')
        AND eklenmeTarihi>=CAST(GETDATE() AS DATE)
    </cfquery>

    <cfif val(qLimit.adet) GTE val(application.aiLimit)>
        <cflocation url="#donusAdresi#&hata=limit" addtoken="false">
    </cfif>
</cfif>

<cfset aiNesnesi=createObject("component","lgs.ai")>
<cfset aiSonuc=aiNesnesi.cozumUretme(soruID=soruID,kullaniciID=val(SESSION.kullaniciID))>

<cfif aiSonuc.basari>
    <cflocation url="#donusAdresi#&ai=1" addtoken="false">
<cfelseif findNoCase("okunamad",aiSonuc.hata)>
    <cflocation url="#donusAdresi#&hata=okunamadi" addtoken="false">
<cfelse>
    <cflocation url="#donusAdresi#&hata=ai" addtoken="false">
</cfif>