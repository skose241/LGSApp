<cfsetting requesttimeout="1800">
<cfsetting showdebugoutput="false">
<cfcontent type="text/plain; charset=utf-8" reset="true">

<cfparam name="URL.token" default="">

<cfif NOT len(trim(application.uretimToken)) OR compare(URL.token,application.uretimToken) NEQ 0>
    <cfoutput>Yetkisiz erişim</cfoutput>
    <cfabort>
</cfif>

<cfif NOT val(application.ayar.soruUretimAktifMi)>
    <cfoutput>Soru üretimi kapalı</cfoutput>
    <cfabort>
</cfif>

<cfset bugun=createDate(year(now()),month(now()),day(now()))>
<cfset gunNo=dayOfWeek(bugun)>
<cfset carpan=val(application.ayar.soruCarpani)>
<cfset aiNesnesi=createObject("component","lgs.ai")>
<cfset toplamBasarili=0>
<cfset toplamHatali=0>

<cfquery name="qProgram" datasource="#application.DSN#">
    SELECT p.dersID,p.soruSayisi,d.dersAdi
    FROM DersProgrami p
    INNER JOIN Dersler d ON d.dersID=p.dersID
    WHERE p.gunNo=<cfqueryparam value="#gunNo#" cfsqltype="cf_sql_tinyint">
    AND d.aktifMi=1
    ORDER BY d.siraNo
</cfquery>

<cfoutput>LGS Soru Üretimi - #dateFormat(bugun,"dd.mm.yyyy")# #chr(10)#</cfoutput>

<cfloop query="qProgram">
    <cfset dersID=val(qProgram.dersID)>
    <cfset uretilecek=ceiling(val(qProgram.soruSayisi)*carpan)>
    <cfset konuID=0>
    <cfset konuKaynagi="">

    <cfquery name="qMevcutUretim" datasource="#application.DSN#">
        SELECT COUNT(*) AS adet
        FROM UretimLog
        WHERE calismaTarihi=<cfqueryparam value="#bugun#" cfsqltype="cf_sql_date">
        AND dersID=<cfqueryparam value="#dersID#" cfsqltype="cf_sql_integer">
        AND durum=<cfqueryparam value="basarili" cfsqltype="cf_sql_nvarchar">
    </cfquery>

    <cfset eksikSayisi=uretilecek-val(qMevcutUretim.adet)>

    <cfif eksikSayisi LTE 0>
        <cfoutput>#qProgram.dersAdi#: zaten tamam,atlandı#chr(10)#</cfoutput>
        <cfcontinue>
    </cfif>

    <cfquery name="qPlan" datasource="#application.DSN#">
        SELECT konuID
        FROM GunlukKonuPlani
        WHERE planTarihi=<cfqueryparam value="#bugun#" cfsqltype="cf_sql_date">
        AND dersID=<cfqueryparam value="#dersID#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfif qPlan.recordCount>
        <cfset konuID=val(qPlan.konuID)>
        <cfset konuKaynagi="öğretmen seçimi">
    <cfelse>
        <cfquery name="qSonKullanilan" datasource="#application.DSN#">
            SELECT TOP 1 konuID
            FROM GunlukKonuPlani
            WHERE dersID=<cfqueryparam value="#dersID#" cfsqltype="cf_sql_integer">
            AND kullanildiMi=1
            ORDER BY planTarihi DESC
        </cfquery>

        <cfif qSonKullanilan.recordCount>
            <cfset konuID=val(qSonKullanilan.konuID)>
            <cfset konuKaynagi="son kullanılan konu">
        <cfelse>
            <cfquery name="qIlkKonu" datasource="#application.DSN#">
                SELECT TOP 1 konuID
                FROM Konular
                WHERE dersID=<cfqueryparam value="#dersID#" cfsqltype="cf_sql_integer">
                AND aktifMi=1
                ORDER BY siraNo
            </cfquery>

            <cfif qIlkKonu.recordCount>
                <cfset konuID=val(qIlkKonu.konuID)>
                <cfset konuKaynagi="varsayılan ilk konu">
            </cfif>
        </cfif>
    </cfif>

    <cfif NOT konuID>
        <cfquery datasource="#application.DSN#">
            INSERT INTO UretimLog(calismaTarihi,dersID,durum,hataMesaji)
            VALUES(
            <cfqueryparam value="#bugun#" cfsqltype="cf_sql_date">,
            <cfqueryparam value="#dersID#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="hatali" cfsqltype="cf_sql_nvarchar">,
            <cfqueryparam value="Bu ders için hiç konu tanımlanmamış" cfsqltype="cf_sql_longvarchar">
            )
        </cfquery>

        <cfset toplamHatali=toplamHatali+1>
        <cfoutput>#qProgram.dersAdi#: konu yok,atlandı#chr(10)#</cfoutput>
        <cfcontinue>
    </cfif>

    <cfoutput>#qProgram.dersAdi# (#konuKaynagi#) - #eksikSayisi# soru#chr(10)#</cfoutput>

    <cfloop from="1" to="#eksikSayisi#" index="s">
        <cfset uretim={basari=false,soruID=0,hata=""}>

        <cftry>
            <cfset uretim=aiNesnesi.soruUretme(
                dersID=dersID,
                konuID=konuID,
                yayinTarihi=bugun
                )>

            <cfcatch type="any">
                <cfset uretim.hata="İstisna:" & cfcatch.message>
            </cfcatch>
        </cftry>

        <cfif uretim.basari>
            <cfquery datasource="#application.DSN#">
                INSERT INTO UretimLog(calismaTarihi,dersID,konuID,durum,uretilenSoruID)
                VALUES(
                <cfqueryparam value="#bugun#" cfsqltype="cf_sql_date">,
                <cfqueryparam value="#dersID#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#konuID#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="basarili" cfsqltype="cf_sql_nvarchar">,
                <cfqueryparam value="#val(uretim.soruID)#" cfsqltype="cf_sql_integer">
                )
            </cfquery>

            <cfset toplamBasarili=toplamBasarili+1>
            <cfoutput>  #s#. soru üretildi (ID:#uretim.soruID#)#chr(10)#</cfoutput>
        <cfelse>
            <cfquery datasource="#application.DSN#">
                INSERT INTO UretimLog(calismaTarihi,dersID,konuID,durum,hataMesaji)
                VALUES(
                <cfqueryparam value="#bugun#" cfsqltype="cf_sql_date">,
                <cfqueryparam value="#dersID#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#konuID#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="hatali" cfsqltype="cf_sql_nvarchar">,
                <cfqueryparam value="#left(uretim.hata,4000)#" cfsqltype="cf_sql_longvarchar">
                )
            </cfquery>

            <cfset toplamHatali=toplamHatali+1>
            <cfoutput>  #s#. soru HATA: #left(uretim.hata,150)##chr(10)#</cfoutput>
        </cfif>

        <cfset sleep(6000)>
    </cfloop>

    <cfquery datasource="#application.DSN#">
        UPDATE GunlukKonuPlani
        SET kullanildiMi=1
        WHERE planTarihi=<cfqueryparam value="#bugun#" cfsqltype="cf_sql_date">
        AND dersID=<cfqueryparam value="#dersID#" cfsqltype="cf_sql_integer">
    </cfquery>
</cfloop>

<cfif toplamBasarili OR toplamHatali>
    <cfquery name="qMudurler" datasource="#application.DSN#">
        SELECT kullaniciID
        FROM Kullanicilar
        WHERE rol=<cfqueryparam value="#application.rol.mudur#" cfsqltype="cf_sql_tinyint">
        AND aktifMi=1
    </cfquery>

    <cfloop query="qMudurler">
        <cfquery datasource="#application.DSN#">
            INSERT INTO Bildirimler(kullaniciID,bildirimTipi,mesaj,hedefURL)
            VALUES(
            <cfqueryparam value="#val(qMudurler.kullaniciID)#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="uretim" cfsqltype="cf_sql_nvarchar">,
            <cfqueryparam value="Günlük soru üretimi tamamlandı: #toplamBasarili# başarılı, #toplamHatali# hatalı" cfsqltype="cf_sql_nvarchar">,
            <cfqueryparam value="#application.kokYol#/views/yonetim/uretimLog.cfm" cfsqltype="cf_sql_nvarchar">
            )
        </cfquery>
    </cfloop>
</cfif>

<cfoutput>#chr(10)#Tamamlandı: #toplamBasarili# başarılı, #toplamHatali# hatalı</cfoutput>