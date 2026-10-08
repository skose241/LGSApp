<cfset gerekliRoller=application.rol.mudur>
<cfinclude template="/lgs/views/includes/yetki.cfm">

<cfset sayfaBasligi="Yönetim Paneli">
<cfset bugun=createDate(year(now()),month(now()),day(now()))>
<cfset gorevSonucu="">

<cfif structKeyExists(FORM,"gorevCalistir") AND structKeyExists(FORM,"csrf") AND compare(FORM.csrf,SESSION.csrf) EQ 0>
    <cfif listFind("soruUret,soruYayinla,odevKapat",FORM.gorevAdi)>
        <cfsetting requesttimeout="1800">

        <cftry>
            <cfhttp method="GET"
                url="http://localhost#(cgi.server_port NEQ 80 ? ':' & cgi.server_port : '')##application.kokYol#/gorevler/#FORM.gorevAdi#.cfm"
                result="gorevCevap"
                charset="UTF-8"
                throwonerror="false"
                timeout="1500">
                <cfhttpparam type="url" name="token" value="#application.uretimToken#">
            </cfhttp>

            <cfset gorevSonucu=gorevCevap.fileContent>

            <cfcatch type="any">
                <cfset gorevSonucu="Görev çalıştırılamadı:" & cfcatch.message>
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<cfquery name="qOzet" datasource="#application.DSN#">
    SELECT
        (SELECT COUNT(*) FROM Kullanicilar WHERE rol=<cfqueryparam value="#application.rol.ogrenci#" cfsqltype="cf_sql_tinyint"> AND aktifMi=1) AS ogrenci,
        (SELECT COUNT(*) FROM Kullanicilar WHERE rol=<cfqueryparam value="#application.rol.ogretmen#" cfsqltype="cf_sql_tinyint"> AND aktifMi=1) AS ogretmen,
        (SELECT COUNT(*) FROM Sorular WHERE aktifMi=1) AS soru,
        (SELECT COUNT(*) FROM Cevaplar) + (SELECT COUNT(*) FROM OdevCevaplari) AS cevap,
        (SELECT COUNT(*) FROM Sikayetler WHERE durum='bekliyor') AS sikayet,
        (SELECT COUNT(*) FROM Odevler WHERE durum=<cfqueryparam value="#application.odevDurum.yayinda#" cfsqltype="cf_sql_nvarchar">) AS odev
</cfquery>

<cfquery name="qBugunUretim" datasource="#application.DSN#">
    SELECT
        SUM(CASE WHEN durum='basarili' THEN 1 ELSE 0 END) AS basarili,
        SUM(CASE WHEN durum='hatali' THEN 1 ELSE 0 END) AS hatali
    FROM UretimLog
    WHERE calismaTarihi=<cfqueryparam value="#bugun#" cfsqltype="cf_sql_date">
</cfquery>

<cfquery name="qBugunYayin" datasource="#application.DSN#">
    SELECT
        SUM(CASE WHEN yayinlandiMi=1 THEN 1 ELSE 0 END) AS yayinda,
        SUM(CASE WHEN yayinlandiMi=0 THEN 1 ELSE 0 END) AS bekleyen
    FROM Sorular
    WHERE yayinTarihi=<cfqueryparam value="#bugun#" cfsqltype="cf_sql_date">
    AND kaynak=<cfqueryparam value="#application.kaynak.ai#" cfsqltype="cf_sql_tinyint">
</cfquery>

<cfquery name="qSonHatalar" datasource="#application.DSN#">
    SELECT TOP 10 sayfa,islem,mesaj,eklenmeTarihi
    FROM HataLog
    ORDER BY eklenmeTarihi DESC
</cfquery>

<cfinclude template="/lgs/views/includes/baslik.cfm">

<cfoutput>
    <div class="yigin">

        <section class="pano">
            <h1 class="pano__baslik">Yönetim Paneli</h1>
            <p class="pano__alt">Sistem Durumu ve Görev Yönetimi</p>

            <div class="istatistik ust-bosluk">
                <div class="istatistik__kutu">
                    <span class="istatistik__sayi">#val(qOzet.ogrenci)#</span>
                    <span class="istatistik__ad">Öğrenci:</span>
                </div>

                <div class="istatistik__kutu">
                    <span class="istatistik__sayi">#val(qOzet.soru)#</span>
                    <span class="istatistik__ad">Soru:</span>
                </div>

                <div class="istatistik__kutu">
                    <span class="istatistik__sayi">#val(qOzet.cevap)#</span>
                    <span class="istatistik__ad">Cevap:</span>
                </div>

                <div class="istatistik__kutu <cfif val(qOzet.sikayet)>istatistik__kutu--favori</cfif>">
                    <span class="istatistik__sayi">#val(qOzet.sikayet)#</span>
                    <span class="istatistik__ad">Bekleyen şikayet sayısı:</span>
                </div>
            </div>
        </section>

        <section class="kart">
            <div class="kart__baslik">Bugünün Durumu</div>

            <div class="kart__govde">
                <div class="bilgi-liste">
                    <div>
                        <dt>Üretilen soru</dt>
                        <dd>#val(qBugunUretim.basarili)# başarılı<cfif val(qBugunUretim.hatali)>,#val(qBugunUretim.hatali)# hatalı</cfif></dd>
                    </div>

                    <div>
                        <dt>Yayın durumu</dt>
                        <dd>#val(qBugunYayin.yayinda)# yayında,#val(qBugunYayin.bekleyen)# bekliyor</dd>
                    </div>

                    <div>
                        <dt>Açık ödev</dt>
                        <dd>#val(qOzet.odev)#</dd>
                    </div>
                </div>
            </div>
        </section>

        <section class="kart">
            <div class="kart__baslik">Görevleri Elle Çalıştır</div>

            <div class="kart__govde">
                <p class="sessiz">Zamanlanmış görev çalışmadıysa buradan tetikleyebilirsiniz.Üretim birkaç dakika sürebilir</p>

                <div class="pano__eylem">
                    <form method="post" action="#cgi.script_name#">
                        <cfinclude template="/lgs/views/includes/csrfAlan.cfm">
                        <input type="hidden" name="gorevAdi" value="soruUret">
                        <button class="dugme dugme--ana" type="submit" name="gorevCalistir" value="1">Soru Üret</button>
                    </form>

                    <form method="post" action="#cgi.script_name#">
                        <cfinclude template="/lgs/views/includes/csrfAlan.cfm">
                        <input type="hidden" name="gorevAdi" value="soruYayinla">
                        <button class="dugme dugme--ikincil" type="submit" name="gorevCalistir" value="1">Soruları Yayınla</button>
                    </form>

                    <form method="post" action="#cgi.script_name#">
                        <cfinclude template="/lgs/views/includes/csrfAlan.cfm">
                        <input type="hidden" name="gorevAdi" value="odevKapat">
                        <button class="dugme dugme--ikincil" type="submit" name="gorevCalistir" value="1">Ödevleri Kapat</button>
                    </form>
                </div>

                <cfif len(gorevSonucu)>
                    <div class="ai-kutu ust-bosluk">
                        <div class="ai-kutu__baslik">Görev Çıktısı</div>
                        <div class="veri">#replace(encodeForHTML(gorevSonucu),chr(10),"<br>","all")#</div>
                    </div>
                </cfif>
            </div>
        </section>

        <section class="kart">
            <div class="kart__baslik">Hızlı Erişim</div>

            <div class="kart__govde">
                <div class="pano__eylem">
                    <a class="dugme dugme--ikincil" href="#application.kokYol#/views/yonetim/kullaniciOlusturma.cfm">Kullanıcılar</a>
                    <a class="dugme dugme--ikincil" href="#application.kokYol#/views/yonetim/uretimLog.cfm">Üretim Günlüğü</a>
                    <a class="dugme dugme--ikincil" href="#application.kokYol#/views/ogretmen/konuSecimi.cfm">Günlük Konular</a>
                    <a class="dugme dugme--ikincil" href="#application.kokYol#/views/sikayet/sikayet.cfm">Şikayetler<cfif val(qOzet.sikayet)> (#val(qOzet.sikayet)#)</cfif></a>
                </div>
            </div>
        </section>

        <cfif qSonHatalar.recordCount>
            <section class="kart">
                <div class="kart__baslik">Son Hatalar</div>

                <div class="tablo-sarmal">
                    <table class="tablo">
                        <thead>
                            <tr>
                                <th>Zaman:</th>
                                <th>Sayfa:</th>
                                <th>İşlem:</th>
                                <th>Mesaj:</th>
                            </tr>
                        </thead>

                        <tbody>
                            <cfloop query="qSonHatalar">
                                <tr>
                                    <td class="veri">#dateFormat(qSonHatalar.eklenmeTarihi,"dd.mm")# #timeFormat(qSonHatalar.eklenmeTarihi,"HH:mm")#</td>
                                    <td class="veri">#encodeForHTML(listLast(qSonHatalar.sayfa,"/"))#</td>
                                    <td>#encodeForHTML(qSonHatalar.islem)#</td>
                                    <td><span class="sessiz">#encodeForHTML(left(qSonHatalar.mesaj,100))#</span></td>
                                </tr>
                            </cfloop>
                        </tbody>
                    </table>
                </div>
            </section>
        </cfif>
    </div>
</cfoutput>

<cfinclude template="/lgs/views/includes/altBilgi.cfm">