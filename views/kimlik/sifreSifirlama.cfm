<cfset sifirlamaAcikMi=false>
<cfif NOT sifirlamaAcikMi>
    <cfinclude template="/views/includes/baslik.cfm">

    <cfoutput>
        <div class="dar">
            <section class="kart">
                <div class="kart__govde">
                    <h1 class="baslik">Şifre Sıfırlama Kapalı</h1>
                    <div class="bildirim bildirim--bilgi" role="status">Şifrenizi unuttuysanız okul yönetimine başvurunuz.Yeni şifreniz size iletilecektir</div>
                    <a class="dugme dugme--ikincil dugme--tam ust-bosluk" href="#application.kokYol#/views/kimlik/giris.cfm">Giriş sayfasına dön</a>
                </div>
            </section>
        </div>
    </cfoutput>

    <cfinclude template="/views/includes/altBilgi.cfm">
    <cfabort>
</cfif>