<cfparam name="gerekliRoller" default="">

<cfinclude template="/lgs/views/includes/oturumKontrol.cfm">

<cfif len(trim(gerekliRoller)) AND NOT listFind(gerekliRoller,val(SESSION.rol))>
    <cflocation url="#application.kokYol#/anaSayfa.cfm?hata=yetkisiz" addtoken="false">
</cfif>