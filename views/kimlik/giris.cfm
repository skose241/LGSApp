<cfparam name="URL.donus" default="">
<cfparam name="URL.hata" default="">

<cfif structKeyExists(SESSION,"kullaniciID") AND val(SESSION.kullaniciID)>
    <cflocation url="#application.kokYol#/anaSayfa.cfm" addtoken="false">
</cfif>

<cfset hataMesaji="">
<cfset kullaniciAdiDeger="">

<cfif structKeyExists(FORM,"gonder")>
    <cfset kullaniciAdiDeger=trim(FORM.kullaniciAdi)>

    <cfif NOT structKeyExists(FORM,"csrf") OR NOT structKeyExists(SESSION,"csrf") OR compare(FORM.csrf,SESSION.csrf) NEQ 0>
        <cfset hataMesaji="Oturum doğrulaması başarısız.Sayfayı yenileyip tekrar deneyiniz">
    <cfelseif NOT len(kullaniciAdiDeger) OR NOT len(trim(FORM.sifre))>
        <cfset hataMesaji="Kullanıcı adı ve şifre zorunludur">
    <cfelse>
        <cfquery name="qKullanici" datasource="#application.DSN#">
            SELECT kullaniciID,kullaniciAdi,sifreHash,rol,puan,bransDersID
            FROM Kullanicilar
            WHERE kullaniciAdi=<cfqueryparam value="#kullaniciAdiDeger#" cfsqltype="cf_sql_nvarchar">
            AND aktifMi=1
        </cfquery>

        <cfset sifrelemeNesnesi=createObject("component","lgs.views.includes.sifreleme")>
        <cfif qKullanici.recordCount AND sifrelemeNesnesi.sifreDogrula(FORM.sifre,qKullanici.sifreHash)>
            <cfset sessionRotate()>
            <cfset SESSION.kullaniciID=val(qKullanici.kullaniciID)>
            <cfset SESSION.kullaniciAd=qKullanici.kullaniciAdi>
            <cfset SESSION.rol=val(qKullanici.rol)>
            <cfset SESSION.puan=val(qKullanici.puan)>
            <cfset SESSION.bransDersID=val(qKullanici.bransDersID)>
            <cfset SESSION.csrf=hash(createUUID() & getTickCount(),"SHA-256")>

            <cfquery datasource="#application.DSN#">
                UPDATE Kullanicilar
                SET sonGirisTarihi=GETDATE()
                WHERE kullaniciID=<cfqueryparam value="#val(qKullanici.kullaniciID)#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfif structKeyExists(FORM,"beniHatirla") AND FORM.beniHatirla EQ "1">
                <cfset oturumToken=sifrelemeNesnesi.tokenUret()>
                <cfquery datasource="#application.DSN#">
                    INSERT INTO Oturumlar(kullaniciID,sessionToken,girisTarihi,sonGoruldu,aktifMi)
                    VALUES(
                    <cfqueryparam value="#val(qKullanici.kullaniciID)#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#oturumToken#" cfsqltype="cf_sql_nvarchar">,
                    GETDATE(),
                    GETDATE(),
                    1
                    )
                </cfquery>

                <cfcookie name="beniHatirla" value="#oturumToken#" expires="30" httponly="true" secure="true">
            </cfif>

            <cfif reFind("^/[^/\\]",URL.donus)>
                <cflocation url="#URL.donus#" addtoken="false">
            <cfelse>
                <cflocation url="#application.kokYol#/anaSayfa.cfm" addtoken="false">
            </cfif>
        <cfelse>
            <cfset hataMesaji="Kullanıcı adı veya şifre hatalı">
        </cfif>
    </cfif>
</cfif>

<cfinclude template="/lgs/views/includes/baslik.cfm">

<cfoutput>
    <div class="dar">
        <section class="kart">
            <div class="kart__govde">
                <h1 baslik>Giriş Yap</h1>

                <cfif len(hataMesaji)>
                    <div class="bildirim bildirim--hata" role="alert">#hataMesaji#</div>
                </cfif>

                <cfif URL.hata EQ "yetkisiz">
                    <div class="bildirim bildirim--hata" role="alert">Bu sayfaya erişim yetkiniz bulunmuyor</div>
                </cfif>

                <form method="post" action="#cgi.script_name#<cfif len(trim(URL.donus))>?donus=#urlEncodedFormat(URL.donus)#</cfif>">
                    <cfinclude template="/lgs/views/includes/csrfAlan.cfm">

                    <div class="alan">
                        <label etiket for="kullaniciAdi">Kullanıcı Adı:</label>
                        <input class="girdi" type="text" id="kullaniciAdi" name="kullaniciAdi" value="#encodeForHTMLAttribute(kullaniciAdiDeger)#" maxlength="50" autocomplete="username" required>
                    </div>

                    <div class="alan">
                        <label etiket for="sifre">Şifre</label>
                        <input class="girdi" type="password" id="sifre" name="sifre" maxlength="100" autocomplete="current-password" required>
                    </div>

                    <div class="alan">
                        <label class="onay">
                            <input type="checkbox" name="beniHatirla" value="1"> Beni Hatırla
                        </label>
                    </div>

                    <button class="dugme dugme--ana dugme--tam" type="submit" name="gonder" value="1">Giriş Yap</button>
                </form>

                <p class="sessiz ust-bosluk">Hesabınızla ilgili sorun yaşıyorsanız okul yönetimine başvurunuz</p>
            </div>
        </section>
    </div>
</cfoutput>

<cfinclude template="/lgs/views/includes/altBilgi.cfm">