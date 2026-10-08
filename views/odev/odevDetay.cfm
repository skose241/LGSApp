<cfinclude template="/lgs/views/includes/yetki.cfm">

<cfparam name="URL.odevID" default="0">
<cfparam name="URL.sira" default="0">
<cfset odevID=val(URL.odevID)>
<cfset hataMesaji="">
<cfset ogretmenMi=(val(SESSION.rol) EQ application.rol.ogretmen OR val(SESSION.rol) EQ application.rol.mudur)>

<cfquery name="qOdev" datasource="#application.DSN#">
    SELECT o.odevID,o.ogretmenID,o.baslik,o.baslangicTarihi,o.bitisTarihi,o.durum,d.dersAdi
    FROM Odevler o
    INNER JOIN Dersler d ON d.dersID=o.dersID
    WHERE o.odevID=<cfqueryparam value="#odevID#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif NOT qOdev.recordCount>
    <cflocation url="#application.kokYol#/views/odev/odevListesi.cfm" addtoken="false">
</cfif>

<cfif qOdev.durum EQ application.odevDurum.taslak AND NOT ogretmenMi>
    <cflocation url="#application.kokYol#/views/odev/odevListesi.cfm?hata=yetkisiz" addtoken="false">
</cfif>

<cfset cozulebilirMi=(NOT ogretmenMi AND qOdev.durum EQ application.odevDurum.yayinda AND dateCompare(now(),qOdev.bitisTarihi,"d") LTE 0)>

<cfif structKeyExists(FORM,"cevapGonder")>
    <cfset hedefSoruID=val(FORM.soruID)>
    <cfset secilenDeger=ucase(trim(FORM.verilenCevap))>

    <cfif NOT structKeyExists(FORM,"csrf") OR compare(FORM.csrf,SESSION.csrf) NEQ 0>
        <cfset hataMesaji="Oturum doğrulaması başarısız">
    <cfelseif NOT cozulebilirMi>
        <cfset hataMesaji="Bu ödevin süresi dolmuş">
    <cfelseif NOT listFind("A,B,C,D",secilenDeger)>
        <cfset hataMesaji="Lütfen bir şık seçiniz">
    <cfelse>
        <cfquery name="qDogru" datasource="#application.DSN#">
            SELECT s.dogruCevap
            FROM OdevSorulari os
            INNER JOIN Sorular s ON s.soruID=os.soruID
            WHERE os.odevID=<cfqueryparam value="#odevID#" cfsqltype="cf_sql_integer">
            AND os.soruID=<cfqueryparam value="#hedefSoruID#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfif qDogru.recordCount>
            <cfset dogruMu=(compare(secilenDeger,trim(qDogru.dogruCevap)) EQ 0)>

            <cftry>
                <cftransaction>
                    <cfquery datasource="#application.DSN#">
                        INSERT INTO OdevCevaplari(odevID,soruID,kullaniciID,verilenCevap,dogruMu)
                        VALUES(
                        <cfqueryparam value="#odevID#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#hedefSoruID#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#secilenDeger#" cfsqltype="cf_sql_nchar">,
                        <cfqueryparam value="#dogruMu#" cfsqltype="cf_sql_bit">
                        )
                    </cfquery>

                    <cfif dogruMu>
                        <cfquery datasource="#application.DSN#">
                            UPDATE Kullanicilar
                            SET puan=puan+<cfqueryparam value="#val(application.ayar.puanDogruCevap)#" cfsqltype="cf_sql_integer">
                            WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
                        </cfquery>
                        <cfset SESSION.puan=val(SESSION.puan)+val(application.ayar.puanDogruCevap)>
                    </cfif>
                </cftransaction>

                <cfcatch type="any">
                    <cfset hataMesaji="Bu soruyu zaten cevapladınız">
                </cfcatch>
            </cftry>
        </cfif>
    </cfif>
</cfif>

<cfquery name="qSorular" datasource="#application.DSN#">
    SELECT os.siraNo,s.soruID,s.soruGorsel,s.dogruCevap,
           oc.verilenCevap,oc.dogruMu
    FROM OdevSorulari os
    INNER JOIN Sorular s ON s.soruID=os.soruID
    LEFT JOIN OdevCevaplari oc ON oc.soruID=os.soruID AND oc.odevID=os.odevID
        AND oc.kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
    WHERE os.odevID=<cfqueryparam value="#odevID#" cfsqltype="cf_sql_integer">
    ORDER BY os.siraNo
</cfquery>

<cfset cevaplanan=0>
<cfset bekleyenSira=0>

<cfloop query="qSorular">
    <cfif len(qSorular.verilenCevap)>
        <cfset cevaplanan=cevaplanan+1>
    <cfelseif NOT bekleyenSira>
        <cfset bekleyenSira=val(qSorular.siraNo)>
    </cfif>
</cfloop>

<cfif listFind("#application.odevDurum.taslak#,#application.odevDurum.planlandi#",qOdev.durum) AND NOT ogretmenMi>
    <cflocation url="#application.kokYol#/views/odev/odevSonuc.cfm?odevID=#odevID#" addtoken="false">
</cfif>

<cfset aktifSira=val(URL.sira)>

<cfif NOT aktifSira>
    <cfset aktifSira=bekleyenSira>
</cfif>

<cfif NOT aktifSira>
    <cfset aktifSira=1>
</cfif>

<cfset sayfaBasligi="#qOdev.dersAdi# Ödevi">

<cfinclude template="/lgs/views/includes/baslik.cfm">

<cfoutput>
    <div class="yigin">
        <cfif len(hataMesaji)>
            <div class="bildirim bildirim--hata" role="alert">#encodeForHTML(hataMesaji)#</div>
        </cfif>

        <section class="kart">
            <div class="kart__baslik">
                #encodeForHTML(len(qOdev.baslik) ? qOdev.baslik : qOdev.dersAdi)#
                <span class="rozet">#cevaplanan# / #qSorular.recordCount#</span>
            </div>

            <div class="kart__govde">
                <div class="soru__ust">
                    <span class="rozet rozet--ders">#encodeForHTML(qOdev.dersAdi)#</span>
                    <span class="sessiz">Son teslim: #dateFormat(qOdev.bitisTarihi,"dd.mm.yyyy")#</span>
                </div>

                <cfif NOT cozulebilirMi AND NOT ogretmenMi>
                    <div class="hedef-kutu">Bu ödevin süresi doldu.Soruları ve çözümleri inceleyebilirsiniz ancak cevap veremezsiniz</div>
                </cfif>
            </div>
        </section>

        <cfif qSorular.recordCount>
            <cfloop query="qSorular">
                <cfif ogretmenMi OR NOT cozulebilirMi OR val(qSorular.siraNo) EQ aktifSira OR len(qSorular.verilenCevap)>
                <section class="kart">
                    <div class="kart__baslik">
                        Soru #qSorular.siraNo#

                        <cfif len(qSorular.verilenCevap)>
                            <cfif qSorular.dogruMu>
                                <span class="rozet rozet--dogru">Doğru</span>
                            <cfelse>
                                <span class="rozet rozet--yanlis">Yanlış</span>
                            </cfif>
                        </cfif>
                    </div>

                    <div class="kart__govde">
                        <img
                            class="soru-gorsel" src="#application.odevGorselYol##qSorular.soruGorsel#" alt="Soru #qSorular.siraNo#">

                        <cfif len(qSorular.verilenCevap)>
                            <div class="sonuc <cfif qSorular.dogruMu>sonuc--dogru<cfelse>sonuc--yanlis</cfif>">
                                <div class="sonuc__kutu">
                                    <span class="sonuc__etiket">Cevabınız:</span>
                                    <span class="sonuc__harf">#qSorular.verilenCevap#</span>
                                </div>

                                <div class="sonuc__kutu">
                                    <span class="sonuc__etiket">Doğru Cevap:</span>
                                    <span class="sonuc__harf">#qSorular.dogruCevap#</span>
                                </div>
                            </div>

                            <div class="pano__eylem">
                                <a class="dugme dugme--sade" href="#application.kokYol#/views/soru/soruDetay.cfm?id=#qSorular.soruID#">Çözümleri Gör</a>
                            </div>
                        <cfelseif ogretmenMi>
                            <div class="hedef-kutu">Doğru cevap: <strong>#qSorular.dogruCevap#</strong></div>
                        <cfelseif cozulebilirMi>
                            <form method="post" action="#cgi.script_name#?odevID=#odevID#">
                                <cfinclude template="/lgs/views/includes/csrfAlan.cfm">
                                <input type="hidden" name="soruID" value="#qSorular.soruID#">

                                <div class="siklar--satir">
                                    <cfloop list="A,B,C,D" index="harf">
                                        <label class="sik sik--sade">
                                            <input type="radio" name="verilenCevap" value="#harf#" required>
                                            <span class="optik">#harf#</span>
                                        </label>
                                    </cfloop>
                                </div>

                                <div class="hedef-kutu ust-bosluk">Cevabınızı gönderdikten sonra değiştiremezsiniz</div>

                                <button class="dugme dugme--ana dugme--tam" type="submit" name="cevapGonder" value="1">Cevapla</button>
                            </form>
                        </cfif>
                    </div>
                </section>
                </cfif>
            </cfloop>

            <cfif cozulebilirMi AND cevaplanan LT qSorular.recordCount>
                <div class="sayfalama">
                    <cfloop query="qSorular">
                        <cfif len(qSorular.verilenCevap)>
                            <span>#qSorular.siraNo#</span>
                        <cfelse>
                            <a href="#cgi.script_name#?odevID=#odevID#&sira=#qSorular.siraNo#"<cfif val(qSorular.siraNo) EQ aktifSira> aria-current="page"</cfif>>#qSorular.siraNo#</a>
                        </cfif>
                    </cfloop>
                </div>
            </cfif>
        <cfelse>
            <div class="bos-durum">
                <div class="bos-durum__daire"></div>
                <h3>Bu ödevde soru yok</h3>
            </div>
        </cfif>
    </div>
</cfoutput>

<cfinclude template="/lgs/views/includes/altBilgi.cfm">