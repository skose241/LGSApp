<cfsetting requesttimeout="300">
<cfsetting showdebugoutput="false">
<cfcontent type="text/plain; charset=utf-8" reset="true">

<cfparam name="URL.token" default="">

<cfif NOT len(trim(application.uretimToken)) OR compare(URL.token,application.uretimToken) NEQ 0>
    <cfoutput>Yetkisiz erişim</cfoutput>
    <cfabort>
</cfif>

<cfset bugun=createDate(year(now()),month(now()),day(now()))>
<cfset yayinlanan=0>
<cfset acilanOdev=0>

<cfquery name="qYayinlanacak" datasource="#application.DSN#">
    SELECT s.soruID,d.dersAdi
    FROM Sorular s
    INNER JOIN Dersler d ON d.dersID=s.dersID
    WHERE s.yayinTarihi<=<cfqueryparam value="#bugun#" cfsqltype="cf_sql_date">
    AND s.yayinlandiMi=0
    AND s.aktifMi=1
    AND s.kaynak=<cfqueryparam value="#application.kaynak.ai#" cfsqltype="cf_sql_tinyint">
</cfquery>

<cfif qYayinlanacak.recordCount>
    <cfquery datasource="#application.DSN#">
        UPDATE Sorular
        SET yayinlandiMi=1
        WHERE yayinTarihi<=<cfqueryparam value="#bugun#" cfsqltype="cf_sql_date">
        AND yayinlandiMi=0
        AND aktifMi=1
        AND kaynak=<cfqueryparam value="#application.kaynak.ai#" cfsqltype="cf_sql_tinyint">
    </cfquery>

    <cfset yayinlanan=qYayinlanacak.recordCount>
</cfif>

<cfquery name="qAcilacakOdevler" datasource="#application.DSN#">
    SELECT o.odevID,d.dersAdi
    FROM Odevler o
    INNER JOIN Dersler d ON d.dersID=o.dersID
    WHERE o.durum=<cfqueryparam value="#application.odevDurum.planlandi#" cfsqltype="cf_sql_nvarchar">
    AND o.baslangicTarihi<=<cfqueryparam value="#bugun#" cfsqltype="cf_sql_date">
    AND o.bitisTarihi>=<cfqueryparam value="#bugun#" cfsqltype="cf_sql_date">
</cfquery>

<cfif qAcilacakOdevler.recordCount>
    <cfquery datasource="#application.DSN#">
        UPDATE Odevler
        SET durum=<cfqueryparam value="#application.odevDurum.yayinda#" cfsqltype="cf_sql_nvarchar">
        WHERE durum=<cfqueryparam value="#application.odevDurum.planlandi#" cfsqltype="cf_sql_nvarchar">
        AND baslangicTarihi<=<cfqueryparam value="#bugun#" cfsqltype="cf_sql_date">
        AND bitisTarihi>=<cfqueryparam value="#bugun#" cfsqltype="cf_sql_date">
    </cfquery>

    <cfset acilanOdev=qAcilacakOdevler.recordCount>
</cfif>

<cfif yayinlanan OR acilanOdev>
    <cfquery name="qOgrenciler" datasource="#application.DSN#">
        SELECT kullaniciID
        FROM Kullanicilar
        WHERE rol=<cfqueryparam value="#application.rol.ogrenci#" cfsqltype="cf_sql_tinyint">
        AND aktifMi=1
    </cfquery>

    <cfset mesajMetni="">

    <cfif yayinlanan>
        <cfset mesajMetni="Bugünün #yayinlanan# sorusu yayında">
    </cfif>

    <cfif acilanOdev>
        <cfif len(mesajMetni)>
            <cfset mesajMetni=mesajMetni & " ve #acilanOdev# yeni ödev açıldı">
        <cfelse>
            <cfset mesajMetni="#acilanOdev# yeni ödev açıldı">
        </cfif>
    </cfif>

    <cfloop query="qOgrenciler">
        <cfquery datasource="#application.DSN#">
            INSERT INTO Bildirimler(kullaniciID,bildirimTipi,mesaj,hedefURL)
            VALUES(
            <cfqueryparam value="#val(qOgrenciler.kullaniciID)#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="gunlukSoru" cfsqltype="cf_sql_nvarchar">,
            <cfqueryparam value="#mesajMetni#" cfsqltype="cf_sql_nvarchar">,
            <cfqueryparam value="#application.kokYol#/anaSayfa.cfm" cfsqltype="cf_sql_nvarchar">
            )
        </cfquery>
    </cfloop>
</cfif>

<cfoutput>Yayın tamamlandı: #yayinlanan# soru, #acilanOdev# ödev#chr(10)#</cfoutput>

<cfloop query="qYayinlanacak">
    <cfoutput>#qYayinlanacak.dersAdi# - Soru ID: #qYayinlanacak.soruID# yayınlandı#chr(10)#</cfoutput>
</cfloop>