<cfset gerekliRoller="#application.rol.ogretmen#,#application.rol.mudur#">
<cfinclude template="/lgs/views/includes/yetki.cfm">

<cfset sayfaBasligi="Günlük Soru Konuları">
<cfset hataMesaji="">
<cfset basariMesaji="">
<cfset mudurMu=(val(SESSION.rol) EQ application.rol.mudur)>
<cfset bransDersID=val(SESSION.bransDersID)>
<cfset gunSayisi=7>
<cfset sonSecimSaati=16*60+45>
<cfset suankiSaat=hour(now())*60+minute(now())>

<cfif NOT mudurMu AND NOT bransDersID>
    <cfset hataMesaji="Hesabınıza branş tanımlanmamış.Yönetime başvurunuz">
</cfif>

<cfif structKeyExists(FORM,"kaydet")>
    <cfset eklenen=0>

    <cfif NOT structKeyExists(FORM,"csrf") OR compare(FORM.csrf,SESSION.csrf) NEQ 0>
        <cfset hataMesaji="Oturum doğrulaması başarısız">
    <cfelse>
        <cfloop from="0" to="#gunSayisi-1#" index="g">
            <cfset hedefTarih=dateFormat(dateAdd("d",g,now()),"yyyy-mm-dd")>

            <cfloop query="application.qDers">
                <cfset alanAdi="konu_" & g & "_" & application.qDers.dersID>

                <cfif structKeyExists(FORM,alanAdi) AND val(FORM[alanAdi])>
                    <cfif mudurMu OR val(application.qDers.dersID) EQ bransDersID>
                        <cfset gecmisMi=(suankiSaat GTE sonSecimSaati)>

                        <cfif NOT gecmisMi>
                            <cfquery datasource="#application.DSN#">
                                MERGE GunlukKonuPlani AS hedef
                                USING (SELECT
                                    <cfqueryparam value="#hedefTarih#" cfsqltype="cf_sql_date"> AS planTarihi,
                                    <cfqueryparam value="#val(application.qDers.dersID)#" cfsqltype="cf_sql_integer"> AS dersID,
                                    <cfqueryparam value="#val(FORM[alanAdi])#" cfsqltype="cf_sql_integer"> AS konuID
                                ) AS kaynak
                                ON hedef.planTarihi=kaynak.planTarihi AND hedef.dersID=kaynak.dersID
                                WHEN MATCHED AND hedef.kullanildiMi=0 THEN
                                    UPDATE SET konuID=kaynak.konuID
                                WHEN NOT MATCHED THEN
                                    INSERT(planTarihi,dersID,konuID,kullanildiMi)
                                    VALUES(kaynak.planTarihi,kaynak.dersID,kaynak.konuID,0);
                            </cfquery>

                            <cfset eklenen=eklenen+1>
                        </cfif>
                    </cfif>
                </cfif>
            </cfloop>
        </cfloop>

        <cfif eklenen>
            <cfset basariMesaji="#eklenen# gün için konu kaydedildi">
        <cfelse>
            <cfset hataMesaji="Kaydedilecek konu seçimi bulunamadı">
        </cfif>
    </cfif>
</cfif>

<cfquery name="qProgram" datasource="#application.DSN#">
    SELECT p.gunNo,p.dersID,p.soruSayisi,d.dersAdi
    FROM DersProgrami p
    INNER JOIN Dersler d ON d.dersID=p.dersID
    WHERE d.aktifMi=1
    <cfif NOT mudurMu AND bransDersID>
        AND p.dersID=<cfqueryparam value="#bransDersID#" cfsqltype="cf_sql_integer">
    </cfif>
    ORDER BY p.gunNo,d.siraNo
</cfquery>

<cfquery name="qSecilenler" datasource="#application.DSN#">
    SELECT g.planTarihi,g.dersID,g.konuID,g.kullanildiMi,k.konuAdi
    FROM GunlukKonuPlani g
    INNER JOIN Konular k ON k.konuID=g.konuID
    WHERE g.planTarihi>=CAST(GETDATE() AS DATE)
    AND g.planTarihi<=DATEADD(DAY,<cfqueryparam value="#gunSayisi-1#" cfsqltype="cf_sql_integer">,CAST(GETDATE() AS DATE))
</cfquery>

<cfset carpan=val(application.ayar.soruCarpani)>

<cfinclude template="/lgs/views/includes/baslik.cfm">

<cfoutput>
    <div class="yigin">
        <cfif len(hataMesaji)>
            <div class="bildirim bildirim--hata" role="alert">#encodeForHTML(hataMesaji)#</div>
        </cfif>

        <cfif len(basariMesaji)>
            <div class="bildirim bildirim--basarili" role="status">#encodeForHTML(basariMesaji)#</div>
        </cfif>

        <div class="baslik-satiri">
            <h2>Günlük Soru Konuları</h2>
        </div>

        <p class="sessiz">Yapay zeka her gün saat 17:30'da,seçtiğiniz konudan soru üretir ve akşam 19:00'da yayınlar.Bugün için seçiminizi 16:45'e kadar yapmalısınız.Konu seçilmezse o dersin en son kullanılan konusu kullanılır</p>

        <form method="post" action="#cgi.script_name#">
            <cfinclude template="/lgs/views/includes/csrfAlan.cfm">

            <cfloop from="0" to="#gunSayisi-1#" index="g">
                <cfset buTarih=dateAdd("d",g,now())>
                <cfset buGunNo=dayOfWeek(buTarih)>

                <cfquery name="qGunDersleri" dbtype="query">
                    SELECT dersID,dersAdi,soruSayisi
                    FROM qProgram
                    WHERE gunNo=#buGunNo#
                </cfquery>

                <cfif qGunDersleri.recordCount>
                    <section class="kart">
                        <div class="kart__baslik">
                            #dateFormat(buTarih,"dd.mm.yyyy")# #listGetAt(gunAdlari,buGunNo)#

                            <cfif g EQ 0>
                                <cfif suankiSaat GTE sonSecimSaati>
                                    <span class="rozet rozet--pasif">Süre doldu</span>
                                <cfelse>
                                    <span class="rozet rozet--aktif">Bugün:</span>
                                </cfif>
                            </cfif>
                        </div>

                        <div class="kart__govde">
                            <cfloop query="qGunDersleri">
                                <cfset uretilecek=ceiling(val(qGunDersleri.soruSayisi)*carpan)>

                                <cfquery name="qMevcut" dbtype="query">
                                    SELECT konuID,konuAdi,kullanildiMi
                                    FROM qSecilenler
                                    WHERE dersID=#val(qGunDersleri.dersID)#
                                    AND planTarihi=#createODBCDate(buTarih)#
                                </cfquery>

                                <cfquery name="qDersKonulari" dbtype="query">
                                    SELECT konuID,konuAdi
                                    FROM application.qKonu
                                    WHERE dersID=#val(qGunDersleri.dersID)#
                                    ORDER BY siraNo
                                </cfquery>

                                <div class="alan">
                                    <label for="konu_#g#_#qGunDersleri.dersID#">
                                        #encodeForHTML(qGunDersleri.dersAdi)#
                                        <span class="rozet">#uretilecek# soru</span>

                                        <cfif qMevcut.recordCount AND qMevcut.kullanildiMi>
                                            <span class="rozet rozet--pasif">Üretildi</span>
                                        </cfif>
                                    </label>

                                    <select class="secim" id="konu_#g#_#qGunDersleri.dersID#" name="konu_#g#_#qGunDersleri.dersID#"<cfif (g EQ 0 AND suankiSaat GTE sonSecimSaati) OR (qMevcut.recordCount AND qMevcut.kullanildiMi)> disabled</cfif>>
                                        <option value="0">Seçilmedi</option>

                                        <cfloop query="qDersKonulari">
                                            <option value="#qDersKonulari.konuID#"<cfif qMevcut.recordCount AND val(qMevcut.konuID) EQ val(qDersKonulari.konuID)> selected</cfif>>#encodeForHTML(qDersKonulari.konuAdi)#</option>
                                        </cfloop>
                                    </select>
                                </div>
                            </cfloop>
                        </div>
                    </section>
                </cfif>
            </cfloop>
            <button class="dugme dugme--ana dugme--tam" type="submit" name="kaydet" value="1">Konuları Kaydet</button>
        </form>
    </div>
</cfoutput>

<cfinclude template="/lgs/views/includes/altBilgi.cfm">