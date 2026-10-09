<cfcomponent output="false">
    <cfset this.name="LGSApp.V2">
    <cfset this.datasource="LGSDSN">
    <cfset this.mappings["/lgs"]=getDirectoryFromPath(getCurrentTemplatePath())>
    <cfset this.sessionManagement=true>
    <cfset this.sessionTimeOut=createTimespan(0,4,0,0)>
    <cfset this.clientManagement=false>
    <cfset this.setClientCookies=true>
    <cfset this.sessionCookie.httpOnly=true>
    <cfset this.sessionCookie.secure=true>
    <cfset this.scriptProtect="none">

    <cffunction name="envDegeri" access="private" returntype="string" output="false">
        <cfargument name="ad" type="string" required="true">
        <cfset var env=server.system.environment>
        <cfset var k="">
        <cfloop collection="#env#" item="k">
            <cfif compareNoCase(trim(k),trim(arguments.ad)) EQ 0>
                <cfreturn trim(env[k])>
            </cfif>
        </cfloop>
        <cflog file="lgsHata" type="warning" text="Ortam değişkeni bulunamadı:#arguments.ad#">

        <cfreturn "">
    </cffunction>

    <cffunction name="referansYukle" access="private" returntype="void" output="false">
        <cfset var qDersYeni="">
        <cfset var qKonuYeni="">
        <cfset var qAyarYeni="">
        <cfset var ayarYapi=structNew()>
        <cflock name="LGSApp_referansYukle" type="exclusive" timeout="10">
            <cfquery name="qDersYeni" datasource="#this.datasource#">
                SELECT dersID,dersAdi,oturum,siraNo,uretimSikligi
                FROM Dersler
                WHERE aktifMi=1
                ORDER BY siraNo
            </cfquery>

            <cfquery name="qKonuYeni" datasource="#this.datasource#">
                SELECT konuID,dersID,konuAdi,siraNo
                FROM Konular
                WHERE aktifMi=1
                ORDER BY dersID,siraNo
            </cfquery>

            <cfquery name="qAyarYeni" datasource="#this.datasource#">
                SELECT ayarAnahtar,ayarDeger
                FROM Ayarlar
            </cfquery>

            <cfloop query="qAyarYeni">
                <cfset ayarYapi[qAyarYeni.ayarAnahtar]=qAyarYeni.ayarDeger>
            </cfloop>
            <cfset application.qDers=qDersYeni>
            <cfset application.qKonu=qKonuYeni>
            <cfset application.ayar=ayarYapi>
            <cfset application.referansZaman=now()>
        </cflock>
    </cffunction>

    <cffunction name="onApplicationStart" returntype="boolean" output="false">
        <cfset var qAIHesap="">
        <cfset application.DSN=this.datasource>
        <cfset application.varlikSurum="1.0.1">
        <cfset application.kokYol="/LGSApp">
        <cfset application.yerelURL="http://localhost:8888">
        <cfset application.geminiSoruKey=envDegeri("GEMINI_API_KEY_Soru")>
        <cfset application.geminiCozumKey=envDegeri("GEMINI_API_KEY_Cozum")>
        <cfset application.uretimToken=envDegeri("LGS_URETIM_TOKEN")>
        <cfset application.geminiURL="https://generativelanguage.googleapis.com/v1beta/interactions">
        <cfset application.aiLimit=5>
        <cfset application.uretimBekleme=35000>

        <cfset application.rol={mudur=1,ogretmen=2,ogrenci=3,ai=4}>
        <cfquery name="qAIHesap" datasource="#this.datasource#">
            SELECT TOP 1 kullaniciID
            FROM Kullanicilar
            WHERE rol=<cfqueryparam value="#application.rol.ai#" cfsqltype="cf_sql_tinyint">
            ORDER BY kullaniciID
        </cfquery>
        <cfset application.aiKullaniciID=val(qAIHesap.kullaniciID)>

        <cfset application.kaynak={ogretmen=2,ogrenci=3,ai=4}>
        <cfset application.cozumTipi={ogretmen=2,ogrenci=3,ai=4}>
        <cfset application.odevDurum={taslak="taslak",planlandi="planlandi",yayinda="yayinda",kapandi="kapandi"}>

        <cfset application.fizikselKok=getDirectoryFromPath(getCurrentTemplatePath())>
        <cfset application.soruGorselDizin=application.fizikselKok & "assets\images\sorular\">
        <cfset application.cozumGorselDizin=application.fizikselKok & "assets\images\cevaplar\">
        <cfset application.odevGorselDizin=application.fizikselKok & "assets\images\odev\">
        <cfset application.avatarDizin=application.fizikselKok & "assets\images\avatar\">

        <cfset application.soruGorselYol="#application.kokYol#/assets/images/sorular/">
        <cfset application.cozumGorselYol="#application.kokYol#/assets/images/cevaplar/">
        <cfset application.odevGorselYol="#application.kokYol#/assets/images/odev/">
        <cfset application.avatarYol="#application.kokYol#/assets/images/avatar/">
        <cfset referansYukle()>

        <cfreturn true>
    </cffunction>

    <cffunction name="onRequestStart" returntype="boolean" output="false">
        <cfargument name="targetPage" type="string" required="true">
        <cfset var qOturum="">
        <cfif structKeyExists(URL,"yenidenBaslat") AND len(trim(application.uretimToken)) AND URL.yenidenBaslat EQ application.uretimToken>
            <cfset onApplicationStart()>
        </cfif>

        <cfif NOT structKeyExists(application,"referansZaman") OR dateDiff("n",application.referansZaman,now()) GTE 60>
            <cfset referansYukle()>
        </cfif>

        <cfif NOT structKeyExists(SESSION,"kullaniciID") AND structKeyExists(COOKIE,"beniHatirla") AND len(trim(COOKIE.beniHatirla))>
            <cfquery name="qOturum" datasource="#application.DSN#">
                SELECT k.kullaniciID,k.kullaniciAdi,k.rol,k.puan,k.bransDersID
                FROM Oturumlar o
                INNER JOIN Kullanicilar k ON k.kullaniciID=o.kullaniciID
                WHERE o.sessionToken=<cfqueryparam value="#COOKIE.beniHatirla#" cfsqltype="cf_sql_varchar">
                AND o.aktifMi=1
                AND k.aktifMi=1
                AND o.girisTarihi>DATEADD(DAY,-30,GETDATE())
            </cfquery>

            <cfif qOturum.recordCount>
                <cfset sessionRotate()>
                <cfset SESSION.kullaniciID=val(qOturum.kullaniciID)>
                <cfset SESSION.kullaniciAd=qOturum.kullaniciAdi>
                <cfset SESSION.rol=val(qOturum.rol)>
                <cfset SESSION.puan=val(qOturum.puan)>
                <cfset SESSION.bransDersID=val(qOturum.bransDersID)>

                <cfquery datasource="#application.DSN#">
                    UPDATE Oturumlar
                    SET sonGoruldu=<cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
                    WHERE sessionToken=<cfqueryparam value="#COOKIE.beniHatirla#" cfsqltype="cf_sql_varchar">
                    AND aktifMi=1
                </cfquery>
            <cfelse>
                <cfcookie name="beniHatirla" value="" expires="now" httponly="true" secure="true">
            </cfif>
        </cfif>

        <cfreturn true>
    </cffunction>

    <cffunction name="onSessionStart" returntype="void" output="false">
        <cfset SESSION.csrf=hash(createUUID() & getTickCount(),"SHA-256")>
    </cffunction>

    <cffunction name="onSessionEnd" returntype="void" output="false">
        <cfargument name="sessionScope" required="true">
        <cfargument name="appScope" required="false">
    </cffunction>

    <cffunction name="onError" returntype="void" output="true">
        <cfargument name="exception" required="true">
        <cfargument name="eventName" type="string" required="false" default="">
        <cflog file="lgsHata" type="error" text="#arguments.eventName# | #cgi.script_name# | #arguments.exception.message# | #arguments.exception.detail#">

        <cfset var konum="">
        <cftry>
            <cfif structKeyExists(arguments.exception,"tagContext") AND isArray(arguments.exception.tagContext) AND arrayLen(arguments.exception.tagContext)>
                <cfloop from="1" to="#min(3,arrayLen(arguments.exception.tagContext))#" index="i">
                    <cfset konum=konum & arguments.exception.tagContext[i].template & ":" & arguments.exception.tagContext[i].line & " | ">
                </cfloop>
            </cfif>
            <cfcatch type="any"></cfcatch>
        </cftry>

        <cfset var eksikDosya="">
        <cfif structKeyExists(arguments.exception,"missingFileName")>
            <cfset eksikDosya=arguments.exception.missingFileName>
        </cfif>

        <cfset var detayMetni=arguments.exception.message & " || DETAY:" & arguments.exception.detail & " || TIP:" & arguments.exception.type & " || EKSIK:" & eksikDosya & " || KONUM:" & konum>
        <cftry>
            <cfquery datasource="#application.DSN#">
                INSERT INTO HataLog(sayfa,islem,mesaj,detay,eklenmeTarihi)
                VALUES(
                <cfqueryparam value="#left(cgi.script_name,100)#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#left('onError:' & arguments.eventName,100)#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#left(detayMetni,8000)#" cfsqltype="cf_sql_longvarchar">,
                <cfqueryparam value="#left(arguments.exception.detail,8000)#" cfsqltype="cf_sql_longvarchar">,
                GETDATE()
                )
            </cfquery>
            <cfcatch type="any"></cfcatch>
        </cftry>

        <cfoutput>
            <!DOCTYPE HTML>
            <html lang="tr" data-tema="gunduz">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width,initial-scale=1.0">
                    <title>Hata</title>
                    <link href="#application.kokYol#/assets/css/style.css?v=#application.varlikSurum#" rel="stylesheet">
                </head>
                <body>
                    <div class="kabuk">
                        <main class="icerik">
                            <div class="dar">
                                <section class="kart">
                                    <div class="kart__govde">
                                        <div class="bildirim bildirim--hata" role="alert">Bir hata oluştu.Lütfen daha sonra tekrar deneyiniz</div>
                                        <a class="dugme dugme--ikincil dugme--tam ust-bosluk" href="#application.kokYol#/anaSayfa.cfm">Ana sayfaya dön</a>
                                    </div>
                                </section>
                            </div>
                        </main>
                    </div>
                </body>
            </html>
        </cfoutput>
    </cffunction>
</cfcomponent>