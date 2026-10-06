<cfset kayitAcikMi=false>
<cfif NOT kayitAcikMi>
    <cfinclude template="/views/includes/baslik.cfm">

    <cfoutput>
        <div class="dar">
            <section class="kart">
                <div class="kart__govde">
                    <h1 class="baslik">Kayıt Kapalı</h1>
                    <div class="bildirim bildirim--bilgi" role="status">Bu platformda hesaplar okul yönetimi tarafından oluşturulmaktadır.Kendi başınıza kayıt olamazsınız</div>
                    <a class="dugme dugme--ikincil dugme--tam ust-bosluk" href="#application.kokYol#/views/kimlik/giris.cfm">Giriş sayfasına dön</a>
                </div>
            </section>
        </div>
    </cfoutput>

    <cfinclude template="/views/includes/altBilgi.cfm">
    <cfabort>
</cfif>