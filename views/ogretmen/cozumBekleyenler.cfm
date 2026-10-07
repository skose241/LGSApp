<cfset gerekliRoller="#application.rol.ogretmen#,#application.rol.mudur#">
<cfinclude template="/lgs/views/includes/yetki.cfm">

<cfset sayfaBasligi="Çözüm Bekleyenler">
<cfset basariMesaji="">
<cfset bransFiltresi=val(SESSION.bransDersID)>
<cfset mudurMu=(val(SESSION.rol) EQ application.rol.mudur)>
<cfset esikCevap=val(application.ayar.cozumEsikCevapSayisi)>
<cfset esikOran=val(application.ayar.cozumEsikYanlisOrani)>

<cfif structKeyExists(FORM,"gormezden") AND structKeyExists(FORM,"csrf") AND compare(FORM.csrf,SESSION.csrf) EQ 0>
    <cfquery datasource="#application.DSN#">
        UPDATE Sorular
        SET cozumGerekmiyor=1
        WHERE soruID=<cfqueryparam value="#val(FORM.soruID)#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfset basariMesaji="Soru listeden kaldırıldı">
</cfif>

<cfquery name="qListe" datasource="#application.DSN#">
    SELECT s.soruID,s.soruGorsel,s.soruMetni,s.dogruCevap,s.cevapSupheli,s.kaynak,
           d.dersAdi,k.kullaniciAdi,
           v.toplamCevap,v.yanlisSayisi,v.yanlisOrani
    FROM Sorular s
    INNER JOIN vw_SoruIstatistik v ON v.soruID=s.soruID
    INNER JOIN Dersler d ON d.dersID=s.dersID
    INNER JOIN Kullanicilar k ON k.kullaniciID=s.kullaniciID
    WHERE s.aktifMi=1
    AND s.cozumGerekmiyor=0
    AND v.toplamCevap>=<cfqueryparam value="#esikCevap#" cfsqltype="cf_sql_integer">
    AND v.yanlisOrani>=<cfqueryparam value="#esikOran#" cfsqltype="cf_sql_integer">
    AND NOT EXISTS(
        SELECT 1 FROM Cozumler c
        WHERE c.soruID=s.soruID
        AND c.cozumTipi=<cfqueryparam value="#application.cozumTipi.ogretmen#" cfsqltype="cf_sql_tinyint">
    )
    <cfif NOT mudurMu AND bransFiltresi>
        AND s.dersID=<cfqueryparam value="#bransFiltresi#" cfsqltype="cf_sql_integer">
    </cfif>
    ORDER BY v.yanlisOrani DESC,v.toplamCevap DESC
</cfquery>

<cfinclude template="/lgs/views/includes/baslik.cfm">

<cfoutput>
    <div class="yigin">
        <cfif len(basariMesaji)>
            <div class="bildirim bildirim--basarili" role="status">#encodeForHTML(basariMesaji)#</div>
        </cfif>

        <div class="baslik-satiri">
            <h2>Çözüm Bekleyen Sorular:</h2>
            <span class="rozet">#qListe.recordCount#</span>
        </div>

        <cfif qListe.recordCount>
            <p class="sessiz">En az #esikCevap# öğrencinin çözdüğü ve yanlış oranı %#esikOran# üzerinde olan sorular listelenir</p>

            <cfloop query="qListe">
                <section class="kart <cfif qListe.cevapSupheli>mod-kutu</cfif>">
                    <div class="kart__baslik">
                        <span class="rozet rozet--ders">#encodeForHTML(qListe.dersAdi)#</span>

                        <cfif qListe.cevapSupheli>
                            <span class="rozet rozet--yanlis">Cevap Şüpheli:</span>
                        </cfif>

                        <span class="rozet rozet--yanlis">%#numberFormat(qListe.yanlisOrani,"9")# yanlış</span>
                    </div>

                    <div class="kart__govde">
                        <cfif len(qListe.soruGorsel)>
                            <img
                                class="soru-gorsel" src="<cfif val(qListe.kaynak) EQ application.kaynak.ogretmen>#application.odevGorselYol#<cfelse>#application.soruGorselYol#</cfif>#qListe.soruGorsel#" alt="Soru Görseli">
                        <cfelseif len(qListe.soruMetni)>
                            <div class="soru__metin">#encodeForHTML(qListe.soruMetni)#</div>
                        </cfif>

                        <div class="dip-not">
                            <span>Çözen Öğrenci Sayısı: <b>#val(qListe.toplamCevap)#</b></span>
                            <span>Yanlış Cevap Sayısı: <b>#val(qListe.yanlisSayisi)#</b></span>
                            <span>Kayıtlı Doğru Cevap: <b>#qListe.dogruCevap#</b></span>
                        </div>

                        <div class="pano__eylem">
                            <a class="dugme dugme--ana" href="#application.kokYol#/views/ogretmen/cozumEkle.cfm?soruID=#qListe.soruID#">Çözüm Ekle</a>

                            <form method="post" action="#cgi.script_name#">
                                <cfinclude template="/lgs/views/includes/csrfAlan.cfm">
                                <input type="hidden" name="soruID" value="#qListe.soruID#">
                                <button class="dugme dugme--sade" type="submit" name="gormezden" value="1">Görmezden Gel</button>
                            </form>
                        </div>
                    </div>
                </section>
            </cfloop>
        <cfelse>
            <div class="bos-durum">
                <div class="bos-durum__daire"></div>
                <h3>Bekleyen soru yok</h3>
                <p class="sessiz">Öğrencilerin çoğunlukla yanlış yaptığı sorular burada listelenecek</p>
            </div>
        </cfif>
    </div>
</cfoutput>

<cfinclude template="/lgs/views/includes/altBilgi.cfm">