<cfinclude template="/lgs/views/includes/yetki.cfm">

<cfparam name="URL.soruID" default="0">
<cfset soruID=val(URL.soruID)>
<cfset hataMesaji="">
<cfset ogretmenMi=(val(SESSION.rol) EQ application.rol.ogretmen OR val(SESSION.rol) EQ application.rol.mudur)>

<cfif ogretmenMi AND NOT soruID>
    <cfif structKeyExists(FORM,"durumGuncelle") AND structKeyExists(FORM,"csrf") AND compare(FORM.csrf,SESSION.csrf) EQ 0>
        <cfif listFind("incelendi,reddedildi",FORM.yeniDurum)>
            <cfquery datasource="#application.DSN#">
                UPDATE Sikayetler
                SET durum=<cfqueryparam value="#FORM.yeniDurum#" cfsqltype="cf_sql_nvarchar">
                WHERE sikayetID=<cfqueryparam value="#val(FORM.sikayetID)#" cfsqltype="cf_sql_integer">
            </cfquery>
        </cfif>
    </cfif>

    <cfif structKeyExists(FORM,"soruGizle") AND structKeyExists(FORM,"csrf") AND compare(FORM.csrf,SESSION.csrf) EQ 0>
        <cfquery datasource="#application.DSN#">
            UPDATE Sorular
            SET aktifMi=0
            WHERE soruID=<cfqueryparam value="#val(FORM.hedefSoruID)#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfquery datasource="#application.DSN#">
            UPDATE Sikayetler
            SET durum=<cfqueryparam value="incelendi" cfsqltype="cf_sql_nvarchar">
            WHERE soruID=<cfqueryparam value="#val(FORM.hedefSoruID)#" cfsqltype="cf_sql_integer">
        </cfquery>
    </cfif>

    <cfquery name="qSikayetler" datasource="#application.DSN#">
        SELECT s.sikayetID,s.soruID,s.sebep,s.durum,s.olusturmaTarihi,
               k.kullaniciAdi,d.dersAdi,so.soruGorsel,so.soruMetni,so.kaynak,so.aktifMi
        FROM Sikayetler s
        INNER JOIN Kullanicilar k ON k.kullaniciID=s.kullaniciID
        INNER JOIN Sorular so ON so.soruID=s.soruID
        INNER JOIN Dersler d ON d.dersID=so.dersID
        ORDER BY s.durum,s.olusturmaTarihi DESC
    </cfquery>

    <cfset sayfaBasligi="Şikayetler">

    <cfinclude template="/lgs/views/includes/baslik.cfm">

    <cfoutput>
        <div class="yigin">
            <div class="baslik-satiri">
                <h2>Şikayetler</h2>
                <span class="rozet">#qSikayetler.recordCount#</span>
            </div>

            <cfif qSikayetler.recordCount>
                <cfloop query="qSikayetler">
                    <section class="kart">
                        <div class="kart__baslik">
                            <span class="rozet rozet--ders">#encodeForHTML(qSikayetler.dersAdi)#</span>

                            <cfswitch expression="#qSikayetler.durum#">
                                <cfcase value="bekliyor"><span class="rozet rozet--yanlis">Bekliyor</span></cfcase>
                                <cfcase value="incelendi"><span class="rozet rozet--aktif">İncelendi</span></cfcase>
                                <cfdefaultcase><span class="rozet rozet--pasif">Reddedildi</span></cfdefaultcase>
                            </cfswitch>

                            <cfif NOT qSikayetler.aktifMi>
                                <span class="rozet rozet--pasif">Gizlendi</span>
                            </cfif>
                        </div>

                        <div class="kart__govde">
                            <div class="dip-not">
                                <span>Bildiren: <b>#encodeForHTML(qSikayetler.kullaniciAdi)#</b></span>
                                <span>Tarih: <b>#dateFormat(qSikayetler.olusturmaTarihi,"dd.mm.yyyy")#</b></span>
                            </div>

                            <div class="ai-kutu ust-bosluk">#encodeForHTML(qSikayetler.sebep)#</div>

                            <div class="pano__eylem">
                                <a class="dugme dugme--ikincil" href="#application.kokYol#/views/soru/soruDetay.cfm?id=#qSikayetler.soruID#">Soruyu Gör</a>

                                <cfif qSikayetler.durum EQ "bekliyor">
                                    <form method="post" action="#cgi.script_name#">
                                        <cfinclude template="/lgs/views/includes/csrfAlan.cfm">
                                        <input type="hidden" name="sikayetID" value="#qSikayetler.sikayetID#">
                                        <input type="hidden" name="yeniDurum" value="reddedildi">
                                        <button class="dugme dugme--sade" type="submit" name="durumGuncelle" value="1">Sorun Yok</button>
                                    </form>

                                    <cfif qSikayetler.aktifMi>
                                        <form method="post" action="#cgi.script_name#">
                                            <cfinclude template="/lgs/views/includes/csrfAlan.cfm">
                                            <input type="hidden" name="hedefSoruID" value="#qSikayetler.soruID#">
                                            <button class="dugme dugme--red dugme--kucuk" type="submit" name="soruGizle" value="1">Soruyu Gizle</button>
                                        </form>
                                    </cfif>
                                </cfif>
                            </div>
                        </div>
                    </section>
                </cfloop>
            <cfelse>
                <div class="bos-durum">
                    <div class="bos-durum__daire"></div>
                    <h3>Şikayet yok</h3>
                </div>
            </cfif>
        </div>
    </cfoutput>

    <cfinclude template="/lgs/views/includes/altBilgi.cfm">
    <cfabort>
</cfif>

<cfif NOT soruID>
    <cflocation url="#application.kokYol#/anaSayfa.cfm" addtoken="false">
</cfif>

<cfquery name="qSoru" datasource="#application.DSN#">
    SELECT s.soruID,d.dersAdi
    FROM Sorular s
    INNER JOIN Dersler d ON d.dersID=s.dersID
    WHERE s.soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    AND s.aktifMi=1
</cfquery>

<cfif NOT qSoru.recordCount>
    <cflocation url="#application.kokYol#/anaSayfa.cfm" addtoken="false">
</cfif>

<cfif structKeyExists(FORM,"gonder")>
    <cfset sebepDeger=trim(FORM.sebep)>

    <cfif NOT structKeyExists(FORM,"csrf") OR compare(FORM.csrf,SESSION.csrf) NEQ 0>
        <cfset hataMesaji="Oturum doğrulaması başarısız">
    <cfelseif len(sebepDeger) LT 10>
        <cfset hataMesaji="Lütfen sorunu biraz daha açıklayınız">
    <cfelse>
        <cfquery name="qDahaOnce" datasource="#application.DSN#">
            SELECT sikayetID
            FROM Sikayetler
            WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
            AND kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfif qDahaOnce.recordCount>
            <cfset hataMesaji="Bu soruyu zaten bildirdiniz">
        <cfelse>
            <cfquery datasource="#application.DSN#">
                INSERT INTO Sikayetler(soruID,kullaniciID,sebep,durum)
                VALUES(
                <cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#left(sebepDeger,500)#" cfsqltype="cf_sql_nvarchar">,
                <cfqueryparam value="bekliyor" cfsqltype="cf_sql_nvarchar">
                )
            </cfquery>

            <cflocation url="#application.kokYol#/views/soru/soruDetay.cfm?id=#soruID#&bildirildi=1" addtoken="false">
        </cfif>
    </cfif>
</cfif>

<cfset sayfaBasligi="Soru Bildir">

<cfinclude template="/lgs/views/includes/baslik.cfm">

<cfoutput>
    <div class="dar dar--genis">
        <cfif len(hataMesaji)>
            <div class="bildirim bildirim--hata" role="alert">#encodeForHTML(hataMesaji)#</div>
        </cfif>

        <section class="kart">
            <div class="kart__baslik">Soruyu Bildir</div>

            <div class="kart__govde">
                <p class="sessiz">Soruda bir sorun varsa öğretmenlerin incelemesi için bildirebilirsin</p>

                <form method="post" action="#cgi.script_name#?soruID=#soruID#">
                    <cfinclude template="/lgs/views/includes/csrfAlan.cfm">

                    <div class="alan">
                        <label for="sebep">Sorun Nedir:</label>
                        <textarea class="girdi" id="sebep" name="sebep" maxlength="500" required placeholder="Görsel okunmuyor,cevap anahtarı hatalı,soru eksik gibi"></textarea>
                        <span class="alan__ipucu">En az 10 karakter</span>
                    </div>

                    <button class="dugme dugme--ana dugme--tam" type="submit" name="gonder" value="1">Bildir</button>
                </form>
            </div>
        </section>
    </div>
</cfoutput>

<cfinclude template="/lgs/views/includes/altBilgi.cfm">