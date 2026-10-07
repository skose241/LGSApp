<cfset gerekliRoller="#application.rol.ogretmen#,#application.rol.mudur#">
<cfinclude template="/lgs/views/includes/yetki.cfm">

<cfset sayfaBasligi="Öğretmen Paneli">
<cfset bransFiltresi=val(SESSION.bransDersID)>
<cfset mudurMu=(val(SESSION.rol) EQ application.rol.mudur)>
<cfset esikCevap=val(application.ayar.cozumEsikCevapSayisi)>
<cfset esikOran=val(application.ayar.cozumEsikYanlisOrani)>

<cfquery name="qBekleyen" datasource="#application.DSN#">
    SELECT COUNT(*) AS adet
    FROM Sorular s
    INNER JOIN vw_SoruIstatistik v ON v.soruID=s.soruID
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
</cfquery>

<cfquery name="qSupheli" datasource="#application.DSN#">
    SELECT s.soruID,s.soruGorsel,s.dogruCevap,d.dersAdi
    FROM Sorular s
    INNER JOIN Dersler d ON d.dersID=s.dersID
    WHERE s.cevapSupheli=1
    AND s.aktifMi=1
    <cfif NOT mudurMu AND bransFiltresi>
        AND s.dersID=<cfqueryparam value="#bransFiltresi#" cfsqltype="cf_sql_integer">
    </cfif>
    ORDER BY s.olusturmaTarihi DESC
</cfquery>

<cfquery name="qOdevler" datasource="#application.DSN#">
    SELECT o.odevID,o.baslik,o.baslangicTarihi,o.bitisTarihi,o.durum,d.dersAdi,
           (SELECT COUNT(*) FROM OdevSorulari os WHERE os.odevID=o.odevID) AS soruSayisi,
           (SELECT COUNT(DISTINCT oc.kullaniciID) FROM OdevCevaplari oc WHERE oc.odevID=o.odevID) AS katilimci
    FROM Odevler o
    INNER JOIN Dersler d ON d.dersID=o.dersID
    WHERE o.durum IN (<cfqueryparam value="#application.odevDurum.planlandi#" cfsqltype="cf_sql_nvarchar">,<cfqueryparam value="#application.odevDurum.yayinda#" cfsqltype="cf_sql_nvarchar">)
    <cfif NOT mudurMu>
        AND o.ogretmenID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
    </cfif>
    ORDER BY o.baslangicTarihi
</cfquery>

<cfquery name="qSonSorular" datasource="#application.DSN#">
    SELECT TOP 8 s.soruID,s.soruGorsel,s.olusturmaTarihi,k.kullaniciAdi,d.dersAdi
    FROM Sorular s
    INNER JOIN Kullanicilar k ON k.kullaniciID=s.kullaniciID
    INNER JOIN Dersler d ON d.dersID=s.dersID
    WHERE s.aktifMi=1
    AND s.kaynak=<cfqueryparam value="#application.kaynak.ogrenci#" cfsqltype="cf_sql_tinyint">
    <cfif NOT mudurMu AND bransFiltresi>
        AND s.dersID=<cfqueryparam value="#bransFiltresi#" cfsqltype="cf_sql_integer">
    </cfif>
    ORDER BY s.olusturmaTarihi DESC
</cfquery>

<cfinclude template="/lgs/views/includes/baslik.cfm">

<cfoutput>
    <div class="yigin">
        <section class="pano">
            <h1 class="pano__baslik">Sayın #encodeForHTML(SESSION.kullaniciAd)# Hocam:</h1>
            <p class="pano__alt">Öğrencilerin takıldığı soruları buradan takip edebilirsiniz</p>

            <div class="pano__eylem">
                <a class="dugme dugme--ana" href="#application.kokYol#/views/odev/odevOlusturma.cfm">Yeni Ödev</a>
                <a class="dugme dugme--ikincil" href="#application.kokYol#/views/ogretmen/cozumBekleyenler.cfm">Çözüm Bekleyen Sorular<cfif val(qBekleyen.adet)> (#val(qBekleyen.adet)#)</cfif></a>
            </div>
        </section>

        <cfif qSupheli.recordCount>
            <section class="kart mod-kutu">
                <div class="kart__baslik">Cevap Anahtarı Şüpheli<span class="rozet rozet--yanlis">#qSupheli.recordCount#</span></div>

                <div class="kart__govde">
                    <p class="sessiz">Yapay zeka bu sorularda kayıtlı cevaptan farklı bir şık buldu.Kontrol edip düzeltiniz</p>

                    <div class="soru-izgara ust-bosluk">
                        <cfloop query="qSupheli">
                            <div class="soru-kutu">
                                <a class="soru-kutu__ust" href="#application.kokYol#/views/ogretmen/cozumEkle.cfm?soruID=#qSupheli.soruID#">
                                    <img
                                        class="soru-kutu__gorsel" src="#application.soruGorselYol##qSupheli.soruGorsel#" alt="Soru">
                                </a>

                                <div class="soru-kutu__govde">
                                    <div class="soru-kutu__alt">
                                        <span class="rozet rozet--ders">#encodeForHTML(qSupheli.dersAdi)#</span>
                                        <span class="rozet rozet--yanlis">#qSupheli.dogruCevap#</span>
                                    </div>
                                </div>
                            </div>
                        </cfloop>
                    </div>
                </div>
            </section>
        </cfif>

        <section class="kart">
            <div class="kart__baslik">Aktif Ödevler<span class="rozet">#qOdevler.recordCount#</span></div>

            <cfif qOdevler.recordCount>
                <div class="tablo-sarmal">
                    <table class="tablo">
                        <thead>
                            <tr>
                                <th>Ödev:</th>
                                <th>Ders:</th>
                                <th>Tarih:</th>
                                <th>Soru:</th>
                                <th>Katılan:</th>
                                <th>Durum:</th>
                                <th></th>
                            </tr>
                        </thead>

                        <tbody>
                            <cfloop query="qOdevler">
                                <tr>
                                    <td>#encodeForHTML(len(qOdevler.baslik) ? qOdevler.baslik : qOdevler.dersAdi)#</td>
                                    <td>#encodeForHTML(qOdevler.dersAdi)#</td>
                                    <td class="veri">#dateFormat(qOdevler.baslangicTarihi,"dd.mm")# - #dateFormat(qOdevler.bitisTarihi,"dd.mm")#</td>
                                    <td class="veri">#val(qOdevler.soruSayisi)#</td>
                                    <td class="veri">#val(qOdevler.katilimci)#</td>

                                    <td>
                                        <cfif qOdevler.durum EQ application.odevDurum.yayinda>
                                            <span class="rozet rozet--aktif">Açık</span>
                                        <cfelse>
                                            <span class="rozet">Planlandı</span>
                                        </cfif>
                                    </td>

                                    <td>
                                        <a class="metin-dugme" href="#application.kokYol#/views/odev/odevKatilim.cfm?odevID=#qOdevler.odevID#">Katılım</a>
                                    </td>
                                </tr>
                            </cfloop>
                        </tbody>
                    </table>
                </div>
            <cfelse>
                <div class="kart__govde">
                    <p class="sessiz">Aktif ödeviniz yok</p>
                </div>
            </cfif>
        </section>

        <section class="kart">
            <div class="kart__baslik">Öğrencilerin Son Soruları:</div>

            <div class="kart__govde">
                <cfif qSonSorular.recordCount>
                    <div class="soru-izgara">
                        <cfloop query="qSonSorular">
                            <div class="soru-kutu">
                                <a class="soru-kutu__ust" href="#application.kokYol#/views/soru/soruDetay.cfm?id=#qSonSorular.soruID#">
                                    <img
                                        class="soru-kutu__gorsel" src="#application.soruGorselYol##qSonSorular.soruGorsel#" alt="Soru">
                                </a>

                                <div class="soru-kutu__govde">
                                    <span class="rozet rozet--ders">#encodeForHTML(qSonSorular.dersAdi)#</span>
                                    <span class="soru-kutu__kisi">#encodeForHTML(qSonSorular.kullaniciAdi)# · #dateFormat(qSonSorular.olusturmaTarihi,"dd.mm")#</span>
                                </div>
                            </div>
                        </cfloop>
                    </div>
                <cfelse>
                    <p class="sessiz">Henüz soru yüklenmemiş</p>
                </cfif>
            </div>
        </section>
    </div>
</cfoutput>

<cfinclude template="/lgs/views/includes/altBilgi.cfm">