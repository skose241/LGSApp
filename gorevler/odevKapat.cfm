<cfsetting requesttimeout="300">
<cfsetting showdebugoutput="false">
<cfcontent type="text/plain; charset=utf-8" reset="true">

<cfparam name="URL.token" default="">

<cfif NOT len(trim(application.uretimToken)) OR compare(URL.token,application.uretimToken) NEQ 0>
    <cfoutput>Yetkisiz erişim</cfoutput>
    <cfabort>
</cfif>

<cfset bugun=createDate(year(now()),month(now()),day(now()))>
<cfset acilanOdev=0>

<cfquery name="qKapanacaklar" datasource="#application.DSN#">
    SELECT o.odevID,o.ogretmenID,o.baslik,o.bitisTarihi,d.dersAdi
    FROM Odevler o
    INNER JOIN Dersler d ON d.dersID=o.dersID
    WHERE o.durum=<cfqueryparam value="#application.odevDurum.yayinda#" cfsqltype="cf_sql_nvarchar">
    AND o.bitisTarihi<<cfqueryparam value="#bugun#" cfsqltype="cf_sql_date">
</cfquery>

<cfif qKapanacaklar.recordCount>
    <cfquery datasource="#application.DSN#">
        UPDATE Odevler
        SET durum=<cfqueryparam value="#application.odevDurum.kapandi#" cfsqltype="cf_sql_nvarchar">
        WHERE durum=<cfqueryparam value="#application.odevDurum.yayinda#" cfsqltype="cf_sql_nvarchar">
        AND bitisTarihi<<cfqueryparam value="#bugun#" cfsqltype="cf_sql_date">
    </cfquery>

    <cfloop query="qKapanacaklar">
        <cfquery datasource="#application.DSN#">
            INSERT INTO Bildirimler(kullaniciID,bildirimTipi,mesaj,hedefURL)
            VALUES(
            <cfqueryparam value="#val(qKapanacaklar.ogretmenID)#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="odevKapandi" cfsqltype="cf_sql_nvarchar">,
            <cfqueryparam value="#qKapanacaklar.dersAdi# ödeviniz kapandı,sonuçları inceleyebilirsiniz" cfsqltype="cf_sql_nvarchar">,
            <cfqueryparam value="#application.kokYol#/views/odev/odevKatilim.cfm?odevID=#val(qKapanacaklar.odevID)#" cfsqltype="cf_sql_nvarchar">
            )
        </cfquery>
    </cfloop>
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

    <cfquery name="qOgrenciler" datasource="#application.DSN#">
        SELECT kullaniciID
        FROM Kullanicilar
        WHERE rol=<cfqueryparam value="#application.rol.ogrenci#" cfsqltype="cf_sql_tinyint">
        AND aktifMi=1
    </cfquery>

    <cfloop query="qOgrenciler">
        <cfquery datasource="#application.DSN#">
            INSERT INTO Bildirimler(kullaniciID,bildirimTipi,mesaj,hedefURL)
            VALUES(
            <cfqueryparam value="#val(qOgrenciler.kullaniciID)#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="odev" cfsqltype="cf_sql_nvarchar">,
            <cfqueryparam value="#acilanOdev# yeni ödev açıldı" cfsqltype="cf_sql_nvarchar">,
            <cfqueryparam value="#application.kokYol#/views/odev/odevListesi.cfm" cfsqltype="cf_sql_nvarchar">
            )
        </cfquery>
    </cfloop>
</cfif>

<cfquery name="qEskiTaslak" datasource="#application.DSN#">
    SELECT COUNT(*) AS adet
    FROM Odevler
    WHERE durum=<cfqueryparam value="#application.odevDurum.taslak#" cfsqltype="cf_sql_nvarchar">
    AND olusturmaTarihi<DATEADD(DAY,-7,GETDATE())
</cfquery>

<cfoutput>Kapanan ödev: #qKapanacaklar.recordCount##chr(10)#</cfoutput>

<cfloop query="qKapanacaklar">
    <cfoutput>  #qKapanacaklar.dersAdi# (bitiş: #dateFormat(qKapanacaklar.bitisTarihi,"dd.mm.yyyy")#)#chr(10)#</cfoutput>
</cfloop>

<cfoutput>Açılan ödev: #acilanOdev##chr(10)#</cfoutput>

<cfif val(qEskiTaslak.adet)>
    <cfoutput>#chr(10)#Uyarı: #val(qEskiTaslak.adet)# adet 7 günden eski taslak ödev var</cfoutput>
</cfif>