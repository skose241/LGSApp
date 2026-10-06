<cfcomponent output="false">
    <cffunction name="tuzUret" access="public" returntype="string" output="false">
        <cfreturn hash(createUUID() & getTickCount(),"SHA-256")>
    </cffunction>

    <cffunction name="sifreHashle" access="public" returntype="string" output="false">
        <cfargument name="sifre" type="string" required="true">
        <cfargument name="tuz" type="string" required="false" default="">
        <cfset var kullanilanTuz=arguments.tuz>
        <cfset var ozet="">
        <cfset var i=0>

        <cfif NOT len(trim(kullanilanTuz))>
            <cfset kullanilanTuz=tuzUret()>
        </cfif>

        <cfset ozet=hash(kullanilanTuz & arguments.sifre,"SHA-512")>
        <cfloop from="1" to="5000" index="i">
            <cfset ozet=hash(ozet & kullanilanTuz,"SHA-512")>
        </cfloop>

        <cfreturn kullanilanTuz & ":" & ozet>
    </cffunction>

    <cffunction name="sifreDogrula" access="public" returntype="boolean" output="false">
        <cfargument name="sifre" type="string" required="true">
        <cfargument name="kayitliHash" type="string" required="true">
        <cfset var tuz="">
        <cfset var yeniden="">

        <cfif listLen(arguments.kayitliHash,":") NEQ 2>
            <cfreturn false>
        </cfif>
        
        <cfset tuz=listFirst(arguments.kayitliHash,":")>
        <cfset yeniden=sifreHashle(arguments.sifre,tuz)>

        <cfreturn compare(yeniden,arguments.kayitliHash) EQ 0>
    </cffunction>

    <cffunction name="tokenUret" access="public" returntype="string" output="false">
        <cfreturn hash(createUUID() & getTickCount() & rand(),"SHA-256")>
    </cffunction>

</cfcomponent>