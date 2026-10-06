<cfset gerekliRoller=application.rol.mudur>
<cfinclude template="/lgs/views/includes/yetki.cfm">

<cfset sayfaBasligi="Kullanıcı Yönetimi">
<cfset hataMesaji="">
<cfset basariMesaji="">
<cfset uretilenSifre="">
<cfset adDeger="">
<cfset kullaniciAdiDeger="">
<cfset rolDeger=application.rol.ogrenci>
<cfset bransDeger=0>
<cfset sifrelemeNesnesi=createObject("component","lgs.views.includes.sifreleme")>

<cfif structKeyExists(FORM,"gonder")>
    <cfset adDeger=trim(FORM.adSoyad)>
    <cfset kullaniciAdiDeger=trim(FORM.kullaniciAdi)>
    <cfset rolDeger=val(FORM.rol)>
    <cfset bransDeger=val(FORM.bransDersID)>

    <cfif NOT structKeyExists(FORM,"csrf") OR compare(FORM.csrf,SESSION.csrf) NEQ 0>
        <cfset hataMesaji="Oturum doğrulaması başarısız.Sayfayı yenileyip tekrar deneyiniz">
    <cfelseif NOT len(kullaniciAdiDeger)>
        <cfset hataMesaji="Kullanıcı adı zorunludur">
    <cfelseif NOT reFind("^[a-zA-Z0-9_]{3,50}$",kullaniciAdiDeger)>
        <cfset hataMesaji="Kullanıcı adı 3-50 karakter aralığında olmalı ve sadece harf,rakam ve alt çizgi içermelidir">
    <cfelseif NOT listFind("#application.rol.mudur#,#application.rol.ogretmen#,#application.rol.ogrenci#",rolDeger)>
        <cfset hataMesaji="Geçersiz rol seçimi">
    <cfelseif rolDeger EQ application.rol.ogretmen AND NOT bransDeger>
        <cfset hataMesaji="Öğretmen hesapları için branş seçimi zorunludur">
    <cfelse>
        <cfquery name="qVarMi" datasource="#application.DSN#">
            SELECT kullaniciID
            FROM Kullanicilar
            WHERE kullaniciAdi=<cfqueryparam value="#kullaniciAdiDeger#" cfsqltype="cf_sql_nvarchar">
        </cfquery>

        <cfif qVarMi.recordCount>
            <cfset hataMesaji="Bu kullanıcı adı zaten kullanılıyor">
        <cfelse>
            <cfset uretilenSifre=left(hash(createUUID(),"MD5"),8)>

            <cfquery datasource="#application.DSN#">
                INSERT INTO Kullanicilar(kullaniciAdi,adSoyad,sifreHash,rol,bransDersID,aktifMi)
                VALUES(
                <cfqueryparam value="#kullaniciAdiDeger#" cfsqltype="cf_sql_nvarchar">,
                <cfqueryparam value="#adDeger#" cfsqltype="cf_sql_nvarchar" null="#NOT len(adDeger)#">,
                <cfqueryparam value="#sifrelemeNesnesi.sifreHashle(uretilenSifre)#" cfsqltype="cf_sql_nvarchar">,
                <cfqueryparam value="#rolDeger#" cfsqltype="cf_sql_tinyint">,
                <cfqueryparam value="#bransDeger#" cfsqltype="cf_sql_integer" null="#(rolDeger NEQ application.rol.ogretmen OR NOT bransDeger)#">,
                1
                )
            </cfquery>

            <cfset basariMesaji="#kullaniciAdiDeger# kullanıcısı oluşturuldu">
            <cfset adDeger="">
            <cfset kullaniciAdiDeger="">
            <cfset bransDeger=0>
        </cfif>
    </cfif>
</cfif>

<cfif structKeyExists(FORM,"sifreYenile") AND structKeyExists(FORM,"hedefID")>
    <cfif structKeyExists(FORM,"csrf") AND compare(FORM.csrf,SESSION.csrf) EQ 0 AND val(FORM.hedefID)>
        <cfset uretilenSifre=left(hash(createUUID(),"MD5"),8)>

        <cfquery datasource="#application.DSN#">
            UPDATE Kullanicilar
            SET sifreHash=<cfqueryparam value="#sifrelemeNesnesi.sifreHashle(uretilenSifre)#" cfsqltype="cf_sql_nvarchar">
            WHERE kullaniciID=<cfqueryparam value="#val(FORM.hedefID)#" cfsqltype="cf_sql_integer">
            AND rol<><cfqueryparam value="#application.rol.ai#" cfsqltype="cf_sql_tinyint">
        </cfquery>

        <cfquery datasource="#application.DSN#">
            UPDATE Oturumlar
            SET aktifMi=0
            WHERE kullaniciID=<cfqueryparam value="#val(FORM.hedefID)#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfset basariMesaji="Yeni şifre oluşturuldu">
    </cfif>
</cfif>

<cfif structKeyExists(FORM,"durumDegistir") AND structKeyExists(FORM,"hedefID")>
    <cfif structKeyExists(FORM,"csrf") AND compare(FORM.csrf,SESSION.csrf) EQ 0 AND val(FORM.hedefID) AND val(FORM.hedefID) NEQ val(SESSION.kullaniciID)>
        <cfquery datasource="#application.DSN#">
            UPDATE Kullanicilar
            SET aktifMi=CASE WHEN aktifMi=1 THEN 0 ELSE 1 END
            WHERE kullaniciID=<cfqueryparam value="#val(FORM.hedefID)#" cfsqltype="cf_sql_integer">
            AND rol<><cfqueryparam value="#application.rol.ai#" cfsqltype="cf_sql_tinyint">
        </cfquery>

        <cfset basariMesaji="Hesap durumu güncellendi">
    </cfif>
</cfif>

<cfquery name="qKullanicilar" datasource="#application.DSN#">
    SELECT k.kullaniciID,k.kullaniciAdi,k.adSoyad,k.rol,k.aktifMi,k.sonGirisTarihi,d.dersAdi
    FROM Kullanicilar k
    LEFT JOIN Dersler d ON d.dersID=k.bransDersID
    ORDER BY k.rol,k.kullaniciAdi
</cfquery>

<cfinclude template="/lgs/views/includes/baslik.cfm">

<cfoutput>
    <div class="yigin">
        <cfif len(hataMesaji)>
            <div class="bildirim bildirim--hata" role="alert">#encodeForHTML(hataMesaji)#</div>
        </cfif>

        <cfif len(basariMesaji)>
            <div class="bildirim bildirim--basarili" role="status">
                #encodeForHTML(basariMesaji)#
                <cfif len(uretilenSifre)><span class="bildirim__xp">Şifre: #uretilenSifre#</span></cfif>
            </div>
        </cfif>

        <cfif len(uretilenSifre)>
            <div class="hedef-kutu">Bu şifre yalnızca şimdi görünür.Kaydetmeden önce sayfadan ayrılmayınız</div>
        </cfif>

        <section class="kart">
            <div class="kart__baslik">Yeni Kullanıcı</div>

            <div class="kart__govde">
                <form method="post" action="#cgi.script_name#">
                    <cfinclude template="/lgs/views/includes/csrfAlan.cfm">

                    <div class="alan">
                        <label for="kullaniciAdi">Kullanıcı Adı:</label>
                        <input class="girdi" type="text" id="kullaniciAdi" name="kullaniciAdi" value="#encodeForHTMLAttribute(kullaniciAdiDeger)#" maxlength="50" required>
                        <span class="alan__ipucu">Örnek: ogrenci01,ogretmen_mat</span>
                    </div>

                    <div class="alan">
                        <label for="adSoyad">Ad Soyad:</label>
                        <input class="girdi" type="text" id="adSoyad" name="adSoyad" value="#encodeForHTMLAttribute(adDeger)#" maxlength="100">
                    </div>

                    <div class="alan">
                        <label for="rol">Rol:</label>
                        <select class="secim" id="rol" name="rol">
                            <option value="#application.rol.ogrenci#"<cfif rolDeger EQ application.rol.ogrenci> selected</cfif>>Öğrenci</option>
                            <option value="#application.rol.ogretmen#"<cfif rolDeger EQ application.rol.ogretmen> selected</cfif>>Öğretmen</option>
                            <option value="#application.rol.mudur#"<cfif rolDeger EQ application.rol.mudur> selected</cfif>>Müdür</option>
                        </select>
                    </div>

                    <div class="alan">
                        <label for="bransDersID">Branş:</label>
                        <select class="secim" id="bransDersID" name="bransDersID">
                            <option value="0">Seçiniz</option>
                            <cfloop query="application.qDers">
                                <option value="#application.qDers.dersID#"<cfif bransDeger EQ application.qDers.dersID> selected</cfif>>#encodeForHTML(application.qDers.dersAdi)#</option>
                            </cfloop>
                        </select>
                        <span class="alan__ipucu">Yalnızca öğretmen hesapları için gereklidir</span>
                    </div>

                    <button class="dugme dugme--ana dugme--tam" type="submit" name="gonder" value="1">Kullanıcı Oluştur</button>
                </form>
            </div>
        </section>

        <section class="kart">
            <div class="kart__baslik">Kullanıcılar<span class="rozet">#qKullanicilar.recordCount#</span></div>

            <div class="tablo-sarmal">
                <table class="tablo">
                    <thead>
                        <tr>
                            <th>Kullanıcı Adı:</th>
                            <th>Ad Soyad:</th>
                            <th>Rol:</th>
                            <th>Branş:</th>
                            <th>Son Giriş:</th>
                            <th>Durum:</th>
                            <th>İşlem:</th>
                        </tr>
                    </thead>

                    <tbody>
                        <cfloop query="qKullanicilar">
                            <tr<cfif NOT qKullanicilar.aktifMi> class="pasif"</cfif>>
                                <td>#encodeForHTML(qKullanicilar.kullaniciAdi)#</td>
                                <td>#encodeForHTML(qKullanicilar.adSoyad)#</td>

                                <td>
                                    <cfswitch expression="#val(qKullanicilar.rol)#">
                                        <cfcase value="#application.rol.mudur#">Müdür</cfcase>
                                        <cfcase value="#application.rol.ogretmen#">Öğretmen</cfcase>
                                        <cfcase value="#application.rol.ogrenci#">Öğrenci</cfcase>
                                        <cfdefaultcase>Sistem</cfdefaultcase>
                                    </cfswitch>
                                </td>

                                <td>#encodeForHTML(qKullanicilar.dersAdi)#</td>

                                <td class="veri">
                                    <cfif len(qKullanicilar.sonGirisTarihi)>#dateFormat(qKullanicilar.sonGirisTarihi,"dd.mm.yyyy")#<cfelse>-</cfif>
                                </td>

                                <td>
                                    <cfif qKullanicilar.aktifMi>
                                        <span class="rozet rozet--aktif">Aktif</span>
                                    <cfelse>
                                        <span class="rozet rozet--pasif">Pasif</span>
                                    </cfif>
                                </td>

                                <td>
                                    <cfif val(qKullanicilar.rol) NEQ application.rol.ai>
                                        <div class="tablo__eylem">
                                            <form method="post" action="#cgi.script_name#">
                                                <cfinclude template="/lgs/views/includes/csrfAlan.cfm">
                                                <input type="hidden" name="hedefID" value="#qKullanicilar.kullaniciID#">
                                                <button class="dugme dugme--kucuk dugme--ikincil" type="submit" name="sifreYenile" value="1">Şifre Yenile</button>
                                            </form>

                                            <cfif val(qKullanicilar.kullaniciID) NEQ val(SESSION.kullaniciID)>
                                                <form method="post" action="#cgi.script_name#">
                                                    <cfinclude template="/lgs/views/includes/csrfAlan.cfm">
                                                    <input type="hidden" name="hedefID" value="#qKullanicilar.kullaniciID#">
                                                    <button class="dugme dugme--kucuk <cfif qKullanicilar.aktifMi>dugme--red<cfelse>dugme--onay</cfif>" type="submit" name="durumDegistir" value="1"><cfif qKullanicilar.aktifMi>Pasifleştir<cfelse>Aktifleştir</cfif></button>
                                                </form>
                                            </cfif>
                                        </div>
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