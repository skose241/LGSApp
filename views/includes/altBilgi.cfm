<cfoutput>
                </main>
            </div>

            <cfif structKeyExists(SESSION,"kullaniciID") AND val(SESSION.kullaniciID)>
                <nav class="alt-tab">
                    <a class="tab" href="#application.kokYol#/anaSayfa.cfm">Ana Sayfa</a>
                    <a class="tab" href="#application.kokYol#/views/odev/odevListesi.cfm">Ödevler</a>

                    <cfif val(SESSION.rol) EQ application.rol.ogrenci>
                        <a class="tab tab--ekle" href="#application.kokYol#/views/soru/soruEkle.cfm">
                            <span class="tab__daire">+</span>Soru Sor
                        </a>
                    </cfif>

                    <a class="tab" href="#application.kokYol#/views/bildirim/bildirimler.cfm">Bildirim</a>
                    <a class="tab" href="#application.kokYol#/views/profil/profilim.cfm">Profil</a>
                </nav>
            </cfif>

            <script src="#application.kokYol#/assets/vendor/katex/katex.min.js"></script>
            <script src="#application.kokYol#/assets/vendor/katex/auto-render.min.js"></script>
            <script src="#application.kokYol#/assets/js/custom.js?v=#application.varlikSurum#"></script>
            <script src="#application.kokYol#/assets/js/topluYukle.js?v=#application.varlikSurum#"></script>

            <script>
                if ("serviceWorker" in navigator) {
                    navigator.serviceWorker.register("#application.kokYol#/service-worker.js");
                }
            </script>
        </body>
    </html>
</cfoutput>