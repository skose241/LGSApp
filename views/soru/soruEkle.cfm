<cfset gerekliRoller="#application.rol.ogrenci#,#application.rol.ogretmen#,#application.rol.mudur#">
<cfinclude template="/lgs/views/includes/yetki.cfm">

<cfset sayfaBasligi="Soru Ekle">
<cfset hataMesaji="">
<cfset dersDeger=0>
<cfset aciklamaDeger="">
<cfset dogruCevapDeger="">
<cfset minKarakter=val(application.ayar.aciklamaMinKarakter)>
<cfset yuklemeKlasoru=application.soruGorselDizin>

<cfif structKeyExists(FORM,"gonder")>
    <cfset dersDeger=val(FORM.dersID)>
    <cfset aciklamaDeger=trim(FORM.aciklama)>
    <cfset dogruCevapDeger=ucase(trim(FORM.dogruCevap))>
    <cfset dosyaAdi="">

    <cfif NOT structKeyExists(FORM,"csrf") OR compare(FORM.csrf,SESSION.csrf) NEQ 0>
        <cfset hataMesaji="Oturum doğrulaması başarısız.Sayfayı yenileyip tekrar deneyiniz">
    <cfelseif NOT dersDeger>
        <cfset hataMesaji="Ders seçimi zorunludur">
    <cfelseif NOT listFind("A,B,C,D",dogruCevapDeger)>
        <cfset hataMesaji="Doğru cevap seçimi zorunludur">
    <cfelseif NOT len(trim(FORM.soruGorsel))>
        <cfset hataMesaji="Soru görseli zorunludur">
    <cfelseif len(aciklamaDeger) LT minKarakter>
        <cfset hataMesaji="Çözüm açıklaması en az #minKarakter# karakter olmalıdır">
    <cfelse>
        <cftry>
            <cfif NOT directoryExists(yuklemeKlasoru)>
                <cfdirectory action="create" directory="#yuklemeKlasoru#">
            </cfif>

            <cffile action="upload" fileField="soruGorsel" destination="#yuklemeKlasoru#" nameConflict="makeunique" accept="image/jpeg,image/png,image/webp" strict="true" result="yukleme">
            <cfset dosyaAdi=yukleme.serverFile>

            <cfif NOT listFindNoCase("jpg,jpeg,png,webp",yukleme.serverFileExt)>
                <cffile action="delete" file="#yuklemeKlasoru##dosyaAdi#">
                <cfthrow message="Geçersiz dosya türü">
            </cfif>

            <cfset yeniAd="soru_" & dateFormat(now(),"yyyymmdd") & "_" & left(hash(createUUID(),"MD5"),10) & "." & lcase(yukleme.serverFileExt)>
            <cffile action="rename" source="#yuklemeKlasoru##dosyaAdi#" destination="#yuklemeKlasoru##yeniAd#">
            <cfset dosyaAdi=yeniAd>

            <cfimage action="read" source="#yuklemeKlasoru##dosyaAdi#" name="gorsel">

            <cfif imageGetWidth(gorsel) GT 800>
                <cfset imageResize(gorsel,800,"")>
                <cfimage action="write" source="#gorsel#" destination="#yuklemeKlasoru##dosyaAdi#" overwrite="true" quality="0.6">
            </cfif>

            <cfquery datasource="#application.DSN#" result="sonuc">
                INSERT INTO Sorular(kullaniciID,dersID,soruGorsel,dogruCevap,aciklama,kaynak,yayinlandiMi,aktifMi)
                VALUES(
                <cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#dersDeger#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#dosyaAdi#" cfsqltype="cf_sql_nvarchar">,
                <cfqueryparam value="#dogruCevapDeger#" cfsqltype="cf_sql_nchar">,
                <cfqueryparam value="#aciklamaDeger#" cfsqltype="cf_sql_longvarchar">,
                application.kaynak.ogrenci,
                1,
                1
                )
            </cfquery>

            <cfquery datasource="#application.DSN#">
                UPDATE Kullanicilar
                SET puan=puan+<cfqueryparam value="#val(application.ayar.puanSoruYukleme)#" cfsqltype="cf_sql_integer">
                WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfset SESSION.puan=val(SESSION.puan)+val(application.ayar.puanSoruYukleme)>
            <cflocation url="#application.kokYol#/views/soru/soruDetay.cfm?id=#val(sonuc.generatedKey)#&yeni=1" addtoken="false">

            <cfcatch type="any">
                <cfif len(dosyaAdi) AND fileExists("#yuklemeKlasoru##dosyaAdi#")>
                    <cffile action="delete" file="#yuklemeKlasoru##dosyaAdi#">
                </cfif>
                    <cfset hataMesaji="HATA:" & cfcatch.message & " | " & cfcatch.detail>
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<cfinclude template="/lgs/views/includes/baslik.cfm">

<cfoutput>
    <div class="dar dar--genis">
        <section class="kart">
            <div class="kart__baslik">Soru Ekle</div>

            <div class="kart__govde">

                <cfif len(hataMesaji)>
                    <div class="bildirim bildirim--hata" role="alert">#encodeForHTML(hataMesaji)#</div>
                </cfif>

                <form method="post" action="#cgi.script_name#" enctype="multipart/form-data">
                    <cfinclude template="/lgs/views/includes/csrfAlan.cfm">

                    <div class="alan">
                        <label for="dersID">Ders:</label>
                        <select class="secim" id="dersID" name="dersID" required>
                            <option value="0">Seçiniz</option>
                            <cfloop query="application.qDers">
                                <option value="#application.qDers.dersID#"<cfif dersDeger EQ application.qDers.dersID> selected</cfif>>#encodeForHTML(application.qDers.dersAdi)#</option>
                            </cfloop>
                        </select>
                    </div>

                    <div class="alan">
                        <label for="soruGorsel">Soru Görseli</label>

                        <div class="dosya-alan">
                            <input type="file" id="soruGorsel" name="soruGorsel" accept="image/jpeg,image/png,image/webp" required>
                            <div class="dosya-alan__simge">+</div>
                            <div class="dosya-alan__baslik">Fotoğraf seçin veya sürükleyiniz</div>
                            <div class="dosya-alan__ipucu">jpg,png veya webp formatında olmalıdır</div>
                        </div>

                        <div class="onizleme" id="onizleme" hidden>
                            <img
                                class="onizleme__resim" id="onizlemeResim" src="" alt="Seçilen görsel">
                            <span class="onizleme__ad" id="onizlemeAd"></span>
                        </div>
                    </div>

                    <div class="alan">
                        <label for="dogruCevap">Doğru Cevap:</label>

                        <div class="siklar--satir">
                            <cfloop list="A,B,C,D" index="harf">
                                <label class="sik sik--sade">
                                    <input type="radio" name="dogruCevap" value="#harf#"<cfif dogruCevapDeger EQ harf> checked</cfif> required>
                                    <span class="optik">#harf#</span>
                                </label>
                            </cfloop>
                        </div>

                        <span class="alan__ipucu">Soru için doğru olduğunu düşündüğünüz cevabı işaretleyiniz</span>
                    </div>

                    <div class="alan">
                        <label for="aciklama">Nerede Takıldın?</label>
                        <textarea class="girdi" id="aciklama" name="aciklama" maxlength="4000" minlength="#minKarakter#" required placeholder="Soruyu çözerken ne denedin,hangi adımda takıldın?">#encodeForHTML(aciklamaDeger)#</textarea>
                        <span class="alan__ipucu">En az #minKarakter# karakter. <br> Çözüm yolunuzu anlatmanız,sorunun çözümüne ne derece hakim olduğunuzu gösterir</span>
                    </div>

                    <button class="dugme dugme--ana dugme--tam" type="submit" name="gonder" value="1">Soruyu Yükle</button>
                </form>
            </div>
        </section>
    </div>
</cfoutput>

<cfinclude template="/lgs/views/includes/altBilgi.cfm">