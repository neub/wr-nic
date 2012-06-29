NOT OFFICIAL, PLEASE REMOVE THIS FILE

El hdlmake no funciona sin permisos por tanto, el repositorio no puede estar en windows. 

Po eso o por algo más, Thomasz me paso su hdlmake y este si funciona. No obstante parece que: 

 -Cuando hay "bajadas de repositorios anidadas", puede ser necesarios varios hdlmake -f 

 - Hay que ir paso a paso, generando el make para el ise y todo eso. 

  - Acoardarse de actualizar el proyecto de ise

  - despues de eso, parece que finalmente va todo con hdlmake -l. 

* Error en el paquete	package wrcore_pkg, redefine el tipo: t_txtsu_timestamp
Solución: eliminar la definición del tipo y añadir use work.wrsw_txtsu_pkg.all;
a la entity xwr_core.

* PROBLEMA: NO GENERA .BIN	
Tras compilar una vez, cambiar de: 
    <property xil_pn:name="Create Binary Configuration File" xil_pn:value="false" xil_pn:valueState="non-default"/>

A 
    <property xil_pn:name="Create Binary Configuration File" xil_pn:value="true" xil_pn:valueState="non-default"/>

Y volver a compilar.
