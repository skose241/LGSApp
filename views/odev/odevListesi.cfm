<cfinclude template="/lgs/views/includes/yetki.cfm">

<cfset sayfaBasligi="Ödevler">
<cfset ogretmenMi=(val(SESSION.rol) EQ application.rol.ogretmen OR val(SESSION.rol) EQ application.rol.mudur)>

<cfif ogretmenMi>
    <cfquery name="qOdevler" datasource="#application.DSN#">
        SELECT o.odevID,o.baslik,o.baslangicTarihi,o.bitisTarihi,o.durum,d.dersAdi,
               (SELECT COUNT(*) FROM OdevSorulari os WHERE os.odevID=o.odevID) AS soruSayisi,
               (SELECT COUNT(DISTINCT oc.kullaniciID) FROM OdevCevaplari oc WHERE oc.odevID=o.odevID) AS katilimci
        FROM Odevler o
        INNER JOIN Dersler d ON d.dersID=o.dersID
        <cfif val(SESSION.rol) EQ application.rol.ogretmen>
            WHERE o.ogretmenID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
        </cfif>
        ORDER BY CASE WHEN o.durum=N'yayinda' THEN 0 ELSE 1 END,o.bitisTarihi DESC
    </cfquery>
<cfelse>
    <cfquery name="qOdevler" datasource="#application.DSN#">
        SELECT o.odevID,o.baslik,o.baslangicTarihi,o.bitisTarihi,o.durum,d.dersAdi,
               (SELECT COUNT(*) FROM OdevSorulari os WHERE os.odevID=o.odevID) AS soruSayisi,
               (SELECT COUNT(*) FROM OdevCevaplari oc WHERE oc.odevID=o.odevID AND oc.kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">) AS cevapladigim
        FROM Odevler o
        INNER JOIN Dersler d ON d.dersID=o.dersID
        WHERE o.durum IN (<cfqueryparam value="#application.odevDurum.yayinda#" cfsqltype="cf_sql_nvarchar">,<cfqueryparam value="#application.odevDurum.kapandi#" cfsqltype="cf_sql_nvarchar">)
        ORDER BY CASE WHEN o.durum=N'yayinda' THEN 0 ELSE 1 END,o.bitisTarihi DESC
    </cfquery>
</cfif>

<cfinclude template="/lgs/views/includes/baslik.cfm">

<cfoutput>
    <div class="yigin">
        <cfif structKeyExists(URL,"yayinlandi")>
            <div class="bildirim bildirim--basarili" role="status">Ödev Yayınlandı</div>
        </cfif>

        <cfif structKeyExists(URL,"hata")>
            <div class="bildirim bildirim--hata" role="alert">Bu işlem için yetkiniz bulunmuyor</div>
        </cfif>

        <div class="baslik-satiri">
            <h2>Ödevler</h2>

            <cfif ogretmenMi>
                <a class="dugme dugme--ana" href="#application.kokYol#/views/odev/odevOlusturma.cfm">Yeni Ödev</a>
            </cfif>
        </div>

        <cfif qOdevler.recordCount>
            <cfloop query="qOdevler">
                <section class="kart">
                    <div class="kart__baslik">
                        #encodeForHTML(len(qOdevler.baslik) ? qOdevler.baslik : qOdevler.dersAdi)#

                        <cfswitch expression="#qOdevler.durum#">
                            <cfcase value="#application.odevDurum.taslak#"><span class="rozet rozet--pasif">Taslakta</span></cfcase>
                            <cfcase value="#application.odevDurum.planlandi#"><span class="rozet">İleri tarihe planlandı</span></cfcase>
                            <cfcase value="#application.odevDurum.yayinda#"><span class="rozet rozet--aktif">Açık</span></cfcase>
                            <cfdefaultcase><span class="rozet rozet--pasif">Kapandı</span></cfdefaultcase>
                        </cfswitch>
                    </div>

                    <div class="kart__govde">
                        <div class="soru__ust">
                            <span class="rozet rozet--ders">#encodeForHTML(qOdevler.dersAdi)#</span>
                            <span class="sessiz">#dateFormat(qOdevler.baslangicTarihi,"dd.mm.yyyy")# - #dateFormat(qOdevler.bitisTarihi,"dd.mm.yyyy")#</span>
                        </div>

                        <div class="dip-not">
                            <span>Soru: <b>#val(qOdevler.soruSayisi)#</b></span>

                            <cfif ogretmenMi>
                                <span>Katılan: <b>#val(qOdevler.katilimci)#</b></span>
                            <cfelse>
                                <span>Çözdüğünüz: <b>#val(qOdevler.cevapladigim)#</b></span>
                            </cfif>
                        </div>

                        <div class="pano__eylem">
                            <cfif ogretmenMi AND qOdevler.durum EQ application.odevDurum.taslak>
                                <a class="dugme dugme--ana" href="#application.kokYol#/views/odev/odevTopluYukleme.cfm?odevID=#qOdevler.odevID#">Soru Ekle ve Yayınla</a>
                            <cfelse>
                                <a class="dugme dugme--ikincil" href="#application.kokYol#/views/odev/odevDetay.cfm?odevID=#qOdevler.odevID#">
                                    <cfif ogretmenMi>Soruları Gör<cfelseif qOdevler.durum EQ application.odevDurum.kapandi>Görüntüle<cfelseif val(qOdevler.cevapladigim)>Devam Et<cfelse>Başla</cfif>
                                </a>
                            </cfif>

                            <cfif ogretmenMi AND qOdevler.durum NEQ application.odevDurum.taslak>
                                <a class="dugme dugme--sade" href="#application.kokYol#/views/odev/odevKatilim.cfm?odevID=#qOdevler.odevID#">Katılım</a>
                            </cfif>
                        </div>
                    </div>
                </section>
            </cfloop>
        <cfelse>
            <div class="bos-durum">
                <div class="bos-durum__daire"></div>
                <h3>Henüz ödev yok</h3>
                <p class="sessiz"><cfif ogretmenMi>Yeni ödev oluşturarak başlayabilirsiniz<cfelse>Öğretmenleriniz ödev yayınladığında burada görünecek</cfif></p>
            </div>
        </cfif>
    </div>
</cfoutput>

<cfinclude template="/lgs/views/includes/altBilgi.cfm">