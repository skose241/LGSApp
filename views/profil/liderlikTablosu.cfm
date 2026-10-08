<cfinclude template="/lgs/views/includes/yetki.cfm">

<cfset sayfaBasligi="Liderlik Tablosu">
<cfparam name="URL.aralik" default="hafta">

<cfif NOT listFind("hafta,tum",URL.aralik)>
    <cfset URL.aralik="hafta">
</cfif>

<cfif URL.aralik EQ "tum">
    <cfquery name="qSiralama" datasource="#application.DSN#">
        SELECT TOP 20 k.kullaniciID,k.kullaniciAdi,k.puan AS skor
        FROM Kullanicilar k
        WHERE k.rol=<cfqueryparam value="#application.rol.ogrenci#" cfsqltype="cf_sql_tinyint">
        AND k.aktifMi=1
        ORDER BY k.puan DESC,k.kullaniciAdi
    </cfquery>
<cfelse>
    <cfquery name="qSiralama" datasource="#application.DSN#">
        SELECT TOP 20 k.kullaniciID,k.kullaniciAdi,
               ISNULL(SUM(CASE WHEN t.dogruMu=1 THEN 1 ELSE 0 END),0) AS skor
        FROM Kullanicilar k
        LEFT JOIN(
            SELECT kullaniciID,dogruMu,cevapTarihi FROM Cevaplar
            UNION ALL
            SELECT kullaniciID,dogruMu,cevapTarihi FROM OdevCevaplari
        ) AS t ON t.kullaniciID=k.kullaniciID
            AND t.cevapTarihi>=DATEADD(DAY,-7,CAST(GETDATE() AS DATE))
        WHERE k.rol=<cfqueryparam value="#application.rol.ogrenci#" cfsqltype="cf_sql_tinyint">
        AND k.aktifMi=1
        GROUP BY k.kullaniciID,k.kullaniciAdi
        ORDER BY skor DESC,k.kullaniciAdi
    </cfquery>
</cfif>

<cfinclude template="/lgs/views/includes/baslik.cfm">

<cfoutput>
    <div class="yigin">
        <div class="baslik-satiri">
            <h2>Liderlik Tablosu</h2>
        </div>

        <div class="sekmeler">
            <a class="sekme" href="#cgi.script_name#?aralik=hafta"<cfif URL.aralik EQ "hafta"> aria-selected="true"</cfif>>Bu Hafta</a>
            <a class="sekme" href="#cgi.script_name#?aralik=tum"<cfif URL.aralik EQ "tum"> aria-selected="true"</cfif>>Tüm Zamanlar</a>
        </div>

        <section class="kart">
            <div class="kart__govde">
                <cfif qSiralama.recordCount>
                    <ol class="siralama">
                        <cfloop query="qSiralama">
                            <li<cfif val(qSiralama.kullaniciID) EQ val(SESSION.kullaniciID)> aria-current="true"</cfif>>
                                <span class="sira-no">#qSiralama.currentRow#</span>
                                <span class="avatar">#ucase(left(qSiralama.kullaniciAdi,1))#</span>
                                <span class="siralama__ad">#encodeForHTML(qSiralama.kullaniciAdi)#</span>
                                <span class="siralama__xp">#val(qSiralama.skor)#<cfif URL.aralik EQ "tum"> XP<cfelse> doğru</cfif></span>
                            </li>
                        </cfloop>
                    </ol>
                <cfelse>
                    <div class="bos-durum">
                        <div class="bos-durum__daire"></div>
                        <h3>Henüz veri yok</h3>
                    </div>
                </cfif>
            </div>
        </section>
    </div>
</cfoutput>

<cfinclude template="/lgs/views/includes/altBilgi.cfm">