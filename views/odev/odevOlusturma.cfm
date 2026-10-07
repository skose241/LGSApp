<cfset gerekliRoller="#application.rol.ogretmen#,#application.rol.mudur#">
<cfinclude template="/lgs/views/includes/yetki.cfm">

<cfset sayfaBasligi="Yeni Ödev">
<cfset hataMesaji="">
<cfset baslikDeger="">
<cfset dersDeger=val(SESSION.bransDersID)>
<cfset baslangicDeger=dateFormat(now(),"yyyy-mm-dd")>
<cfset bitisDeger=dateFormat(dateAdd("d",2,now()),"yyyy-mm-dd")>

<cfif structKeyExists(FORM,"gonder")>
    <cfset baslikDeger=trim(FORM.baslik)>
    <cfset dersDeger=val(FORM.dersID)>
    <cfset baslangicDeger=trim(FORM.baslangicTarihi)>
    <cfset bitisDeger=trim(FORM.bitisTarihi)>

    <cfif NOT structKeyExists(FORM,"csrf") OR compare(FORM.csrf,SESSION.csrf) NEQ 0>
        <cfset hataMesaji="Oturum doğrulaması başarısız">
    <cfelseif NOT dersDeger>
        <cfset hataMesaji="Ders seçimi zorunludur">
    <cfelseif NOT isDate(baslangicDeger) OR NOT isDate(bitisDeger)>
        <cfset hataMesaji="Geçerli bir tarih aralığı giriniz">
    <cfelseif dateCompare(bitisDeger,baslangicDeger,"d") LT 0>
        <cfset hataMesaji="Bitiş tarihi başlangıç tarihinden önce olamaz">
    <cfelseif dateCompare(baslangicDeger,now(),"d") LT 0>
        <cfset hataMesaji="Başlangıç tarihi bugünden önce olamaz">
    <cfelse>
        <cfquery datasource="#application.DSN#" result="sonuc">
            INSERT INTO Odevler(ogretmenID,dersID,baslik,baslangicTarihi,bitisTarihi,durum)
            VALUES(
            <cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#dersDeger#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#baslikDeger#" cfsqltype="cf_sql_nvarchar" null="#NOT len(baslikDeger)#">,
            <cfqueryparam value="#baslangicDeger#" cfsqltype="cf_sql_date">,
            <cfqueryparam value="#bitisDeger#" cfsqltype="cf_sql_date">,
            <cfqueryparam value="#application.odevDurum.taslak#" cfsqltype="cf_sql_nvarchar">
            )
        </cfquery>

        <cflocation url="#application.kokYol#/views/odev/odevTopluYukleme.cfm?odevID=#val(sonuc.generatedKey)#" addtoken="false">
    </cfif>
</cfif>

<cfquery name="qTakvim" datasource="#application.DSN#">
    SELECT baslangicTarihi,COUNT(*) AS adet
    FROM Odevler
    WHERE durum IN (<cfqueryparam value="#application.odevDurum.planlandi#" cfsqltype="cf_sql_nvarchar">,<cfqueryparam value="#application.odevDurum.yayinda#" cfsqltype="cf_sql_nvarchar">)
    AND baslangicTarihi>=CAST(GETDATE() AS DATE)
    AND baslangicTarihi<=DATEADD(DAY,14,CAST(GETDATE() AS DATE))
    GROUP BY baslangicTarihi
    ORDER BY baslangicTarihi
</cfquery>

<cfinclude template="/lgs/views/includes/baslik.cfm">

<cfoutput>
    <div class="dar dar--genis">
        <cfif len(hataMesaji)>
            <div class="bildirim bildirim--hata" role="alert">#encodeForHTML(hataMesaji)#</div>
        </cfif>

        <section class="kart">
            <div class="kart__baslik">Yeni Ödev Oluştur</div>

            <div class="kart__govde">
                <form method="post" action="#cgi.script_name#">
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
                        <label for="baslik">Ödev Başlığı:</label>
                        <input class="girdi" type="text" id="baslik" name="baslik" value="#encodeForHTMLAttribute(baslikDeger)#" maxlength="150" placeholder="Üslü İfadeler Tekrar Ödevi">
                        <span class="alan__ipucu">Boş bırakırsanız ders adı kullanılır</span>
                    </div>

                    <div class="alan">
                        <label for="baslangicTarihi">Başlangıç Tarihi:</label>
                        <input class="girdi" type="date" id="baslangicTarihi" name="baslangicTarihi" value="#dateFormat(baslangicDeger,'yyyy-mm-dd')#" required>
                    </div>

                    <div class="alan">
                        <label for="bitisTarihi">Bitiş Tarihi:</label>
                        <input class="girdi" type="date" id="bitisTarihi" name="bitisTarihi" value="#dateFormat(bitisDeger,'yyyy-mm-dd')#" required>
                        <span class="alan__ipucu">Öğrenciler bu tarihten sonra ödevi çözemez,sadece görüntüleyebilir</span>
                    </div>

                    <cfif qTakvim.recordCount>
                        <div class="hedef-kutu">
                            Yaklaşan ödevler:
                            <cfloop query="qTakvim">
                                <strong>#dateFormat(qTakvim.baslangicTarihi,"dd.mm")# (#val(qTakvim.adet)#)</strong>
                            </cfloop>
                        </div>
                    </cfif>

                    <button class="dugme dugme--ana dugme--tam" type="submit" name="gonder" value="1">Devam Et ve Soru Yükle</button>
                </form>
            </div>
        </section>
    </div>
</cfoutput>

<cfinclude template="/lgs/views/includes/altBilgi.cfm">