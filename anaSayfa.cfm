<cfinclude template="/lgs/views/includes/yetki.cfm">

<cfset sayfaBasligi="Ana Sayfa">
<cfset bugun=createDate(year(now()),month(now()),day(now()))>
<cfset ogretmenMi=(val(SESSION.rol) EQ application.rol.ogretmen OR val(SESSION.rol) EQ application.rol.mudur)>

<cfif ogretmenMi>
    <cflocation url="#application.kokYol#/views/ogretmen/ogretmenPanel.cfm" addtoken="false">
</cfif>

<cfquery name="qGununSorulari" datasource="#application.DSN#">
    SELECT s.soruID,s.soruMetni,s.dersID,s.yayinTarihi,d.dersAdi,k.konuAdi,
           c.cevapID,c.dogruMu
    FROM Sorular s
    INNER JOIN Dersler d ON d.dersID=s.dersID
    LEFT JOIN Konular k ON k.konuID=s.konuID
    LEFT JOIN Cevaplar c ON c.soruID=s.soruID
    AND c.kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
    WHERE s.yayinTarihi>=DATEADD(DAY,-6,CAST(GETDATE() AS DATE))
</cfquery>

<cfquery name="qOdevler" datasource="#application.DSN#">
    SELECT o.odevID,o.baslik,o.bitisTarihi,d.dersAdi,
           (SELECT COUNT(*) FROM OdevSorulari os WHERE os.odevID=o.odevID) AS soruSayisi,
           (SELECT COUNT(*) FROM OdevCevaplari oc WHERE oc.odevID=o.odevID AND oc.kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">) AS cevapladigim
    FROM Odevler o
    INNER JOIN Dersler d ON d.dersID=o.dersID
    WHERE o.durum=<cfqueryparam value="#application.odevDurum.yayinda#" cfsqltype="cf_sql_nvarchar">
    AND o.bitisTarihi>=<cfqueryparam value="#bugun#" cfsqltype="cf_sql_date">
    ORDER BY o.bitisTarihi
</cfquery>

<cfquery name="qHaftalik" datasource="#application.DSN#">
    SELECT COUNT(*) AS toplam,SUM(CASE WHEN dogruMu=1 THEN 1 ELSE 0 END) AS dogru
    FROM(
        SELECT dogruMu,cevapTarihi FROM Cevaplar WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
        UNION ALL
        SELECT dogruMu,cevapTarihi FROM OdevCevaplari WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
    ) AS t
    WHERE cevapTarihi>=DATEADD(DAY,-7,CAST(GETDATE() AS DATE))
</cfquery>

<cfquery name="qSeri" datasource="#application.DSN#">
    SELECT DISTINCT CAST(cevapTarihi AS DATE) AS gun
    FROM(
        SELECT cevapTarihi FROM Cevaplar WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
        UNION ALL
        SELECT cevapTarihi FROM OdevCevaplari WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
    ) AS t
    WHERE cevapTarihi>=DATEADD(DAY,-30,CAST(GETDATE() AS DATE))
    ORDER BY gun DESC
</cfquery>

<cfset seriGun=0>
<cfset kontrolTarihi=bugun>

<cfloop query="qSeri">
    <cfif dateCompare(qSeri.gun,kontrolTarihi,"d") EQ 0>
        <cfset seriGun=seriGun+1>
        <cfset kontrolTarihi=dateAdd("d",-1,kontrolTarihi)>
    <cfelseif seriGun EQ 0 AND dateCompare(qSeri.gun,dateAdd("d",-1,bugun),"d") EQ 0>
        <cfset seriGun=1>
        <cfset kontrolTarihi=dateAdd("d",-2,bugun)>
    <cfelse>
        <cfbreak>
    </cfif>
</cfloop>

<cfquery name="qYanlislarim" datasource="#application.DSN#">
    SELECT COUNT(*) AS adet
    FROM(
        SELECT soruID FROM Cevaplar WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer"> AND dogruMu=0
        UNION
        SELECT soruID FROM OdevCevaplari WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer"> AND dogruMu=0
    ) AS t
</cfquery>

<cfquery name="qSonSorular" datasource="#application.DSN#">
    SELECT TOP 6 s.soruID,s.soruGorsel,s.olusturmaTarihi,d.dersAdi,k.kullaniciAdi,
           c.cevapID
    FROM Sorular s
    INNER JOIN Dersler d ON d.dersID=s.dersID
    INNER JOIN Kullanicilar k ON k.kullaniciID=s.kullaniciID
    LEFT JOIN Cevaplar c ON c.soruID=s.soruID
        AND c.kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
    WHERE s.kaynak=<cfqueryparam value="#application.kaynak.ogrenci#" cfsqltype="cf_sql_tinyint">
    AND s.aktifMi=1
    AND s.yayinlandiMi=1
    AND s.kullaniciID<><cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
    ORDER BY s.olusturmaTarihi DESC
</cfquery>

<cfset cozulenGunluk=0>

<cfloop query="qGununSorulari">
    <cfif val(qGununSorulari.cevapID)>
        <cfset cozulenGunluk=cozulenGunluk+1>
    </cfif>
</cfloop>

<cfinclude template="/lgs/views/includes/baslik.cfm">

<cfoutput>
    <div class="yigin">
        <cfif structKeyExists(URL,"hata") AND URL.hata EQ "yetkisiz">
            <div class="bildirim bildirim--hata" role="alert">Bu sayfaya erişim yetkiniz bulunmuyor</div>
        </cfif>

        <section class="pano">
            <h1 class="pano__baslik">Merhaba #encodeForHTML(SESSION.kullaniciAd)#</h1>

            <p class="pano__alt">
                <cfif seriGun GTE 2>
                    #seriGun# gündür aralıksız soru çözüyorsun,devam et
                <cfelseif cozulenGunluk EQ qGununSorulari.recordCount AND qGununSorulari.recordCount>
                    Bugünün sorularını tamamladın
                <cfelseif qGununSorulari.recordCount>
                    #qGununSorulari.recordCount-cozulenGunluk# soru seni bekliyor
                <cfelse>
                    Bugünün soruları henüz yayınlanmadı
                </cfif>
            </p>

            <div class="istatistik ust-bosluk">
                <div class="istatistik__kutu">
                    <span class="istatistik__sayi">#val(qHaftalik.toplam)#</span>
                    <span class="istatistik__ad">Bu hafta çözülen soru sayısı:</span>
                </div>

                <div class="istatistik__kutu istatistik__kutu--dogru">
                    <span class="istatistik__sayi">#val(qHaftalik.dogru)#</span>
                    <span class="istatistik__ad">Bu haftaki doğru cevap sayısı:</span>
                </div>

                <div class="istatistik__kutu">
                    <span class="istatistik__sayi">#seriGun#</span>
                    <span class="istatistik__ad">Günlük seri:</span>
                </div>

                <div class="istatistik__kutu">
                    <span class="istatistik__sayi">#val(SESSION.puan)#</span>
                    <span class="istatistik__ad">Toplam puan:</span>
                </div>
            </div>
        </section>

        <cfif qOdevler.recordCount>
            <section class="kart">
                <div class="kart__baslik">Açık Ödevler<span class="rozet">#qOdevler.recordCount#</span></div>

                <div class="kart__govde">
                    <cfloop query="qOdevler">
                        <div class="bilgi-liste">
                            <div>
                                <dt>
                                    #encodeForHTML(len(qOdevler.baslik) ? qOdevler.baslik : qOdevler.dersAdi)#
                                    <span class="rozet rozet--ders">#encodeForHTML(qOdevler.dersAdi)#</span>
                                </dt>

                                <dd>
                                    <span class="veri">#val(qOdevler.cevapladigim)# / #val(qOdevler.soruSayisi)#</span>
                                    <a class="bag" href="#application.kokYol#/views/odev/odevDetay.cfm?odevID=#qOdevler.odevID#">
                                        <cfif val(qOdevler.cevapladigim) GTE val(qOdevler.soruSayisi)>Gör<cfelseif val(qOdevler.cevapladigim)>Devam Et<cfelse>Başla</cfif>
                                    </a>
                                </dd>
                            </div>
                        </div>
                    </cfloop>
                </div>
            </section>
        </cfif>

        <section class="kart">
            <div class="kart__baslik">
                Günlük Sorular:
                <cfif qGununSorulari.recordCount>
                    <span class="rozet">#cozulenGunluk# / #qGununSorulari.recordCount#</span>
                </cfif>
            </div>

            <div class="kart__govde">
                <cfif qGununSorulari.recordCount>
                    <cfloop query="qGununSorulari">
                        <a class="sik" href="#application.kokYol#/views/soru/soruDetay.cfm?id=#qGununSorulari.soruID#">
                            <span class="optik">
                                <cfif val(qGununSorulari.cevapID)><cfif qGununSorulari.dogruMu>D<cfelse>Y</cfif><cfelse>#qGununSorulari.currentRow#</cfif>
                            </span>

                            <span class="sik__yazi">
                                <strong>#encodeForHTML(qGununSorulari.dersAdi)#</strong>
                                <cfif len(qGununSorulari.konuAdi)><br><span class="sessiz">#encodeForHTML(qGununSorulari.konuAdi)#</span></cfif>
                                
                                <cfif dateCompare(qGununSorulari.yayinTarihi,bugun,"d") NEQ 0>
                                    <span class="rozet">#dateFormat(qGununSorulari.yayinTarihi,"dd.mm")#</span>
                                </cfif>
                            </span>
                        </a>
                    </cfloop>
                <cfelse>
                    <div class="bos-durum">
                        <div class="bos-durum__daire"></div>
                        <h3>Henüz soru yok</h3>
                        <p class="sessiz">Günlük sorular her akşam saat 19:00'da yayınlanır</p>
                    </div>
                </cfif>
            </div>
        </section>

        <cfif val(qYanlislarim.adet)>
            <section class="kart">
                <div class="kart__govde">
                    <div class="hedef-kutu">
                        Toplam <strong>#val(qYanlislarim.adet)#</strong> yanlışın var.Çözümlerine bakarak tekrar etmek ister misin?
                        <a class="bag" href="#application.kokYol#/views/profil/profilim.cfm?sekme=yanlis">Yanlışlarım</a>
                    </div>
                </div>
            </section>
        </cfif>

        <section class="kart">
            <div class="kart__baslik">
                Arkadaşlarının Soruları:
                <a class="bag" href="#application.kokYol#/views/soru/soruEkle.cfm">Soru Sor</a>
            </div>

            <div class="kart__govde">
                <cfif qSonSorular.recordCount>
                    <div class="soru-izgara">
                        <cfloop query="qSonSorular">
                            <div class="soru-kutu">
                                <a class="soru-kutu__ust" href="#application.kokYol#/views/soru/soruDetay.cfm?id=#qSonSorular.soruID#">
                                    <img
                                        class="soru-kutu__gorsel" src="#application.soruGorselYol##qSonSorular.soruGorsel#" alt="Soru görseli">
                                </a>

                                <div class="soru-kutu__govde">
                                    <div class="soru-kutu__etiket">
                                        <span class="rozet rozet--ders">#encodeForHTML(qSonSorular.dersAdi)#</span>

                                        <cfif val(qSonSorular.cevapID)>
                                            <span class="rozet rozet--dogru">Çözdün</span>
                                        </cfif>
                                    </div>

                                    <span class="soru-kutu__kisi">#encodeForHTML(qSonSorular.kullaniciAdi)# · #dateFormat(qSonSorular.olusturmaTarihi,"dd.mm")#</span>
                                </div>
                            </div>
                        </cfloop>
                    </div>
                <cfelse>
                    <div class="bos-durum">
                        <div class="bos-durum__daire"></div>
                        <h3>Henüz soru paylaşılmamış</h3>
                        <p class="sessiz">Takıldığın bir soruyu yükleyerek başlayabilirsin</p>
                    </div>
                </cfif>
            </div>
        </section>
    </div>
</cfoutput>

<cfinclude template="/lgs/views/includes/altBilgi.cfm">