document.addEventListener("DOMContentLoaded",function (){
    gorselOnizleme();
    matematikRender();
    temaKur();
    sayacBagla();
});

function gorselOnizleme() {
    const girdi=document.getElementById("soruGorsel");
    const kutu=document.getElementById("onizleme");
    const resim=document.getElementById("onizlemeResim");
    const ad=document.getElementById("onizlemeAd");

    if (!girdi || !kutu || !resim){
        return;
    }

    girdi.addEventListener("change",function (){
        const dosya=girdi.files[0];

        if (!dosya){
            kutu.hidden=true;
            resim.removeAttribute("src");
            return;
        }

        if (resim.dataset.eskiURL){
            URL.revokeObjectURL(resim.dataset.eskiURL);
        }

        const yeniURL=URL.createObjectURL(dosya);

        resim.src=yeniURL;
        resim.dataset.eskiURL=yeniURL;

        if(ad){
            ad.textContent=dosya.name+" ("+Math.round(dosya.size / 1024)+" KB)";
        }

        kutu.hidden=false;
    });
}

function matematikRender(){
    if(typeof renderMathInElement!=="function"){
        return;
    }

    document.querySelectorAll(".soru__metin, .ai-kutu, .cozum, .yorum").forEach(function(alan){
        renderMathInElement(alan,{
            delimiters: [
                {left:"$$",right:"$$",display:true},
                {left:"\\[",right:"\\]",display:true},
                {left:"$",right:"$",display:false},
                {left:"\\(",right:"\\)",display:false}
            ],
            throwOnError:false
        });
    });
}

function temaKur(){
    const dugme=document.getElementById("temaDugme");
    const kayitli=localStorage.getItem("tema");

    if(kayitli){
        document.documentElement.setAttribute("data-tema",kayitli);
    }

    if(!dugme){
        return;
    }

    dugme.addEventListener("click",function(){
        const simdiki=document.documentElement.getAttribute("data-tema");
        const yeni=simdiki==="gece" ? "gunduz":"gece";

        document.documentElement.setAttribute("data-tema",yeni);
        localStorage.setItem("tema",yeni);
    });
}

function sayacBagla(){
    document.querySelectorAll("[data-sayac]").forEach(function(alan) {
        const hedef=document.getElementById(alan.dataset.sayac);

        if(!hedef){
            return;
        }

        const guncelle=function(){
            hedef.textContent=alan.value.length;
        };

        alan.addEventListener("input",guncelle);
        guncelle();
    });
}