<cfinclude template="/lgs/views/includes/yetki.cfm">

<cfparam name="URL.odevID" default="0">
<cfset odevID=val(URL.odevID)>

<cfquery name="qOdev" datasource="#application.DSN#">
    SELECT o.odevID,o.baslik,o.bitisTarihi,o.durum,d.dersAdi
    FROM Odevler o
    INNER JOIN Dersler d ON d.dersID=o.dersID
    WHERE o.odevID=<cfqueryparam value="#odevID#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif NOT qOdev.recordCount>
    <cflocation url="#application.kokYol#/views/odev/odevListesi.cfm" addtoken="false">
</cfif>

<cfquery name="qSorular" datasource="#application.DSN#">
    SELECT os.siraNo,s.soruID,s.soruGorsel,s.dogruCevap,oc.verilenCevap,oc.dogruMu
    FROM OdevSorulari os
    INNER JOIN Sorular s ON s.soruID=os.soruID
    LEFT JOIN OdevCevaplari oc ON oc.soruID=os.soruID AND oc.odevID=os.odevID
        AND oc.kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
    WHERE os.odevID=<cfqueryparam value="#odevID#" cfsqltype="cf_sql_integer">
    ORDER BY os.siraNo
</cfquery>

<cfset dogruSayisi=0>
<cfset yanlisSayisi=0>
<cfset bosSayisi=0>

<cfloop query="qSorular">
    <cfif NOT len(qSorular.verilenCevap)>
        <cfset bosSayisi=bosSayisi+1>
    <cfelseif qSorular.dogruMu>
        <cfset dogruSayisi=dogruSayisi+1>
    <cfelse>
        <cfset yanlisSayisi=yanlisSayisi+1>
    </cfif>
</cfloop>

<cfset basariOrani=0>

<cfif qSorular.recordCount>
    <cfset basariOrani=round(dogruSayisi/qSorular.recordCount*100)>
</cfif>

<cfset sayfaBasligi="Ödev Sonucu">

<cfinclude template="/lgs/views/includes/baslik.cfm">

<cfoutput>
    <div class="yigin">
        <section class="pano">
            <h1 class="pano__baslik">#encodeForHTML(len(qOdev.baslik) ? qOdev.baslik : qOdev.dersAdi)#</h1>
            <p class="pano__alt">#encodeForHTML(qOdev.dersAdi)# ödevini tamamladınız</p>

            <div class="istatistik ust-bosluk">
                <div class="istatistik__kutu istatistik__kutu--dogru">
                    <span class="istatistik__sayi">#dogruSayisi#</span>
                    <span class="istatistik__ad">Doğru Sayısı:</span>
                </div>

                <div class="istatistik__kutu">
                    <span class="istatistik__sayi">#yanlisSayisi#</span>
                    <span class="istatistik__ad">Yanlış Sayısı:</span>
                </div>

                <div class="istatistik__kutu">
                    <span class="istatistik__sayi">#bosSayisi#</span>
                    <span class="istatistik__ad">Boş Sayısı:</span>
                </div>

                <div class="istatistik__kutu">
                    <span class="istatistik__sayi">%#basariOrani#</span>
                    <span class="istatistik__ad">Başarı Oranı:</span>
                </div>
            </div>
        </section>

        <cfif yanlisSayisi>
            <section class="kart">
                <div class="kart__baslik">Yanlış Yaptığınız Sorular:<span class="rozet">#yanlisSayisi#</span></div>

                <div class="kart__govde">
                    <div class="soru-izgara">
                        <cfloop query="qSorular">
                            <cfif len(qSorular.verilenCevap) AND NOT qSorular.dogruMu>
                                <div class="soru-kutu">
                                    <a class="soru-kutu__ust" href="#application.kokYol#/views/soru/soruDetay.cfm?id=#qSorular.soruID#">
                                        <img
                                            class="soru-kutu__gorsel" src="#application.odevGorselYol##qSorular.soruGorsel#" alt="Soru #qSorular.siraNo#">
                                    </a>

                                    <div class="soru-kutu__govde">
                                        <div class="soru-kutu__alt">
                                            <span class="rozet">#qSorular.siraNo#</span>
                                            <span class="rozet rozet--yanlis">Sizin Cevabınız: #qSorular.verilenCevap#  Doğru Cevap: #qSorular.dogruCevap#</span>
                                        </div>

                                        <a class="bag" href="#application.kokYol#/views/soru/soruDetay.cfm?id=#qSorular.soruID#">Çözümü Gör</a>
                                    </div>
                                </div>
                            </cfif>
                        </cfloop>
                    </div>
                </div>
            </section>
        </cfif>

        <section class="kart">
            <div class="kart__baslik">Tüm Sorular</div>

            <div class="kart__govde">
                <div class="siklar--satir">
                    <cfloop query="qSorular">
                        <a class="sik sik--sade <cfif NOT len(qSorular.verilenCevap)><cfelseif qSorular.dogruMu>sik--dogru<cfelse>sik--yanlis</cfif>" href="#application.kokYol#/views/soru/soruDetay.cfm?id=#qSorular.soruID#">
                            <span class="optik">#qSorular.siraNo#</span>
                        </a>
                    </cfloop>
                </div>
            </div>

            <div class="kart__ayrac">
                <a class="dugme dugme--ikincil dugme--tam" href="#application.kokYol#/views/odev/odevListesi.cfm">Ödevlere Dön</a>
            </div>
        </section>
    </div>
</cfoutput>

<cfinclude template="/lgs/views/includes/altBilgi.cfm">