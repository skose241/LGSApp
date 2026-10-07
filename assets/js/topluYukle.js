document.addEventListener("DOMContentLoaded", function(){
    const secici=document.getElementById("topluDosya");
    const liste=document.getElementById("topluListe");
    const gonder=document.getElementById("topluGonder");

    if(!secici || !liste){
        return;
    }

    secici.addEventListener("change", function(){
        liste.innerHTML="";

        const dosyalar=Array.from(secici.files).slice(0, 20);

        dosyalar.forEach(function (dosya, sira){
            const no=sira+1;
            const kutu=document.createElement("div");
            kutu.className="kart ust-bosluk";

            const govde=document.createElement("div");
            govde.className="kart__govde";

            const resim=document.createElement("img");
            resim.className="onizleme__resim";
            resim.src=URL.createObjectURL(dosya);

            const gizli=document.createElement("input");
            gizli.type="file";
            gizli.name="gorsel" + no;
            gizli.hidden=true;

            const aktarim=new DataTransfer();
            aktarim.items.add(dosya);
            gizli.files=aktarim.files;

            const siklar=document.createElement("div");
            siklar.className="siklar--satir ust-bosluk";

            ["A", "B", "C", "D"].forEach(function(harf){
                const etiket=document.createElement("label");
                etiket.className="sik sik--sade";

                const secim=document.createElement("input");
                secim.type="radio";
                secim.name="cevap" + no;
                secim.value=harf;
                secim.required=true;

                const daire=document.createElement("span");
                daire.className="optik";
                daire.textContent=harf;

                etiket.appendChild(secim);
                etiket.appendChild(daire);
                siklar.appendChild(etiket);
            });

            const baslik=document.createElement("div");
            baslik.className="goz";
            baslik.textContent="Soru "+no;

            govde.appendChild(baslik);
            govde.appendChild(resim);
            govde.appendChild(gizli);
            govde.appendChild(siklar);
            kutu.appendChild(govde);
            liste.appendChild(kutu);
        });

        gonder.disabled=dosyalar.length===0;
    });
});