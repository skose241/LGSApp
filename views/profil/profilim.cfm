<cfinclude template="/lgs/views/includes/yetki.cfm">

<cfparam name="URL.id" default="0">
<cfparam name="URL.sekme" default="dogru">
<cfparam name="URL.sayfa" default="1">

<cfset hedefID=val(URL.id)>
<cfset ogretmenMi=(val(SESSION.rol) EQ application.rol.ogretmen OR val(SESSION.rol) EQ application.rol.mudur)>

<cfif NOT hedefID>
    <cfset hedefID=val(SESSION.kullaniciID)>
</cfif>

<cfset kendiProfilim=(hedefID EQ val(SESSION.kullaniciID))>

<cfif NOT kendiProfilim AND NOT ogretmenMi>
    <cflocation url="#application.kokYol#/anaSayfa.cfm?hata=yetkisiz" addtoken="false">
</cfif>

<cfquery name="qKullanici" datasource="#application.DSN#">
    SELECT k.kullaniciID,k.kullaniciAdi,k.adSoyad,k.rol,k.puan,k.avatar,k.kayitTarihi,k.sonGirisTarihi,d.dersAdi
    FROM Kullanicilar k
    LEFT JOIN Dersler d ON d.dersID=k.bransDersID
    WHERE k.kullaniciID=<cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">
    AND k.aktifMi=1
</cfquery>

<cfif NOT qKullanici.recordCount>
    <cflocation url="#application.kokYol#/anaSayfa.cfm" addtoken="false">
</cfif>

<cfset gizliGorebilir=(kendiProfilim OR ogretmenMi)>
<cfset sayfaNo=val(URL.sayfa)>
<cfset sayfaBoyutu=12>

<cfif sayfaNo LT 1>
    <cfset sayfaNo=1>
</cfif>

<cfif NOT gizliGorebilir AND listFind("dogru,yanlis,begeni",URL.sekme)>
    <cfset URL.sekme="sordugu">
</cfif>

<cfquery name="qSayilar" datasource="#application.DSN#">
    SELECT
        (SELECT COUNT(*) FROM Sorular WHERE kullaniciID=<cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer"> AND aktifMi=1) AS sordugu,
        (SELECT COUNT(*) FROM Begeniler WHERE kullaniciID=<cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">) AS begeni,
        (SELECT COUNT(*) FROM Cozumler WHERE kullaniciID=<cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer"> AND cozumTipi=<cfqueryparam value="#application.cozumTipi.ogrenci#" cfsqltype="cf_sql_tinyint">) AS cozumu
</cfquery>

<cfquery name="qCevapSayi" datasource="#application.DSN#">
    SELECT
        SUM(CASE WHEN dogruMu=1 THEN 1 ELSE 0 END) AS dogru,
        SUM(CASE WHEN dogruMu=0 THEN 1 ELSE 0 END) AS yanlis,
        COUNT(*) AS toplam
    FROM(
        SELECT dogruMu FROM Cevaplar WHERE kullaniciID=<cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">
        UNION ALL
        SELECT dogruMu FROM OdevCevaplari WHERE kullaniciID=<cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">
    ) AS t
</cfquery>

<cfset basariOrani=0>

<cfif val(qCevapSayi.toplam)>
    <cfset basariOrani=round(val(qCevapSayi.dogru)/val(qCevapSayi.toplam)*100)>
</cfif>

<cfswitch expression="#URL.sekme#">
    <cfcase value="dogru,yanlis">
        <cfset hedefDurum=(URL.sekme EQ "dogru" ? 1 : 0)>

        <cfquery name="qListe" datasource="#application.DSN#">
            SELECT s.soruID,s.soruGorsel,s.soruMetni,s.kaynak,d.dersAdi,t.verilenCevap,s.dogruCevap,t.cevapTarihi
            FROM(
                SELECT soruID,verilenCevap,cevapTarihi FROM Cevaplar
                WHERE kullaniciID=<cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">
                AND dogruMu=<cfqueryparam value="#hedefDurum#" cfsqltype="cf_sql_bit">
                UNION ALL
                SELECT soruID,verilenCevap,cevapTarihi FROM OdevCevaplari
                WHERE kullaniciID=<cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">
                AND dogruMu=<cfqueryparam value="#hedefDurum#" cfsqltype="cf_sql_bit">
            ) AS t
            INNER JOIN Sorular s ON s.soruID=t.soruID
            INNER JOIN Dersler d ON d.dersID=s.dersID
            WHERE s.aktifMi=1
            ORDER BY t.cevapTarihi DESC
            OFFSET <cfqueryparam value="#(sayfaNo-1)*sayfaBoyutu#" cfsqltype="cf_sql_integer"> ROWS
            FETCH NEXT <cfqueryparam value="#sayfaBoyutu#" cfsqltype="cf_sql_integer"> ROWS ONLY
        </cfquery>

        <cfset toplamKayit=(URL.sekme EQ "dogru" ? val(qCevapSayi.dogru) : val(qCevapSayi.yanlis))>
    </cfcase>

    <cfcase value="begeni">
        <cfquery name="qListe" datasource="#application.DSN#">
            SELECT s.soruID,s.soruGorsel,s.soruMetni,s.kaynak,d.dersAdi,b.olusturmaTarihi AS cevapTarihi
            FROM Begeniler b
            INNER JOIN Sorular s ON s.soruID=b.soruID
            INNER JOIN Dersler d ON d.dersID=s.dersID
            WHERE b.kullaniciID=<cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">
            AND s.aktifMi=1
            ORDER BY b.olusturmaTarihi DESC
            OFFSET <cfqueryparam value="#(sayfaNo-1)*sayfaBoyutu#" cfsqltype="cf_sql_integer"> ROWS
            FETCH NEXT <cfqueryparam value="#sayfaBoyutu#" cfsqltype="cf_sql_integer"> ROWS ONLY
        </cfquery>

        <cfset toplamKayit=val(qSayilar.begeni)>
    </cfcase>

    <cfdefaultcase>
        <cfquery name="qListe" datasource="#application.DSN#">
            SELECT s.soruID,s.soruGorsel,s.soruMetni,s.kaynak,d.dersAdi,s.olusturmaTarihi AS cevapTarihi
            FROM Sorular s
            INNER JOIN Dersler d ON d.dersID=s.dersID
            WHERE s.kullaniciID=<cfqueryparam value="#hedefID#" cfsqltype="cf_sql_integer">
            AND s.aktifMi=1
            ORDER BY s.olusturmaTarihi DESC
            OFFSET <cfqueryparam value="#(sayfaNo-1)*sayfaBoyutu#" cfsqltype="cf_sql_integer"> ROWS
            FETCH NEXT <cfqueryparam value="#sayfaBoyutu#" cfsqltype="cf_sql_integer"> ROWS ONLY
        </cfquery>

        <cfset toplamKayit=val(qSayilar.sordugu)>
    </cfdefaultcase>
</cfswitch>

<cfset toplamSayfa=ceiling(toplamKayit/sayfaBoyutu)>
<cfset sayfaBasligi=(kendiProfilim ? "Profilim" : qKullanici.kullaniciAdi)>

<cfinclude template="/lgs/views/includes/baslik.cfm">

<cfoutput>
    <div class="yigin">
        <section class="kart">
            <div class="kart__govde">
                <div class="profil-ust">
                    <div class="avatar profil-ust__resim">#ucase(left(qKullanici.kullaniciAdi,1))#</div>

                    <div class="profil-ust__bilgi">
                        <h1 class="profil-ust__ad">#encodeForHTML(qKullanici.kullaniciAdi)#</h1>

                        <div class="profil-ust__satir">
                            <cfif len(qKullanici.adSoyad)>
                                <span class="sessiz">#encodeForHTML(qKullanici.adSoyad)#</span>
                            </cfif>

                            <cfif len(qKullanici.dersAdi)>
                                <span class="rozet rozet--ders">#encodeForHTML(qKullanici.dersAdi)#</span>
                            </cfif>

                            <span class="rozet rozet--xp">#val(qKullanici.puan)# XP</span>
                        </div>
                    </div>
                </div>

                <cfif gizliGorebilir>
                    <div class="istatistik ust-bosluk">
                        <div class="istatistik__kutu">
                            <span class="istatistik__sayi">#val(qCevapSayi.toplam)#</span>
                            <span class="istatistik__ad">Çözülen Soru Sayısı:</span>
                        </div>

                        <div class="istatistik__kutu istatistik__kutu--dogru">
                            <span class="istatistik__sayi">#val(qCevapSayi.dogru)#</span>
                            <span class="istatistik__ad">Doğru Cevap Sayısı:</span>
                        </div>

                        <div class="istatistik__kutu">
                            <span class="istatistik__sayi">#val(qCevapSayi.yanlis)#</span>
                            <span class="istatistik__ad">Yanlış Cevap Sayısı:</span>
                        </div>

                        <div class="istatistik__kutu">
                            <span class="istatistik__sayi">%#basariOrani#</span>
                            <span class="istatistik__ad">Başarı Oranı:</span>
                        </div>
                    </div>
                </cfif>
            </div>
        </section>

        <div class="sekmeler">
            <cfif gizliGorebilir>
                <a class="sekme" href="#cgi.script_name#?id=#hedefID#&sekme=dogru"<cfif URL.sekme EQ "dogru"> aria-selected="true"</cfif>>Doğrularım:<span class="sekme__sayi">#val(qCevapSayi.dogru)#</span></a>
                <a class="sekme" href="#cgi.script_name#?id=#hedefID#&sekme=yanlis"<cfif URL.sekme EQ "yanlis"> aria-selected="true"</cfif>>Yanlışlarım:<span class="sekme__sayi">#val(qCevapSayi.yanlis)#</span></a>
            </cfif>

            <a class="sekme" href="#cgi.script_name#?id=#hedefID#&sekme=sordugu"<cfif URL.sekme EQ "sordugu"> aria-selected="true"</cfif>>Sorduklarım:<span class="sekme__sayi">#val(qSayilar.sordugu)#</span></a>

            <cfif gizliGorebilir>
                <a class="sekme" href="#cgi.script_name#?id=#hedefID#&sekme=begeni"<cfif URL.sekme EQ "begeni"> aria-selected="true"</cfif>>Beğendiklerim:<span class="sekme__sayi">#val(qSayilar.begeni)#</span></a>
            </cfif>
        </div>

        <section class="kart">
            <div class="kart__govde">
                <cfif qListe.recordCount>
                    <div class="soru-izgara">
                        <cfloop query="qListe">
                            <div class="soru-kutu">
                                <a class="soru-kutu__ust" href="#application.kokYol#/views/soru/soruDetay.cfm?id=#qListe.soruID#">
                                    <cfif len(qListe.soruGorsel)>
                                        <img
                                            class="soru-kutu__gorsel" src="<cfif val(qListe.kaynak) EQ application.kaynak.ogretmen>#application.odevGorselYol#<cfelse>#application.soruGorselYol#</cfif>#qListe.soruGorsel#" alt="Soru görseli">
                                    <cfelse>
                                        <div class="soru-kutu__onizleme">#encodeForHTML(left(qListe.soruMetni,160))#</div>
                                    </cfif>
                                </a>

                                <div class="soru-kutu__govde">
                                    <div class="soru-kutu__etiket">
                                        <span class="rozet rozet--ders">#encodeForHTML(qListe.dersAdi)#</span>

                                        <cfif URL.sekme EQ "yanlis">
                                            <span class="rozet rozet--yanlis">#qListe.verilenCevap# yerine #qListe.dogruCevap#</span>
                                        <cfelseif URL.sekme EQ "dogru">
                                            <span class="rozet rozet--dogru">#qListe.dogruCevap#</span>
                                        </cfif>
                                    </div>

                                    <span class="soru-kutu__kisi">#dateFormat(qListe.cevapTarihi,"dd.mm.yyyy")#</span>
                                </div>
                            </div>
                        </cfloop>
                    </div>

                    <cfif toplamSayfa GT 1>
                        <div class="sayfalama ust-bosluk">
                            <cfloop from="1" to="#toplamSayfa#" index="p">
                                <cfif p EQ sayfaNo>
                                    <a href="#cgi.script_name#?id=#hedefID#&sekme=#URL.sekme#&sayfa=#p#" aria-current="page">#p#</a>
                                <cfelse>
                                    <a href="#cgi.script_name#?id=#hedefID#&sekme=#URL.sekme#&sayfa=#p#">#p#</a>
                                </cfif>
                            </cfloop>
                        </div>
                    </cfif>
                <cfelse>
                    <div class="bos-durum">
                        <div class="bos-durum__daire"></div>

                        <h3>
                            <cfswitch expression="#URL.sekme#">
                                <cfcase value="dogru">Henüz doğru cevap yok</cfcase>
                                <cfcase value="yanlis">Henüz yanlış cevap yok</cfcase>
                                <cfcase value="begeni">Henüz beğeni yok</cfcase>
                                <cfdefaultcase>Henüz soru sorulmamış</cfdefaultcase>
                            </cfswitch>
                        </h3>

                        <cfif URL.sekme EQ "yanlis">
                            <p class="sessiz">Yanlış yaptığın sorular burada toplanır,çözümleriyle birlikte tekrar edebilirsin</p>
                        </cfif>
                    </div>
                </cfif>
            </div>
        </section>
    </div>
</cfoutput>

<cfinclude template="/lgs/views/includes/altBilgi.cfm">