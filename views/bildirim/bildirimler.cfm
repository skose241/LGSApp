<cfinclude template="/lgs/views/includes/yetki.cfm">

<cfset sayfaBasligi="Bildirimler">

<cfif structKeyExists(FORM,"tumunuOku") AND structKeyExists(FORM,"csrf") AND compare(FORM.csrf,SESSION.csrf) EQ 0>
    <cfquery datasource="#application.DSN#">
        UPDATE Bildirimler
        SET okunduMu=1
        WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
        AND okunduMu=0
    </cfquery>

    <cflocation url="#cgi.script_name#" addtoken="false">
</cfif>

<cfif structKeyExists(URL,"oku") AND val(URL.oku)>
    <cfquery name="qHedef" datasource="#application.DSN#">
        SELECT hedefURL
        FROM Bildirimler
        WHERE bildirimID=<cfqueryparam value="#val(URL.oku)#" cfsqltype="cf_sql_integer">
        AND kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfif qHedef.recordCount>
        <cfquery datasource="#application.DSN#">
            UPDATE Bildirimler
            SET okunduMu=1
            WHERE bildirimID=<cfqueryparam value="#val(URL.oku)#" cfsqltype="cf_sql_integer">
            AND kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfif len(trim(qHedef.hedefURL)) AND left(trim(qHedef.hedefURL),1) EQ "/">
            <cflocation url="#trim(qHedef.hedefURL)#" addtoken="false">
        </cfif>
    </cfif>

    <cflocation url="#cgi.script_name#" addtoken="false">
</cfif>

<cfquery datasource="#application.DSN#">
    DELETE FROM Bildirimler
    WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
    AND okunduMu=1
    AND olusturmaTarihi<DATEADD(DAY,-30,GETDATE())
</cfquery>

<cfquery name="qBildirimler" datasource="#application.DSN#">
    SELECT TOP 50 bildirimID,bildirimTipi,mesaj,hedefURL,okunduMu,olusturmaTarihi
    FROM Bildirimler
    WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
    ORDER BY okunduMu,olusturmaTarihi DESC
</cfquery>

<cfset okunmamis=0>

<cfloop query="qBildirimler">
    <cfif NOT qBildirimler.okunduMu>
        <cfset okunmamis=okunmamis+1>
    </cfif>
</cfloop>

<cfinclude template="/lgs/views/includes/baslik.cfm">

<cfoutput>
    <div class="yigin">
        <div class="baslik-satiri">
            <h2>Bildirimler</h2>

            <cfif okunmamis>
                <form method="post" action="#cgi.script_name#">
                    <cfinclude template="/lgs/views/includes/csrfAlan.cfm">
                    <button class="dugme dugme--sade" type="submit" name="tumunuOku" value="1">Tümünü okundu işaretle</button>
                </form>
            </cfif>
        </div>

        <section class="kart">
            <cfif qBildirimler.recordCount>
                <div class="liste">
                    <cfloop query="qBildirimler">
                        <a class="liste-bag <cfif NOT qBildirimler.okunduMu>liste-bag--yeni</cfif>" href="#cgi.script_name#?oku=#qBildirimler.bildirimID#">
                            <span class="liste-ikon <cfswitch expression="#qBildirimler.bildirimTipi#"><cfcase value="gunlukSoru">liste-ikon--ai</cfcase><cfcase value="cozum,ogretmenCozum">liste-ikon--yorum</cfcase><cfdefaultcase>liste-ikon--sistem</cfdefaultcase></cfswitch>">
                                <cfswitch expression="#qBildirimler.bildirimTipi#">
                                    <cfcase value="gunlukSoru">S</cfcase>
                                    <cfcase value="odev">Ö</cfcase>
                                    <cfcase value="cozum">Ç</cfcase>
                                    <cfcase value="ogretmenCozum">Ö</cfcase>
                                    <cfcase value="cevapSupheli">!</cfcase>
                                    <cfdefaultcase>i</cfdefaultcase>
                                </cfswitch>
                            </span>

                            <span class="liste-bag__govde">
                                <span class="liste-bag__metin">#encodeForHTML(qBildirimler.mesaj)#</span>
                                <span class="liste-bag__zaman">#dateFormat(qBildirimler.olusturmaTarihi,"dd.mm.yyyy")# #timeFormat(qBildirimler.olusturmaTarihi,"HH:mm")#</span>
                            </span>

                            <span class="liste-bag__ok">></span>
                        </a>
                    </cfloop>
                </div>
            <cfelse>
                <div class="kart__govde">
                    <div class="bos-durum">
                        <div class="bos-durum__daire"></div>
                        <h3>Bildirim yok</h3>
                        <p class="sessiz">Sorularına gelen çözümler ve yeni ödevler burada görünecek</p>
                    </div>
                </div>
            </cfif>
        </section>
    </div>
</cfoutput>

<cfinclude template="/lgs/views/includes/altBilgi.cfm">