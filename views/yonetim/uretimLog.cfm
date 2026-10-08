<cfset gerekliRoller=application.rol.mudur>
<cfinclude template="/lgs/views/includes/yetki.cfm">

<cfset sayfaBasligi="Üretim Günlüğü">

<cfquery name="qGunler" datasource="#application.DSN#">
    SELECT TOP 14 calismaTarihi,
           SUM(CASE WHEN durum='basarili' THEN 1 ELSE 0 END) AS basarili,
           SUM(CASE WHEN durum='hatali' THEN 1 ELSE 0 END) AS hatali
    FROM UretimLog
    GROUP BY calismaTarihi
    ORDER BY calismaTarihi DESC
</cfquery>

<cfquery name="qSonKayitlar" datasource="#application.DSN#">
    SELECT TOP 60 u.logID,u.calismaTarihi,u.calismaZamani,u.durum,u.hataMesaji,u.uretilenSoruID,
           d.dersAdi,k.konuAdi
    FROM UretimLog u
    LEFT JOIN Dersler d ON d.dersID=u.dersID
    LEFT JOIN Konular k ON k.konuID=u.konuID
    ORDER BY u.calismaZamani DESC
</cfquery>

<cfquery name="qEksikKonu" datasource="#application.DSN#">
    SELECT p.gunNo,d.dersID,d.dersAdi
    FROM DersProgrami p
    INNER JOIN Dersler d ON d.dersID=p.dersID
    WHERE p.gunNo=<cfqueryparam value="#dayOfWeek(dateAdd('d',1,now()))#" cfsqltype="cf_sql_tinyint">
    AND NOT EXISTS(
        SELECT 1 FROM GunlukKonuPlani g
        WHERE g.dersID=p.dersID
        AND g.planTarihi=CAST(DATEADD(DAY,1,GETDATE()) AS DATE)
    )
</cfquery>

<cfinclude template="/lgs/views/includes/baslik.cfm">

<cfoutput>
    <div class="yigin">
        <div class="baslik-satiri">
            <h2>Üretim Günlüğü</h2>
        </div>

        <cfif qEksikKonu.recordCount>
            <section class="kart mod-kutu">
                <div class="kart__baslik">Ertesi gün için konu seçilmemiş<span class="rozet rozet--yanlis">#qEksikKonu.recordCount#</span></div>

                <div class="kart__govde">
                    <p class="sessiz">Bu derslerde öğretmen konu seçmezse son kullanılan konu kullanılacak</p>

                    <div class="satir ust-bosluk">
                        <cfloop query="qEksikKonu">
                            <span class="rozet rozet--ders">#encodeForHTML(qEksikKonu.dersAdi)#</span>
                        </cfloop>
                    </div>
                </div>
            </section>
        </cfif>

        <section class="kart">
            <div class="kart__baslik">Son 14 Gün</div>

            <div class="tablo-sarmal">
                <table class="tablo">
                    <thead>
                        <tr>
                            <th>Tarih:</th>
                            <th>Başarıyla Tamamlanan:</th>
                            <th>Hatalı Oluşturulan:</th>
                            <th>Durum:</th>
                        </tr>
                    </thead>

                    <tbody>
                        <cfloop query="qGunler">
                            <tr<cfif val(qGunler.hatali)> class="pasif"</cfif>>
                                <td class="veri">#dateFormat(qGunler.calismaTarihi,"dd.mm.yyyy")#</td>
                                <td class="veri">#val(qGunler.basarili)#</td>
                                <td class="veri">#val(qGunler.hatali)#</td>

                                <td>
                                    <cfif val(qGunler.hatali) AND NOT val(qGunler.basarili)>
                                        <span class="rozet rozet--yanlis">Başarısız</span>
                                    <cfelseif val(qGunler.hatali)>
                                        <span class="rozet">Kısmi</span>
                                    <cfelse>
                                        <span class="rozet rozet--dogru">Tamam</span>
                                    </cfif>
                                </td>
                            </tr>
                        </cfloop>
                    </tbody>
                </table>
            </div>
        </section>

        <section class="kart">
            <div class="kart__baslik">Son Kayıtlar</div>

            <div class="tablo-sarmal">
                <table class="tablo">
                    <thead>
                        <tr>
                            <th>Zaman:</th>
                            <th>Ders:</th>
                            <th>Konu:</th>
                            <th>Durum:</th>
                            <th>Detay:</th>
                        </tr>
                    </thead>

                    <tbody>
                        <cfloop query="qSonKayitlar">
                            <tr<cfif qSonKayitlar.durum EQ "hatali"> class="pasif"</cfif>>
                                <td class="veri">#dateFormat(qSonKayitlar.calismaZamani,"dd.mm")# #timeFormat(qSonKayitlar.calismaZamani,"HH:mm")#</td>
                                <td>#encodeForHTML(qSonKayitlar.dersAdi)#</td>
                                <td>#encodeForHTML(qSonKayitlar.konuAdi)#</td>

                                <td>
                                    <cfif qSonKayitlar.durum EQ "basarili">
                                        <span class="rozet rozet--dogru">Başarılı</span>
                                    <cfelse>
                                        <span class="rozet rozet--yanlis">Hatalı</span>
                                    </cfif>
                                </td>

                                <td>
                                    <cfif val(qSonKayitlar.uretilenSoruID)>
                                        <a class="metin-dugme" href="#application.kokYol#/views/soru/soruDetay.cfm?id=#qSonKayitlar.uretilenSoruID#">Soruyu gör</a>
                                    <cfelseif len(qSonKayitlar.hataMesaji)>
                                        <span class="sessiz">#encodeForHTML(left(qSonKayitlar.hataMesaji,120))#</span>
                                    </cfif>
                                </td>
                            </tr>
                        </cfloop>
                    </tbody>
                </table>
            </div>
        </section>
    </div>
</cfoutput>

<cfinclude template="/lgs/views/includes/altBilgi.cfm">