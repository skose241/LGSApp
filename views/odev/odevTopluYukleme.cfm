<cfset gerekliRoller="#application.rol.ogretmen#,#application.rol.mudur#">
<cfinclude template="/lgs/views/includes/yetki.cfm">

<cfparam name="URL.odevID" default="0">
<cfset odevID=val(URL.odevID)>
<cfset hataMesaji="">
<cfset basariMesaji="">

<cfquery name="qOdev" datasource="#application.DSN#">
    SELECT o.odevID,o.ogretmenID,o.dersID,o.baslik,o.baslangicTarihi,o.bitisTarihi,o.durum,d.dersAdi
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

<cfif qOdev.durum NEQ application.odevDurum.taslak>
    <cflocation url="#application.kokYol#/views/odev/odevDetay.cfm?odevID=#odevID#" addtoken="false">
</cfif>

<cfif structKeyExists(FORM,"yukle")>
    <cfset eklenen=0>
    <cfset basarisiz=0>

    <cfif NOT structKeyExists(FORM,"csrf") OR compare(FORM.csrf,SESSION.csrf) NEQ 0>
        <cfset hataMesaji="Oturum doğrulaması başarısız">
    <cfelse>
        <cfif NOT directoryExists(application.odevGorselDizin)>
            <cfdirectory action="create" directory="#application.odevGorselDizin#">
        </cfif>

        <cfquery name="qSonSira" datasource="#application.DSN#">
            SELECT ISNULL(MAX(siraNo),0) AS sonSira
            FROM OdevSorulari
            WHERE odevID=<cfqueryparam value="#odevID#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfset siraSayac=val(qSonSira.sonSira)>

        <cfloop from="1" to="20" index="i">
            <cfif structKeyExists(FORM,"gorsel#i#") AND len(trim(FORM["gorsel" & i])) AND structKeyExists(FORM,"cevap#i#") AND listFind("A,B,C,D",ucase(trim(FORM["cevap" & i])))>
                <cfset dosyaAdi="">

                <cftry>
                    <cffile action="upload" fileField="gorsel#i#" destination="#application.odevGorselDizin#" nameConflict="makeunique" accept="image/jpeg,image/png,image/webp" strict="true" result="yukleme">
                    <cfset dosyaAdi=yukleme.serverFile>

                    <cfif NOT listFindNoCase("jpg,jpeg,png,webp",yukleme.serverFileExt)>
                        <cffile action="delete" file="#application.odevGorselDizin##dosyaAdi#">
                        <cfthrow message="Geçersiz dosya türü">
                    </cfif>

                    <cfset yeniAd="odev_" & odevID & "_" & dateFormat(now(),"yyyymmdd") & "_" & left(hash(createUUID(),"MD5"),8) & "." & lcase(yukleme.serverFileExt)>
                    <cffile action="rename" source="#application.odevGorselDizin##dosyaAdi#" destination="#application.odevGorselDizin##yeniAd#">
                    <cfset dosyaAdi=yeniAd>

                    <cfimage action="read" source="#application.odevGorselDizin##dosyaAdi#" name="gorsel">

                    <cfif imageGetWidth(gorsel) GT 800>
                        <cfset imageResize(gorsel,800,"")>
                        <cfimage action="write" source="#gorsel#" destination="#application.odevGorselDizin##dosyaAdi#" overwrite="true" quality=".8">
                    </cfif>

                    <cftransaction>
                        <cfquery datasource="#application.DSN#" result="soruSonuc">
                            INSERT INTO Sorular(kullaniciID,dersID,soruGorsel,dogruCevap,kaynak,yayinlandiMi,aktifMi)
                            VALUES(
                            <cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#val(qOdev.dersID)#" cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#dosyaAdi#" cfsqltype="cf_sql_nvarchar">,
                            <cfqueryparam value="#ucase(trim(FORM['cevap' & i]))#" cfsqltype="cf_sql_nchar">,
                            <cfqueryparam value="#application.kaynak.ogretmen#" cfsqltype="cf_sql_tinyint">,
                            1,
                            1
                            )
                        </cfquery>

                        <cfquery datasource="#application.DSN#">
                            INSERT INTO OdevSorulari(odevID,soruID,siraNo)
                            VALUES(
                            <cfqueryparam value="#odevID#" cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#val(soruSonuc.generatedKey)#" cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#siraSayac+1#" cfsqltype="cf_sql_integer">
                            )
                        </cfquery>
                    </cftransaction>

                    <cfset siraSayac=siraSayac+1>
                    <cfset eklenen=eklenen+1>

                    <cfcatch type="any">
                        <cfif len(dosyaAdi) AND fileExists("#application.odevGorselDizin##dosyaAdi#")>
                            <cffile action="delete" file="#application.odevGorselDizin##dosyaAdi#">
                        </cfif>

                        <cfset createObject("component","lgs.ai").hataYazma(
                            sayfa=cgi.script_name,
                            islem="odevTopluYukleme",
                            mesaj="Ödev #odevID# görsel #i#: #cfcatch.message#",
                            detay=cfcatch.detail
                            )>

                        <cfset basarisiz=basarisiz+1>
                    </cfcatch>
                </cftry>
            </cfif>
        </cfloop>

        <cfif eklenen>
            <cfset basariMesaji="#eklenen# soru eklendi">
        </cfif>

        <cfif basarisiz>
            <cfset hataMesaji="#basarisiz# soru eklenemedi">
        </cfif>

        <cfif NOT eklenen AND NOT basarisiz>
            <cfset hataMesaji="Görsel seçip doğru cevap işaretlemelisiniz">
        </cfif>
    </cfif>
</cfif>

<cfif structKeyExists(FORM,"yayinla")>
    <cfquery name="qSoruSayi" datasource="#application.DSN#">
        SELECT COUNT(*) AS adet
        FROM OdevSorulari
        WHERE odevID=<cfqueryparam value="#odevID#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfif NOT structKeyExists(FORM,"csrf") OR compare(FORM.csrf,SESSION.csrf) NEQ 0>
        <cfset hataMesaji="Oturum doğrulaması başarısız">
    <cfelseif NOT val(qSoruSayi.adet)>
        <cfset hataMesaji="Yayınlamadan önce en az bir soru eklemelisiniz">
    <cfelse>
        <cfset yeniDurum=application.odevDurum.planlandi>

        <cfif dateCompare(qOdev.baslangicTarihi,now(),"d") LTE 0>
            <cfset yeniDurum=application.odevDurum.yayinda>
        </cfif>

        <cfquery datasource="#application.DSN#">
            UPDATE Odevler
            SET durum=<cfqueryparam value="#yeniDurum#" cfsqltype="cf_sql_nvarchar">
            WHERE odevID=<cfqueryparam value="#odevID#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfif yeniDurum EQ application.odevDurum.yayinda>
            <cfquery name="qOgrenciler" datasource="#application.DSN#">
                SELECT kullaniciID
                FROM Kullanicilar
                WHERE rol=<cfqueryparam value="#application.rol.ogrenci#" cfsqltype="cf_sql_tinyint">
                AND aktifMi=1
            </cfquery>

            <cfloop query="qOgrenciler">
                <cfquery datasource="#application.DSN#">
                    INSERT INTO Bildirimler(kullaniciID,bildirimTipi,mesaj,hedefURL)
                    VALUES(
                    <cfqueryparam value="#val(qOgrenciler.kullaniciID)#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="odev" cfsqltype="cf_sql_nvarchar">,
                    <cfqueryparam value="#qOdev.dersAdi# dersinden yeni bir ödev yayınlandı" cfsqltype="cf_sql_nvarchar">,
                    <cfqueryparam value="#application.kokYol#/views/odev/odevDetay.cfm?odevID=#odevID#" cfsqltype="cf_sql_nvarchar">
                    )
                </cfquery>
            </cfloop>
        </cfif>

        <cflocation url="#application.kokYol#/views/odev/odevListesi.cfm?yayinlandi=1" addtoken="false">
    </cfif>
</cfif>

<cfquery name="qEklenenler" datasource="#application.DSN#">
    SELECT os.siraNo,s.soruID,s.soruGorsel,s.dogruCevap
    FROM OdevSorulari os
    INNER JOIN Sorular s ON s.soruID=os.soruID
    WHERE os.odevID=<cfqueryparam value="#odevID#" cfsqltype="cf_sql_integer">
    ORDER BY os.siraNo
</cfquery>

<cfset sayfaBasligi="Ödeve Yükleme">

<cfinclude template="/lgs/views/includes/baslik.cfm">

<cfoutput>
    <div class="yigin">

        <cfif len(hataMesaji)>
            <div class="bildirim bildirim--hata" role="alert">#encodeForHTML(hataMesaji)#</div>
        </cfif>

        <cfif len(basariMesaji)>
            <div class="bildirim bildirim--basarili" role="status">#encodeForHTML(basariMesaji)#</div>
        </cfif>

        <section class="kart">
            <div class="kart__baslik">
                #encodeForHTML(len(qOdev.baslik) ? qOdev.baslik : qOdev.dersAdi)#
                <span class="rozet">#dateFormat(qOdev.baslangicTarihi,"dd.mm")# - #dateFormat(qOdev.bitisTarihi,"dd.mm")#</span>
            </div>

            <div class="kart__govde">
                <form method="post" action="#cgi.script_name#?odevID=#odevID#" enctype="multipart/form-data">
                    <cfinclude template="/lgs/views/includes/csrfAlan.cfm">

                    <div class="alan">
                        <label for="topluDosya">Soru Fotoğrafları:</label>

                        <div class="dosya-alan">
                            <input type="file" id="topluDosya" accept="image/jpeg,image/png,image/webp" multiple>
                            <div class="dosya-alan__simge">+</div>
                            <div class="dosya-alan__baslik">Fotoğrafları tek seferde seçiniz</div>
                            <div class="dosya-alan__ipucu">En fazla 20 adet,jpg png veya webp</div>
                        </div>
                    </div>

                    <div id="topluListe"></div>

                    <button class="dugme dugme--ana dugme--tam" type="submit" name="yukle" value="1" id="topluGonder" disabled>Soruları Yükle</button>
                </form>
            </div>
        </section>

        <cfif qEklenenler.recordCount>
            <section class="kart">
                <div class="kart__baslik">Eklenen Sorular:<span class="rozet">#qEklenenler.recordCount#</span></div>

                <div class="kart__govde">
                    <div class="soru-izgara">
                        <cfloop query="qEklenenler">
                            <div class="soru-kutu">
                                <img
                                    class="soru-kutu__gorsel" src="#application.odevGorselYol##qEklenenler.soruGorsel#" alt="Soru #qEklenenler.siraNo#">

                                <div class="soru-kutu__govde">
                                    <div class="soru-kutu__alt">
                                        <span class="rozet">#qEklenenler.siraNo#</span>
                                        <span class="rozet rozet--dogru">#qEklenenler.dogruCevap#</span>
                                    </div>
                                </div>
                            </div>
                        </cfloop>
                    </div>
                </div>

                <div class="kart__ayrac">
                    <form method="post" action="#cgi.script_name#?odevID=#odevID#">
                        <cfinclude template="/lgs/views/includes/csrfAlan.cfm">
                        <button class="dugme dugme--ana dugme--tam" type="submit" name="yayinla" value="1">Ödevi Yayınla</button>
                    </form>
                </div>
            </section>
        </cfif>
    </div>
</cfoutput>

<cfinclude template="/lgs/views/includes/altBilgi.cfm">