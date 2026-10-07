<cfinclude template="/lgs/views/includes/yetki.cfm">

<cfparam name="URL.id" default="0">
<cfparam name="URL.yeni" default="0">
<cfset soruID=val(URL.id)>
<cfset hataMesaji="">
<cfset basariMesaji="">
<cfset minKarakter=val(application.ayar.aciklamaMinKarakter)>
<cfset secilenDeger="">
<cfset cozumMetniDeger="">

<cfif NOT soruID>
    <cflocation url="#application.kokYol#/anaSayfa.cfm" addtoken="false">
</cfif>

<cfquery name="qSoru" datasource="#application.DSN#">
    SELECT s.soruID,s.kullaniciID,s.dersID,s.konuID,s.soruMetni,s.soruGorsel,
           s.secenekA,s.secenekB,s.secenekC,s.secenekD,s.dogruCevap,s.aciklama,
           s.cevapSupheli,s.kaynak,s.olusturmaTarihi,
           k.kullaniciAdi,d.dersAdi,ko.konuAdi
    FROM Sorular s
    INNER JOIN Kullanicilar k ON k.kullaniciID=s.kullaniciID
    INNER JOIN Dersler d ON d.dersID=s.dersID
    LEFT JOIN Konular ko ON ko.konuID=s.konuID
    WHERE s.soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    AND s.aktifMi=1
    AND s.yayinlandiMi=1
</cfquery>

<cfif NOT qSoru.recordCount>
    <cflocation url="#application.kokYol#/anaSayfa.cfm?hata=bulunamadi" addtoken="false">
</cfif>

<cfset benimSorum=(val(qSoru.kullaniciID) EQ val(SESSION.kullaniciID))>
<cfset ogretmenMi=(val(SESSION.rol) EQ application.rol.ogretmen OR val(SESSION.rol) EQ application.rol.mudur)>

<cfif structKeyExists(FORM,"cevapGonder")>
    <cfset secilenDeger=ucase(trim(FORM.verilenCevap))>
    <cfset cozumMetniDeger=trim(FORM.cozumMetni)>
    <cfset cozumDosyaAdi="">
    <cfset gorselVarMi=(structKeyExists(FORM,"cozumGorsel") AND len(trim(FORM.cozumGorsel)))>

    <cfif NOT structKeyExists(FORM,"csrf") OR compare(FORM.csrf,SESSION.csrf) NEQ 0>
        <cfset hataMesaji="Oturum doğrulaması başarısız">
    <cfelseif benimSorum>
        <cfset hataMesaji="Kendi sorduğunuz soruyu cevaplayamazsınız">
    <cfelseif ogretmenMi>
        <cfset hataMesaji="Öğretmen hesapları soru cevaplayamaz">
    <cfelseif NOT listFind("A,B,C,D",secilenDeger)>
        <cfset hataMesaji="Lütfen bir şık seçiniz">
    <cfelseif NOT len(cozumMetniDeger) AND NOT gorselVarMi>
        <cfset hataMesaji="Çözümünü yazmalı veya kağıt üzerindeki çözümünün fotoğrafını yüklemelisiniz">
    <cfelseif len(cozumMetniDeger) AND NOT gorselVarMi AND len(cozumMetniDeger) LT minKarakter>
        <cfset hataMesaji="Çözüm açıklaması en az #minKarakter# karakter olmalıdır">
    <cfelse>
        <cfset dogruMu=(compare(secilenDeger,trim(qSoru.dogruCevap)) EQ 0)>

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

                <cfset yeniAd="cozum_" & dateFormat(now(),"yyyymmdd") & "_" & left(hash(createUUID(),"MD5"),10) & "." & lcase(cozumYukleme.serverFileExt)>
                <cffile action="rename" source="#application.cozumGorselDizin##cozumDosyaAdi#" destination="#application.cozumGorselDizin##yeniAd#">
                <cfset cozumDosyaAdi=yeniAd>

                <cfimage action="read" source="#application.cozumGorselDizin##cozumDosyaAdi#" name="cozumGorseli">

                <cfif imageGetWidth(cozumGorseli) GT 800>
                    <cfset imageResize(cozumGorseli,800,"")>
                    <cfimage action="write" source="#cozumGorseli#" destination="#application.cozumGorselDizin##cozumDosyaAdi#" overwrite="true" quality=".85">
                </cfif>
            </cfif>

            <cftransaction>
                <cfquery datasource="#application.DSN#">
                    INSERT INTO Cevaplar(soruID,kullaniciID,verilenCevap,dogruMu)
                    VALUES(
                    <cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#secilenDeger#" cfsqltype="cf_sql_nchar">,
                    <cfqueryparam value="#dogruMu#" cfsqltype="cf_sql_bit">
                    )
                </cfquery>

                <cfquery datasource="#application.DSN#">
                    INSERT INTO Cozumler(soruID,kullaniciID,cozumTipi,cozumMetni,cozumGorsel)
                    VALUES(
                    <cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#application.cozumTipi.ogrenci#" cfsqltype="cf_sql_tinyint">,
                    <cfqueryparam value="#cozumMetniDeger#" cfsqltype="cf_sql_longvarchar" null="#NOT len(cozumMetniDeger)#">,
                    <cfqueryparam value="#cozumDosyaAdi#" cfsqltype="cf_sql_nvarchar" null="#NOT len(cozumDosyaAdi)#">
                    )
                </cfquery>

                <cfset kazanilanPuan=val(application.ayar.puanCozumYazma)>

                <cfif dogruMu>
                    <cfset kazanilanPuan=kazanilanPuan+val(application.ayar.puanDogruCevap)>
                </cfif>

                <cfquery datasource="#application.DSN#">
                    UPDATE Kullanicilar
                    SET puan=puan+<cfqueryparam value="#kazanilanPuan#" cfsqltype="cf_sql_integer">
                    WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
                </cfquery>

                <cfquery datasource="#application.DSN#">
                    INSERT INTO Bildirimler(kullaniciID,bildirimTipi,mesaj,hedefURL)
                    VALUES(
                    <cfqueryparam value="#val(qSoru.kullaniciID)#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="cozum" cfsqltype="cf_sql_nvarchar">,
                    <cfqueryparam value="#SESSION.kullaniciAd# sorunuza bir çözüm ekledi" cfsqltype="cf_sql_nvarchar">,
                    <cfqueryparam value="#application.kokYol#/views/soru/soruDetay.cfm?id=#soruID#" cfsqltype="cf_sql_nvarchar">
                    )
                </cfquery>
            </cftransaction>

            <cfset SESSION.puan=val(SESSION.puan)+kazanilanPuan>
            <cflocation url="#cgi.script_name#?id=#soruID#&cozuldu=1" addtoken="false">

            <cfcatch type="any">
                <cfif len(cozumDosyaAdi) AND fileExists("#application.cozumGorselDizin##cozumDosyaAdi#")>
                    <cffile action="delete" file="#application.cozumGorselDizin##cozumDosyaAdi#">
                </cfif>

                <cfif findNoCase("UQ_Cevaplar",cfcatch.message) OR findNoCase("UQ_Cozumler",cfcatch.message) OR findNoCase("duplicate",cfcatch.message)>
                    <cfset hataMesaji="Bu soruyu zaten cevaplamışsınız">
                <cfelse>
                    <cfset hataMesaji="İşlem tamamlanamadı.Lütfen tekrar deneyiniz">
                </cfif>
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<cfquery name="qCevabim" datasource="#application.DSN#">
    SELECT verilenCevap,dogruMu,cevapTarihi
    FROM Cevaplar
    WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    AND kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
</cfquery>

<cfset cevapVerdimMi=(qCevabim.recordCount GT 0)>
<cfset gorebilirMiyim=(cevapVerdimMi OR benimSorum OR ogretmenMi)>

<cfif structKeyExists(FORM,"yorumGonder")>
    <cfset yorumMetniDeger=trim(FORM.yorumMetni)>
    <cfset hedefCozumID=val(FORM.cozumID)>

    <cfif NOT structKeyExists(FORM,"csrf") OR compare(FORM.csrf,SESSION.csrf) NEQ 0>
        <cfset hataMesaji="Oturum doğrulaması başarısız">
    <cfelseif NOT gorebilirMiyim>
        <cfset hataMesaji="Yorum yapmak için önce soruyu cevaplamalısınız">
    <cfelseif NOT len(yorumMetniDeger)>
        <cfset hataMesaji="Yorum metni boş olamaz">
    <cfelse>
        <cfquery datasource="#application.DSN#">
            INSERT INTO Yorumlar(soruID,cozumID,kullaniciID,yorumMetni)
            VALUES(
            <cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#hedefCozumID#" cfsqltype="cf_sql_integer" null="#NOT hedefCozumID#">,
            <cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#left(yorumMetniDeger,800)#" cfsqltype="cf_sql_nvarchar">
            )
        </cfquery>

        <cfset basariMesaji="Yorumunuz eklendi">
    </cfif>
</cfif>

<cfquery name="qCozumler" datasource="#application.DSN#">
    SELECT c.cozumID,c.kullaniciID,c.cozumTipi,c.cozumMetni,c.cozumGorsel,c.olusturmaTarihi,
           k.kullaniciAdi
    FROM Cozumler c
    LEFT JOIN Kullanicilar k ON k.kullaniciID=c.kullaniciID
    WHERE c.soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    ORDER BY c.cozumTipi,c.olusturmaTarihi
</cfquery>

<cfquery name="qYorumlar" datasource="#application.DSN#">
    SELECT y.yorumID,y.cozumID,y.yorumMetni,y.olusturmaTarihi,k.kullaniciAdi
    FROM Yorumlar y
    INNER JOIN Kullanicilar k ON k.kullaniciID=y.kullaniciID
    WHERE y.soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
    AND y.aktifMi=1
    ORDER BY y.olusturmaTarihi
</cfquery>

<cfquery name="qIstatistik" datasource="#application.DSN#">
    SELECT COUNT(*) AS toplam,SUM(CASE WHEN dogruMu=1 THEN 1 ELSE 0 END) AS dogru
    FROM Cevaplar
    WHERE soruID=<cfqueryparam value="#soruID#" cfsqltype="cf_sql_integer">
</cfquery>

<cfset aiCozumuVarMi=false>
<cfloop query="qCozumler">
    <cfif val(qCozumler.cozumTipi) EQ application.cozumTipi.ai>
        <cfset aiCozumuVarMi=true>
    </cfif>
</cfloop>

<cfset sayfaBasligi="#qSoru.dersAdi# Sorusu">

<cfinclude template="/lgs/views/includes/baslik.cfm">

<cfoutput>
    <div class="yigin">
        <cfif URL.yeni EQ "1">
            <div class="bildirim bildirim--basarili" role="status">Sorunuz yayınlandı<span class="bildirim__xp">+#application.ayar.puanSoruYukleme# XP</span></div>
        </cfif>

        <cfif structKeyExists(URL,"cozuldu") AND cevapVerdimMi>
            <div class="bildirim <cfif qCevabim.dogruMu>bildirim--basarili<cfelse>bildirim--hata</cfif>" role="status">
                <cfif qCevabim.dogruMu>Doğru cevap<cfelse>Yanlış cevap.Çözümlere göz atın</cfif>
            </div>
        </cfif>

        <cfif structKeyExists(URL,"hata")>
            <div class="bildirim bildirim--hata" role="alert">
                <cfswitch expression="#URL.hata#">
                    <cfcase value="bekle">Önceki isteğiniz işleniyor.Birkaç saniye sonra tekrar deneyiniz</cfcase>
                    <cfcase value="limit">Günlük yapay zeka çözüm hakkınız doldu</cfcase>
                    <cfcase value="okunamadi">Soru görseli net okunamadığı için çözüm üretilemedi</cfcase>
                    <cfcase value="yetkisiz">Bu işlem için önce soruyu cevaplamalısınız</cfcase>
                    <cfdefaultcase>Yapay zeka şu anda yanıt veremedi.Birkaç dakika sonra tekrar deneyiniz</cfdefaultcase>
                </cfswitch>
            </div>
        </cfif>

        <cfif len(hataMesaji)>
            <div class="bildirim bildirim--hata" role="alert">#encodeForHTML(hataMesaji)#</div>
        </cfif>

        <cfif len(basariMesaji)>
            <div class="bildirim bildirim--basarili" role="status">#encodeForHTML(basariMesaji)#</div>
        </cfif>

        <section class="kart">
            <div class="kart__govde">
                <div class="soru__ust">
                    <span class="rozet rozet--ders">#encodeForHTML(qSoru.dersAdi)#</span>

                    <cfif len(qSoru.konuAdi)>
                        <span class="rozet">#encodeForHTML(qSoru.konuAdi)#</span>
                    </cfif>

                    <cfif val(qSoru.kaynak) EQ application.kaynak.ai>
                        <span class="rozet rozet--yz">Yapay Zeka Sorusu</span>
                    <cfelseif val(qSoru.kaynak) EQ application.kaynak.ogretmen>
                        <span class="rozet rozet--sistem">Öğretmen Sorusu</span>
                    </cfif>

                    <cfif qSoru.cevapSupheli AND ogretmenMi>
                        <span class="rozet rozet--pasif">Cevap Şüpheli</span>
                    </cfif>

                    <span class="sessiz">#encodeForHTML(qSoru.kullaniciAdi)# · #dateFormat(qSoru.olusturmaTarihi,"dd.mm.yyyy")#</span>
                </div>

                <cfif len(qSoru.soruMetni)>
                    <div class="soru__metin">#encodeForHTML(qSoru.soruMetni)#</div>
                </cfif>

                <cfif len(qSoru.soruGorsel)>
                    <img
                        class="soru-gorsel" src="#application.soruGorselYol##qSoru.soruGorsel#" alt="Soru görseli">
                </cfif>

                <cfif cevapVerdimMi>
                    <div class="sonuc <cfif qCevabim.dogruMu>sonuc--dogru<cfelse>sonuc--yanlis</cfif>">
                        <div class="sonuc__kutu">
                            <span class="sonuc__etiket">Cevabınız:</span>
                            <span class="sonuc__harf">#qCevabim.verilenCevap#</span>
                        </div>

                        <div class="sonuc__kutu">
                            <span class="sonuc__etiket">Doğru Cevap:</span>
                            <span class="sonuc__harf">#qSoru.dogruCevap#</span>
                        </div>

                        <div class="sonuc__kutu">
                            <span class="sonuc__etiket">Durum:</span>
                            <span class="sonuc__harf"><cfif qCevabim.dogruMu>Doğru<cfelse>Yanlış</cfif></span>
                        </div>
                    </div>
                <cfelseif benimSorum>
                    <div class="hedef-kutu">Bu soruyu siz sordunuz.Gelen çözümleri aşağıdan takip edebilirsiniz</div>
                <cfelseif ogretmenMi>
                    <div class="hedef-kutu">Doğru cevap: <strong>#qSoru.dogruCevap#</strong></div>
                </cfif>
            </div>

            <cfif gorebilirMiyim AND val(qIstatistik.toplam)>
                <div class="kart__ayrac">
                    <div class="dip-not">
                        <span>Çözen: <b>#val(qIstatistik.toplam)#</b></span>
                        <span>Doğru: <b>#val(qIstatistik.dogru)#</b></span>
                        <span>Başarı: <b>#numberFormat(val(qIstatistik.dogru)/val(qIstatistik.toplam)*100,"9")#%</b></span>
                    </div>
                </div>
            </cfif>
        </section>

        <cfif NOT cevapVerdimMi AND NOT benimSorum AND NOT ogretmenMi>
            <section class="kart">
                <div class="kart__baslik">Cevabınızı ve Çözümünüzü Gönderiniz</div>

                <div class="kart__govde">
                    <form method="post" action="#cgi.script_name#?id=#soruID#" enctype="multipart/form-data">
                        <cfinclude template="/lgs/views/includes/csrfAlan.cfm">

                        <div class="alan">
                            <label>Cevap:</label>

                            <div class="siklar">
                                <cfloop list="A,B,C,D" index="harf">
                                    <label class="sik">
                                        <input type="radio" name="verilenCevap" value="#harf#"<cfif secilenDeger EQ harf> checked</cfif> required>
                                        <span class="optik">#harf#</span>

                                        <cfset sikMetni=qSoru["secenek" & harf][1]>
                                        <cfif len(trim(sikMetni))>
                                            <span class="sik__yazi">#encodeForHTML(sikMetni)#</span>
                                        </cfif>
                                    </label>
                                </cfloop>
                            </div>
                        </div>

                        <div class="alan">
                            <label for="cozumMetni">Çözüm:</label>
                            <textarea class="girdi" id="cozumMetni" name="cozumMetni" maxlength="4000" placeholder="Soruyu nasıl çözdüğünüzü anlatın" data-sayac="cozumSayac">#encodeForHTML(cozumMetniDeger)#</textarea>
                            <span class="alan__ipucu">En az #minKarakter# karakter (<span id="cozumSayac">0</span>).Kağıda çözdüysen metin yerine fotoğraf yükleyebilirsin</span>
                        </div>

                        <div class="alan">
                            <label for="soruGorsel">Çözüm Fotoğrafı:</label>

                            <div class="dosya-alan">
                                <input type="file" id="soruGorsel" name="cozumGorsel" accept="image/jpeg,image/png,image/webp">
                                <div class="dosya-alan__simge">+</div>
                                <div class="dosya-alan__baslik">Kağıt üzerindeki çözümünün fotoğrafı</div>
                                <div class="dosya-alan__ipucu">jpg,png veya webp</div>
                            </div>

                            <div class="onizleme" id="onizleme" hidden>
                                <img
                                    class="onizleme__resim" id="onizlemeResim" src="" alt="Seçilen görsel">
                                <span class="onizleme__ad" id="onizlemeAd"></span>
                            </div>
                        </div>

                        <div class="hedef-kutu">Gönderdikten sonra cevabınızı değiştiremezsiniz.Doğru cevap ve diğer çözümler,kendi çözümünüzü paylaştıktan sonra açılacaktır</div>

                        <button class="dugme dugme--ana dugme--tam" type="submit" name="cevapGonder" value="1">Cevabı ve Çözümü Gönder</button>
                    </form>
                </div>
            </section>
        </cfif>

        <cfif gorebilirMiyim>
            <cfif len(qSoru.aciklama)>
                <section class="kart">
                    <div class="kart__baslik">Soruyu Sahibinin Açıklaması:</div>
                    <div class="kart__govde">#encodeForHTML(qSoru.aciklama)#</div>
                </section>
            </cfif>

            <cfif cevapVerdimMi AND NOT aiCozumuVarMi>
                <section class="kart">
                    <div class="kart__govde">
                        <form method="post" action="#application.kokYol#/views/soru/aiCozdurme.cfm">
                            <cfinclude template="/lgs/views/includes/csrfAlan.cfm">
                            <input type="hidden" name="soruID" value="#soruID#">
                            <button class="dugme dugme--ikincil dugme--tam" type="submit" name="aiIste" value="1">AI çözümü iste</button>
                        </form>
                    </div>
                </section>
            </cfif>

            <cfloop query="qCozumler">
                <section class="kart <cfif val(qCozumler.cozumTipi) EQ application.cozumTipi.ogretmen>mod-kutu</cfif>">
                    <div class="kart__baslik">
                        <cfswitch expression="#val(qCozumler.cozumTipi)#">
                            <cfcase value="#application.cozumTipi.ai#">Yapay Zeka Çözümü:</cfcase>
                            <cfcase value="#application.cozumTipi.ogretmen#">Öğretmen Çözümü:</cfcase>
                            <cfdefaultcase>#encodeForHTML(qCozumler.kullaniciAdi)# Çözümü:</cfdefaultcase>
                        </cfswitch>

                        <span class="cozum-kart__tarih">#dateFormat(qCozumler.olusturmaTarihi,"dd.mm.yyyy")#</span>
                    </div>

                    <div class="kart__govde">
                        <cfif len(qCozumler.cozumMetni)>
                            <div class="soru__metin">#replace(encodeForHTML(qCozumler.cozumMetni),chr(10),"<br>","all")#</div>
                        </cfif>

                        <cfif len(qCozumler.cozumGorsel)>
                            <img
                                class="cozum-gorsel" src="#application.cozumGorselYol##qCozumler.cozumGorsel#" alt="Çözüm görseli">
                        </cfif>

                        <cfset buCozumID=val(qCozumler.cozumID)>
                        <cfquery name="qCozumYorum" dbtype="query">
                            SELECT kullaniciAdi,yorumMetni,olusturmaTarihi
                            FROM qYorumlar
                            WHERE cozumID=#buCozumID#
                            ORDER BY olusturmaTarihi
                        </cfquery>

                        <cfloop query="qCozumYorum">
                            <div class="yorum yorum--yanit">
                                <div class="yorum__govde">
                                    <div class="yorum__ust">
                                        <span class="yorum__ad">#encodeForHTML(qCozumYorum.kullaniciAdi)#</span>
                                        <span class="yorum__zaman">#dateFormat(qCozumYorum.olusturmaTarihi,"dd.mm.yyyy")#</span>
                                    </div>
                                    <div>#encodeForHTML(qCozumYorum.yorumMetni)#</div>
                                </div>
                            </div>
                        </cfloop>

                        <form class="mini-form" method="post" action="#cgi.script_name#?id=#soruID#">
                            <cfinclude template="/lgs/views/includes/csrfAlan.cfm">
                            <input type="hidden" name="cozumID" value="#buCozumID#">
                            <input class="girdi" type="text" name="yorumMetni" maxlength="1000" placeholder="Bu çözüme ekleme yap" required>
                            <button class="dugme dugme--ikincil" type="submit" name="yorumGonder" value="1">Gönder</button>
                        </form>
                    </div>
                </section>
            </cfloop>

            <section class="kart">
                <div class="kart__baslik">Soru Hakkındaki Yorumlar:</div>

                <div class="kart__govde">
                    <cfquery name="qGenelYorum" dbtype="query">
                        SELECT kullaniciAdi,yorumMetni,olusturmaTarihi
                        FROM qYorumlar
                        WHERE cozumID IS NULL
                        ORDER BY olusturmaTarihi
                    </cfquery>

                    <cfif qGenelYorum.recordCount>
                        <cfloop query="qGenelYorum">
                            <div class="yorum">
                                <div class="yorum__govde">
                                    <div class="yorum__ust">
                                        <span class="yorum__ad">#encodeForHTML(qGenelYorum.kullaniciAdi)#</span>
                                        <span class="yorum__zaman">#dateFormat(qGenelYorum.olusturmaTarihi,"dd.mm.yyyy")#</span>
                                    </div>
                                    <div>#encodeForHTML(qGenelYorum.yorumMetni)#</div>
                                </div>
                            </div>
                        </cfloop>
                    <cfelse>
                        <p class="sessiz">Henüz yorum yok</p>
                    </cfif>

                    <form class="mini-form" method="post" action="#cgi.script_name#?id=#soruID#">
                        <cfinclude template="/lgs/views/includes/csrfAlan.cfm">
                        <input type="hidden" name="cozumID" value="0">
                        <input class="girdi" type="text" name="yorumMetni" maxlength="1000" placeholder="Yorumunu yaz" required>
                        <button class="dugme dugme--ikincil" type="submit" name="yorumGonder" value="1">Gönder</button>
                    </form>
                </div>
            </section>
        <cfelse>
            <section class="kart">
                <div class="kart__govde">
                    <div class="bos-durum">
                        <div class="bos-durum__daire"></div>
                        <h3>Önce kendi çözümünüzü gönderin</h3>
                        <p class="sessiz">Doğru cevabı,diğer çözümleri ve yorumları görebilmek için cevabınızı ve çözümünüzü göndermeniz gerekiyor</p>
                    </div>
                </div>
            </section>
        </cfif>
    </div>
</cfoutput>

<cfinclude template="/lgs/views/includes/altBilgi.cfm">