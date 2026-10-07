<cfset gerekliRoller="#application.rol.ogretmen#,#application.rol.mudur#">
<cfinclude template="/lgs/views/includes/yetki.cfm">

<cfparam name="URL.soruID" default="0">
<cfset soruID=val(URL.soruID)>
<cfset hataMesaji="">
<cfset cozumMetniDeger="">

<cfquery name="qSoru" datasource="#application.DSN#">
    SELECT s.soruID,s.soruMetni,s.soruGorsel,s.dogruCevap,s.kaynak,s.cevapSupheli,s.konuID,s.dersID,
           d.dersAdi,k.kullaniciAdi
    FROM Sorular s
    INNER JOIN Dersler d ON d.dersID=s.dersID
    INNER JOIN Kullanicilar k ON k.kullaniciID=s.kullaniciID
    WHERE s.soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    AND s.aktifMi=1
</cfquery>

<cfif NOT qSoru.recordCount>
    <cflocation url="#application.kokYol#/views/ogretmen/cozumBekleyenler.cfm" addtoken="false">
</cfif>

<cfif structKeyExists(FORM,"cevapDuzelt") AND structKeyExists(FORM,"csrf") AND compare(FORM.csrf,SESSION.csrf) EQ 0>
    <cfset yeniCevap=ucase(trim(FORM.yeniDogruCevap))>

    <cfif listFind("A,B,C,D",yeniCevap)>
        <cftransaction>
            <cfquery datasource="#application.DSN#">
                UPDATE Sorular
                SET dogruCevap=<cfqueryparam value="#yeniCevap#" cfsqltype="cf_sql_nchar">,
                    cevapSupheli=0
                WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfquery name="qEskiDurum" datasource="#application.DSN#">
                SELECT kullaniciID,verilenCevap,dogruMu
                FROM(
                    SELECT kullaniciID,verilenCevap,dogruMu FROM Cevaplar WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                    UNION ALL
                    SELECT kullaniciID,verilenCevap,dogruMu FROM OdevCevaplari WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
                ) AS t
            </cfquery>

            <cfloop query="qEskiDurum">
                <cfset yeniDogruMu=(compare(trim(qEskiDurum.verilenCevap),yeniCevap) EQ 0)>

                <cfif yeniDogruMu AND NOT qEskiDurum.dogruMu>
                    <cfset puanFarki=val(application.ayar.puanDogruCevap)>
                <cfelseif NOT yeniDogruMu AND qEskiDurum.dogruMu>
                    <cfset puanFarki=-val(application.ayar.puanDogruCevap)>
                <cfelse>
                    <cfset puanFarki=0>
                </cfif>

                <cfif puanFarki>
                    <cfquery datasource="#application.DSN#">
                        UPDATE Kullanicilar
                        SET puan=CASE WHEN puan+<cfqueryparam value="#puanFarki#" cfsqltype="cf_sql_integer"> LT 0 THEN 0 ELSE puan+<cfqueryparam value="#puanFarki#" cfsqltype="cf_sql_integer"> END
                        WHERE kullaniciID=<cfqueryparam value="#val(qEskiDurum.kullaniciID)#" cfsqltype="cf_sql_integer">
                    </cfquery>
                </cfif>
            </cfloop>

            <cfquery datasource="#application.DSN#">
                UPDATE Cevaplar
                SET dogruMu=CASE WHEN verilenCevap=<cfqueryparam value="#yeniCevap#" cfsqltype="cf_sql_nchar"> THEN 1 ELSE 0 END
                WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfquery datasource="#application.DSN#">
                UPDATE OdevCevaplari
                SET dogruMu=CASE WHEN verilenCevap=<cfqueryparam value="#yeniCevap#" cfsqltype="cf_sql_nchar"> THEN 1 ELSE 0 END
                WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
            </cfquery>
        </cftransaction>

        <cflocation url="#cgi.script_name#?soruID=#soruID#&duzeltildi=1" addtoken="false">
    </cfif>
</cfif>

<cfif structKeyExists(FORM,"cozumGonder")>
    <cfset cozumMetniDeger=trim(FORM.cozumMetni)>
    <cfset cozumDosyaAdi="">
    <cfset gorselVarMi=(structKeyExists(FORM,"cozumGorsel") AND len(trim(FORM.cozumGorsel)))>

    <cfif NOT structKeyExists(FORM,"csrf") OR compare(FORM.csrf,SESSION.csrf) NEQ 0>
        <cfset hataMesaji="Oturum doğrulaması başarısız">
    <cfelseif NOT len(cozumMetniDeger) AND NOT gorselVarMi>
        <cfset hataMesaji="Çözüm metni veya görseli eklemelisiniz">
    <cfelse>
        <cftry>
            <cfif gorselVarMi>
                <cfif NOT directoryExists(application.cozumGorselDizin)>
                    <cfdirectory action="create" directory="#application.cozumGorselDizin#">
                </cfif>

                <cffile action="upload" fileField="cozumGorsel" destination="#application.cozumGorselDizin#" nameConflict="makeunique" accept="image/jpeg,image/png,image/webp" strict="true" result="cozumYukleme">
                <cfset cozumDosyaAdi=cozumYukleme.serverFile>

                <cfif NOT listFindNoCase("jpg,jpeg,png,webp",cozumYukleme.serverFileExt)>
                    <cffile action="delete" file="#application.cozumGorselDizin##cozumDosyaAdi#">
                    <cfthrow message="Geçersiz dosya türü">
                </cfif>

                <cfset yeniAd="ogrtcozum_" & dateFormat(now(),"yyyymmdd") & "_" & left(hash(createUUID(),"MD5"),10) & "." & lcase(cozumYukleme.serverFileExt)>
                <cffile action="rename" source="#application.cozumGorselDizin##cozumDosyaAdi#" destination="#application.cozumGorselDizin##yeniAd#">
                <cfset cozumDosyaAdi=yeniAd>

                <cfimage action="read" source="#application.cozumGorselDizin##cozumDosyaAdi#" name="cozumGorseli">

                <cfif imageGetWidth(cozumGorseli) GT 800>
                    <cfset imageResize(cozumGorseli,800,"")>
                    <cfimage action="write" source="#cozumGorseli#" destination="#application.cozumGorselDizin##cozumDosyaAdi#" overwrite="true" quality=".8">
                </cfif>
            </cfif>

            <cfquery datasource="#application.DSN#">
                INSERT INTO Cozumler(soruID,kullaniciID,cozumTipi,cozumMetni,cozumGorsel)
                VALUES(
                <cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#application.cozumTipi.ogretmen#" cfsqltype="cf_sql_tinyint">,
                <cfqueryparam value="#cozumMetniDeger#" cfsqltype="cf_sql_longvarchar" null="#NOT len(cozumMetniDeger)#">,
                <cfqueryparam value="#cozumDosyaAdi#" cfsqltype="cf_sql_nvarchar" null="#NOT len(cozumDosyaAdi)#">
                )
            </cfquery>

            <cfquery name="qYanlisYapanlar" datasource="#application.DSN#">
                SELECT DISTINCT kullaniciID
                FROM(
                    SELECT kullaniciID FROM Cevaplar WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer"> AND dogruMu=0
                    UNION
                    SELECT kullaniciID FROM OdevCevaplari WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer"> AND dogruMu=0
                ) AS t
            </cfquery>

            <cfloop query="qYanlisYapanlar">
                <cfquery datasource="#application.DSN#">
                    INSERT INTO Bildirimler(kullaniciID,bildirimTipi,mesaj,hedefURL)
                    VALUES(
                    <cfqueryparam value="#val(qYanlisYapanlar.kullaniciID)#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="ogretmenCozum" cfsqltype="cf_sql_nvarchar">,
                    <cfqueryparam value="Takıldığınız bir soruya öğretmen çözümü eklendi" cfsqltype="cf_sql_nvarchar">,
                    <cfqueryparam value="#application.kokYol#/views/soru/soruDetay.cfm?id=#soruID#" cfsqltype="cf_sql_nvarchar">
                    )
                </cfquery>
            </cfloop>

            <cflocation url="#application.kokYol#/views/ogretmen/cozumBekleyenler.cfm?eklendi=1" addtoken="false">

            <cfcatch type="any">
                <cfif len(cozumDosyaAdi) AND fileExists("#application.cozumGorselDizin##cozumDosyaAdi#")>
                    <cffile action="delete" file="#application.cozumGorselDizin##cozumDosyaAdi#">
                </cfif>

                <cfif findNoCase("UQ_Cozumler",cfcatch.message)>
                    <cfset hataMesaji="Bu soruya zaten öğretmen çözümü eklenmiş">
                <cfelse>
                    <cfset hataMesaji="Çözüm eklenemedi.Lütfen tekrar deneyiniz">
                </cfif>
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<cfquery name="qMevcutCozumler" datasource="#application.DSN#">
    SELECT c.cozumTipi,c.cozumMetni,c.cozumGorsel,k.kullaniciAdi
    FROM Cozumler c
    LEFT JOIN Kullanicilar k ON k.kullaniciID=c.kullaniciID
    WHERE c.soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    ORDER BY c.cozumTipi
</cfquery>

<cfset sayfaBasligi="Çözüm Ekle">

<cfinclude template="/lgs/views/includes/baslik.cfm">

<cfoutput>
    <div class="yigin">
        <cfif structKeyExists(URL,"duzeltildi")>
            <div class="bildirim bildirim--basarili" role="status">Doğru cevap güncellendi ve tüm cevaplar yeniden değerlendirildi</div>
        </cfif>

        <cfif len(hataMesaji)>
            <div class="bildirim bildirim--hata" role="alert">#encodeForHTML(hataMesaji)#</div>
        </cfif>

        <section class="kart">
            <div class="kart__baslik">
                <span class="rozet rozet--ders">#encodeForHTML(qSoru.dersAdi)#</span>
                <span class="sessiz">#encodeForHTML(qSoru.kullaniciAdi)#</span>
            </div>

            <div class="kart__govde">
                <cfif len(qSoru.soruGorsel)>
                    <img
                        class="soru-gorsel" src="<cfif val(qSoru.kaynak) EQ application.kaynak.ogretmen>#application.odevGorselYol#<cfelse>#application.soruGorselYol#</cfif>#qSoru.soruGorsel#" alt="Soru görseli">
                <cfelseif len(qSoru.soruMetni)>
                    <div class="soru__metin">#encodeForHTML(qSoru.soruMetni)#</div>
                </cfif>

                <div class="hedef-kutu">Kayıtlı doğru cevap: <strong>#qSoru.dogruCevap#</strong></div>
            </div>
        </section>

        <section class="kart <cfif qSoru.cevapSupheli>mod-kutu</cfif>">
            <div class="kart__baslik">Doğru Cevabı Düzelt</div>

            <div class="kart__govde">
                <cfif qSoru.cevapSupheli>
                    <p class="sessiz">Yapay zeka bu soruda kayıtlı cevaptan farklı bir sonuca ulaştı.Kontrol ediniz</p>
                </cfif>

                <form method="post" action="#cgi.script_name#?soruID=#soruID#">
                    <cfinclude template="/lgs/views/includes/csrfAlan.cfm">

                    <div class="siklar--satir">
                        <cfloop list="A,B,C,D" index="harf">
                            <label class="sik sik--sade">
                                <input type="radio" name="yeniDogruCevap" value="#harf#"<cfif compare(trim(qSoru.dogruCevap),harf) EQ 0> checked</cfif> required>
                                <span class="optik">#harf#</span>
                            </label>
                        </cfloop>
                    </div>

                    <div class="hedef-kutu ust-bosluk">Cevabı değiştirirseniz bu soruyu çözmüş tüm öğrencilerin doğru yanlış durumu yeniden hesaplanır</div>

                    <button class="dugme dugme--ikincil dugme--tam" type="submit" name="cevapDuzelt" value="1">Cevabı Güncelle</button>
                </form>
            </div>
        </section>

        <cfif qMevcutCozumler.recordCount>
            <section class="kart">
                <div class="kart__baslik">Mevcut Çözümler:</div>

                <div class="kart__govde">
                    <cfloop query="qMevcutCozumler">
                        <div class="yorum">
                            <div class="yorum__govde">
                                <div class="yorum__ust">
                                    <span class="yorum__ad">
                                        <cfswitch expression="#val(qMevcutCozumler.cozumTipi)#">
                                            <cfcase value="#application.cozumTipi.ai#">Yapay Zeka</cfcase>
                                            <cfcase value="#application.cozumTipi.ogretmen#">Öğretmen</cfcase>
                                            <cfdefaultcase>#encodeForHTML(qMevcutCozumler.kullaniciAdi)#</cfdefaultcase>
                                        </cfswitch>
                                    </span>
                                </div>

                                <cfif len(qMevcutCozumler.cozumMetni)>
                                    <div class="soru__metin">#replace(encodeForHTML(qMevcutCozumler.cozumMetni),chr(10),"<br>","all")#</div>
                                </cfif>

                                <cfif len(qMevcutCozumler.cozumGorsel)>
                                    <img
                                        class="cozum-gorsel" src="#application.cozumGorselYol##qMevcutCozumler.cozumGorsel#" alt="Çözüm görseli">
                                </cfif>
                            </div>
                        </div>
                    </cfloop>
                </div>
            </section>
        </cfif>

        <section class="kart">
            <div class="kart__baslik">Çözümünüzü Ekleyin</div>

            <div class="kart__govde">
                <form method="post" action="#cgi.script_name#?soruID=#soruID#" enctype="multipart/form-data">
                    <cfinclude template="/lgs/views/includes/csrfAlan.cfm">

                    <div class="alan">
                        <label for="cozumMetni">Çözüm Açıklaması:</label>
                        <textarea class="girdi" id="cozumMetni" name="cozumMetni" maxlength="4000" placeholder="Öğrencilere nerede takıldıklarını ve doğru yolu anlatın">#encodeForHTML(cozumMetniDeger)#</textarea>
                    </div>

                    <div class="alan">
                        <label for="soruGorsel">Çözüm Görseli:</label>

                        <div class="dosya-alan">
                            <input type="file" id="soruGorsel" name="cozumGorsel" accept="image/jpeg,image/png,image/webp">
                            <div class="dosya-alan__simge">+</div>
                            <div class="dosya-alan__baslik">Tahta veya kağıt üzerindeki çözümünüzün fotoğrafı</div>
                            <div class="dosya-alan__ipucu">jpg,png veya webp</div>
                        </div>

                        <div class="onizleme" id="onizleme" hidden>
                            <img
                                class="onizleme__resim" id="onizlemeResim" src="" alt="Seçilen görsel">
                            <span class="onizleme__ad" id="onizlemeAd"></span>
                        </div>
                    </div>

                    <div class="hedef-kutu">Çözümünüz bir kez eklenir ve bu soruyu yanlış yapan tüm öğrencilere bildirim gider</div>

                    <button class="dugme dugme--ana dugme--tam" type="submit" name="cozumGonder" value="1">Çözümü Yayınla</button>
                </form>
            </div>
        </section>
    </div>
</cfoutput>

<cfinclude template="/lgs/views/includes/altBilgi.cfm">