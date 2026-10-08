<cfparam name="sayfaBasligi" default="LGS Soru & Çözüm Platformu">
<cfset girisYapildiMi=structKeyExists(SESSION,"kullaniciID") AND val(SESSION.kullaniciID)>
<cfset okunmamisBildirim=0>
<cfset gunAdlari="Pazar,Pazartesi,Salı,Çarşamba,Perşembe,Cuma,Cumartesi">

<cfif girisYapildiMi>
    <cfquery name="qBildirimSayi" datasource="#application.DSN#">
        SELECT COUNT(*) AS adet
        FROM Bildirimler
        WHERE kullaniciID=<cfqueryparam value="#val(SESSION.kullaniciID)#" cfsqltype="cf_sql_integer">
        AND okunduMu=0
    </cfquery>
    <cfset okunmamisBildirim=val(qBildirimSayi.adet)>
</cfif>

<cfoutput>
    <!DOCTYPE HTML>
    <html lang="tr" data-tema="gunduz">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width,initial-scale=1.0">
            <meta name="theme-color" content="##E9EEEE">
            <title>#encodeForHTML(sayfaBasligi)#</title>
            <link rel="manifest" href="#application.kokYol#/manifest.json">
            <link href="#application.kokYol#/assets/vendor/katex/katex.min.css" rel="stylesheet">
            <link href="#application.kokYol#/assets/css/style.css?v=#application.varlikSurum#" rel="stylesheet">
        </head>

        <body>
            <a class="atla" href="##icerik">İçeriğe atla</a>

            <cfif girisYapildiMi>
                <header class="ust-bar">
                    <div class="ust-bar__ic">
                        <a class="logo" href="#application.kokYol#/anaSayfa.cfm">
                            <span class="logo__net">LGS</span><span class="logo__ad">Platform</span>
                        </a>

                        <div class="ust-bar__bosluk"></div>

                        <a class="simge-dugme zil" href="#application.kokYol#/views/bildirim/bildirimler.cfm" aria-label="Bildirimler">
                            Zil<cfif okunmamisBildirim><span class="zil__sayi">#okunmamisBildirim#</span></cfif>
                        </a>

                        <details class="hesap">
                            <summary class="hesap__dugme">
                                <span class="hesap__harf">#ucase(left(SESSION.kullaniciAd,1))#</span>
                            </summary>

                            <div class="hesap__liste">
                                <div class="hesap__ad">#encodeForHTML(SESSION.kullaniciAd)#</div>
                                <a class="hesap__satir" href="#application.kokYol#/views/profil/profilim.cfm">Profilim</a>

                                <cfif val(SESSION.rol) EQ application.rol.mudur>
                                    <a class="hesap__satir hesap__satir--yonetim" href="#application.kokYol#/views/yonetim/yonetimPanel.cfm">Yönetim</a>
                                </cfif>

                                <a class="hesap__satir hesap__satir--cikis" href="#application.kokYol#/views/kimlik/cikis.cfm">Çıkış</a>
                            </div>
                        </details>
                    </div>
                </header>
            </cfif>

            <div class="kabuk">
                <cfif girisYapildiMi>
                    <aside class="yan-menu">
                        <nav>
                            <a class="menu-baglanti" href="#application.kokYol#/anaSayfa.cfm">Ana Sayfa</a>
                            <a class="menu-baglanti" href="#application.kokYol#/views/odev/odevListesi.cfm">Ödevler</a>

                            <cfif val(SESSION.rol) EQ application.rol.ogrenci>
                                <a class="menu-baglanti" href="#application.kokYol#/views/soru/soruEkle.cfm">Soru Ekle</a>
                            </cfif>

                            <cfif val(SESSION.rol) EQ application.rol.ogretmen OR val(SESSION.rol) EQ application.rol.mudur>
                                <div class="menu-baslik">Öğretmen</div>
                                <a class="menu-baglanti" href="#application.kokYol#/views/ogretmen/ogretmenPanel.cfm">Panel</a>
                                <a class="menu-baglanti" href="#application.kokYol#/views/ogretmen/cozumBekleyenler.cfm">Çözüm Bekleyenler</a>
                                <a class="menu-baglanti" href="#application.kokYol#/views/odev/odevOlusturma.cfm">Ödev Oluştur</a>
                                <a class="menu-baglanti" href="#application.kokYol#/views/ogretmen/konuSecimi.cfm">Günlük Konular</a>
                            </cfif>

                            <cfif val(SESSION.rol) EQ application.rol.mudur>
                                <div class="menu-baslik">Yönetim</div>
                                <a class="menu-baglanti" href="#application.kokYol#/views/yonetim/kullaniciOlusturma.cfm">Kullanıcılar</a>
                                <a class="menu-baglanti" href="#application.kokYol#/views/yonetim/konuPlani.cfm">Konu Planı</a>
                                <a class="menu-baglanti" href="#application.kokYol#/views/yonetim/uretimLog.cfm">Üretim Günlüğü</a>
                            </cfif>
                        </nav>
                    </aside>
                </cfif>

                <main class="icerik" id="icerik">
</cfoutput>