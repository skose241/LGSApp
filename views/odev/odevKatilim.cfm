<cfset gerekliRoller="#application.rol.ogretmen#,#application.rol.mudur#">
<cfinclude template="/lgs/views/includes/yetki.cfm">

<cfparam name="URL.odevID" default="0">
<cfset odevID=val(URL.odevID)>

<cfquery name="qOdev" datasource="#application.DSN#">
    SELECT o.odevID,o.ogretmenID,o.baslik,o.baslangicTarihi,o.bitisTarihi,o.durum,d.dersAdi
    FROM Odevler o
    INNER JOIN Dersler d ON d.dersID=o.dersID
    WHERE o.odevID=<cfqueryparam value="#odevID#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif NOT qOdev.recordCount>
    <cflocation url="#application.kokYol#/views/odev/odevListesi.cfm" addtoken="false">
</cfif>

<cfif val(qOdev.ogretmenID) NEQ val(SESSION.kullaniciID) AND val(SESSION.rol) NEQ application.rol.mudur>
    <cflocation url="#application.kokYol#/views/odev/odevListesi.cfm?hata=yetkisiz" addtoken="false">
</cfif>

<cfquery name="qSoruSayi" datasource="#application.DSN#">
    SELECT COUNT(*) AS adet
    FROM OdevSorulari
    WHERE odevID=<cfqueryparam value="#odevID#" cfsqltype="cf_sql_integer">
</cfquery>

<cfset toplamSoru=val(qSoruSayi.adet)>

<cfquery name="qOgrenciler" datasource="#application.DSN#">
    SELECT k.kullaniciID,k.kullaniciAdi,k.adSoyad,
           COUNT(oc.odevCevapID) AS cevaplanan,
           SUM(CASE WHEN oc.dogruMu=1 THEN 1 ELSE 0 END) AS dogru,
           MAX(oc.cevapTarihi) AS sonCevap
    FROM Kullanicilar k
    LEFT JOIN OdevCevaplari oc ON oc.kullaniciID=k.kullaniciID
        AND oc.odevID=<cfqueryparam value="#odevID#" cfsqltype="cf_sql_integer">
    WHERE k.rol=<cfqueryparam value="#application.rol.ogrenci#" cfsqltype="cf_sql_tinyint">
    AND k.aktifMi=1
    GROUP BY k.kullaniciID,k.kullaniciAdi,k.adSoyad
    ORDER BY COUNT(oc.odevCevapID) DESC,k.kullaniciAdi
</cfquery>

<cfquery name="qSoruBazli" datasource="#application.DSN#">
    SELECT os.siraNo,s.soruID,s.soruGorsel,s.dogruCevap,
           COUNT(oc.odevCevapID) AS cevaplanan,
           SUM(CASE WHEN oc.dogruMu=1 THEN 1 ELSE 0 END) AS dogru
    FROM OdevSorulari os
    INNER JOIN Sorular s ON s.soruID=os.soruID
    LEFT JOIN OdevCevaplari oc ON oc.soruID=os.soruID AND oc.odevID=os.odevID
    WHERE os.odevID=<cfqueryparam value="#odevID#" cfsqltype="cf_sql_integer">
    GROUP BY os.siraNo,s.soruID,s.soruGorsel,s.dogruCevap
    ORDER BY os.siraNo
</cfquery>

<cfset tamamlayan=0>
<cfset hicBaslamayan=0>

<cfloop query="qOgrenciler">
    <cfif val(qOgrenciler.cevaplanan) EQ toplamSoru AND toplamSoru>
        <cfset tamamlayan=tamamlayan+1>
    <cfelseif NOT val(qOgrenciler.cevaplanan)>
        <cfset hicBaslamayan=hicBaslamayan+1>
    </cfif>
</cfloop>

<cfset sayfaBasligi="Ödev Katılımı">

<cfinclude template="/lgs/views/includes/baslik.cfm">

<cfoutput>
    <div class="yigin">
        <section class="kart">
            <div class="kart__baslik">
                #encodeForHTML(len(qOdev.baslik) ? qOdev.baslik : qOdev.dersAdi)#
                <span class="rozet rozet--ders">#encodeForHTML(qOdev.dersAdi)#</span>
            </div>

            <div class="kart__govde">
                <div class="istatistik">
                    <div class="istatistik__kutu istatistik__kutu--dogru">
                        <span class="istatistik__sayi">#tamamlayan#</span>
                        <span class="istatistik__ad">Tamamlayan Sayısı:</span>
                    </div>

                    <div class="istatistik__kutu">
                        <span class="istatistik__sayi">#qOgrenciler.recordCount-tamamlayan-hicBaslamayan#</span>
                        <span class="istatistik__ad">Devam Eden Sayısı:</span>
                    </div>

                    <div class="istatistik__kutu">
                        <span class="istatistik__sayi">#hicBaslamayan#</span>
                        <span class="istatistik__ad">Başlamayan Sayısı:</span>
                    </div>

                    <div class="istatistik__kutu">
                        <span class="istatistik__sayi">#toplamSoru#</span>
                        <span class="istatistik__ad">Soru Sayısı:</span>
                    </div>
                </div>

                <div class="dip-not ust-bosluk">
                    <span>Tarih: <b>#dateFormat(qOdev.baslangicTarihi,"dd.mm.yyyy")# - #dateFormat(qOdev.bitisTarihi,"dd.mm.yyyy")#</b></span>
                </div>
            </div>
        </section>

        <section class="kart">
            <div class="kart__baslik">Öğrenciler</div>

            <div class="tablo-sarmal">
                <table class="tablo">
                    <thead>
                        <tr>
                            <th>Öğrenci Listesi:</th>
                            <th>Çözülen Soru Sayısı:</th>
                            <th>Doğru Sayısı:</th>
                            <th>Başarı Oranı:</th>
                            <th>Son İşlem Tarihi:</th>
                        </tr>
                    </thead>

                    <tbody>
                        <cfloop query="qOgrenciler">
                            <tr<cfif NOT val(qOgrenciler.cevaplanan)> class="pasif"</cfif>>
                                <td>
                                    #encodeForHTML(qOgrenciler.kullaniciAdi)#
                                    <cfif len(qOgrenciler.adSoyad)><br><span class="sessiz">#encodeForHTML(qOgrenciler.adSoyad)#</span></cfif>
                                </td>

                                <td class="veri">#val(qOgrenciler.cevaplanan)# / #toplamSoru#</td>
                                <td class="veri">#val(qOgrenciler.dogru)#</td>

                                <td class="veri">
                                    <cfif val(qOgrenciler.cevaplanan)>
                                        %#round(val(qOgrenciler.dogru)/val(qOgrenciler.cevaplanan)*100)#
                                    <cfelse>
                                        -
                                    </cfif>
                                </td>

                                <td class="veri">
                                    <cfif len(qOgrenciler.sonCevap)>#dateFormat(qOgrenciler.sonCevap,"dd.mm")# #timeFormat(qOgrenciler.sonCevap,"HH:mm")#<cfelse>-</cfif>
                                </td>
                            </tr>
                        </cfloop>
                    </tbody>
                </table>
            </div>
        </section>

        <section class="kart">
            <div class="kart__baslik">Soru Bazlı Durum</div>

            <div class="tablo-sarmal">
                <table class="tablo">
                    <thead>
                        <tr>
                            <th>Soru Numarası:</th>
                            <th>Doğru Cevap:</th>
                            <th>Çözen Öğrenci Sayısı:</th>
                            <th>Doğru Çözen Sayısı:</th>
                            <th>Başarı Oranı:</th>
                            <th></th>
                        </tr>
                    </thead>

                    <tbody>
                        <cfloop query="qSoruBazli">
                            <tr>
                                <td class="veri">#qSoruBazli.siraNo#</td>
                                <td class="veri">#qSoruBazli.dogruCevap#</td>
                                <td class="veri">#val(qSoruBazli.cevaplanan)#</td>
                                <td class="veri">#val(qSoruBazli.dogru)#</td>

                                <td class="veri">
                                    <cfif val(qSoruBazli.cevaplanan)>
                                        <cfset oran=round(val(qSoruBazli.dogru)/val(qSoruBazli.cevaplanan)*100)>
                                        <span class="rozet <cfif oran LT 40>rozet--yanlis<cfelseif oran GTE 70>rozet--dogru</cfif>">%#oran#</span>
                                    <cfelse>
                                        -
                                    </cfif>
                                </td>

                                <td>
                                    <a class="metin-dugme" href="#application.kokYol#/views/soru/soruDetay.cfm?id=#qSoruBazli.soruID#">Soruyu Gör</a>
                                </td>
                            </tr>
                        </cfloop>
                    </tbody>
                </table>
            </div>
        </section>

        <div class="pano__eylem">
            <a class="dugme dugme--ikincil" href="#application.kokYol#/views/odev/odevListesi.cfm">Ödevlere Dön</a>
        </div>
    </div>
</cfoutput>

<cfinclude template="/lgs/views/includes/altBilgi.cfm">