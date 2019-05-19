IMPLEMENTATION MODULE bmp;

(* Librer¡a para mostrar por pantalla im genes en formato bmp con MCGA *)

INLINE PROCEDURE VGA256=code6(0B8H,13H,0H,0CDH,10H,0C3H);			

(* ------------------- *)

PROCEDURE RETRAZO;
	BEGIN	
		REPEAT UNTIL ((In(03DAH) MOD 16) > 7);
		REPEAT UNTIL ((In(03DAH) MOD 16) <= 7);
END RETRAZO;
(* ------------------------ *)

PROCEDURE OpenBMP(archivo:ARRAY OF CHAR;VAR correcto:BOOLEAN):FIO.File;
VAR
	fich: FIO.File;
	nombre: ARRAY [0..11] OF CHAR;
BEGIN
	correcto:=FALSE;
	nombre[0]:=CHR(0);
	Append(nombre,archivo);
	Append(nombre,".BMP");
	IF FIO.Exists(nombre) THEN
		fich:= FIO.Open(nombre);
		correcto:=TRUE;
	END;
	RETURN fich;
END OpenBMP;
(* -------------------------------------------------------- *)

PROCEDURE coge_paleta(F:FIO.File; VAR paleta:TipoPaleta);
VAR n,aux:CARDINAL;
    byte1:CHAR;
BEGIN
    FIO.Seek(F,54);(*Se posiciona el cursor en el sitio para empezar a leer*)
    FOR n:=0 TO 255 DO
        aux:=FIO.RdBin(F,paleta[n].b,SIZE(CHAR));
        aux:=FIO.RdBin(F,paleta[n].g,SIZE(CHAR));
        aux:=FIO.RdBin(F,paleta[n].r,SIZE(CHAR));
        aux:=FIO.RdBin(F,byte1,SIZE(CHAR));
        paleta[n].r:=paleta[n].r DIV 4;
        paleta[n].g:=paleta[n].g DIV 4;
        paleta[n].b:=paleta[n].b DIV 4;
    END;
END coge_paleta;
(* -----------------------------------------------------------------*)

PROCEDURE Actualiza(color,R,G,B : SHORTCARD);
VAR
BEGIN
     SYSTEM.Out(968,color);
     SYSTEM.Out(969,R);
     SYSTEM.Out(969,G);
     SYSTEM.Out(969,B);
END Actualiza;



(* ------------------------------------------------------------------- *)

PROCEDURE PonPaleta(paleta: TipoPaleta);
VAR n:CARDINAL;
BEGIN
    (* Actualiza(0,0,0,0);*)   (* !OJO CON ESTO, QUE HAY QUE BORRARLO!!! *)
    FOR n:=0 TO 255 DO
        Actualiza(SHORTCARD(n),paleta[n].r,paleta[n].g,paleta[n].b);
    END;
    (*Actualiza(255,255,255,255);*) (* !!! ESTO TAMBIEN HAY QUE BORRARLO !!! *)
END PonPaleta;

(* ------------------------------------------------------------- *)

PROCEDURE muestra(F:FIO.File);
VAR
  InfoFile : BITMAPFILEHEADER;
  InfoBitmap : BITMAPINFOHEADER;
  co2 : TipoPaleta;
  aux,registro:CARDINAL;
  x,y,bpl4:LONGINT;
  byte1,r,g,b:CHAR;
  bol:BOOLEAN;
  ncol,bytesporlinea,n,paleta,i,j,Size:CARDINAL;
  valor,r2,g2,b2:LONGCARD;
  real:REAL;
  image,imag2, video:puntero;

BEGIN
    IF Storage.Available(CARDINAL(FIO.Size(F))) THEN
    NEW(image);
    FIO.Seek(F,10);(*Se posiciona el cursor en el sitio para empezar a leer*)
    aux:=FIO.RdBin(F,InfoFile.bfOffbits,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biSize,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biWidth,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biHeight,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biPlanes,SIZE(INTEGER));
    aux:=FIO.RdBin(F,InfoBitmap.biBitCount,SIZE(INTEGER));
    aux:=FIO.RdBin(F,InfoBitmap.biCompression,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biSizeImage,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biXpelsPerMeter,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biYpelsPerMeter,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biClrUsed,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biClrImportant,SIZE(LONGINT));
    IF InfoBitmap.biClrUsed=0 THEN
       ncol:=CARDINAL(Pow(2.0,LONGREAL(InfoBitmap.biBitCount)));
    ELSE
       ncol:=CARDINAL(InfoBitmap.biClrUsed);
    END;
    coge_paleta(F,co2);
    bytesporlinea:=(CARDINAL(InfoBitmap.biWidth)+3) DIV 4;
    bpl4:=LONGINT(bytesporlinea*4);
    FIO.Seek(F,LONGCARD(InfoFile.bfOffbits));(*Coloco la lectura al pricipio de los datos*)
    aux:=FIO.RdBin(F,image^,64000);
	 PonPaleta(co2);
    FOR j:=1 TO 200 DO
        FOR i:=1 TO 320 DO
            Plot(i,200-j,CARDINAL(image^[j*320+i]));
        END;
    END;
    HLine(0,0,320,0);
    Line(319,0,319,200,0);
    END;
    DISPOSE(image);
END muestra;

PROCEDURE coge_sprite(F:FIO.File;x0,y0,x1,y1:LONGINT):matriz;
VAR
  InfoFile : BITMAPFILEHEADER;
  InfoBitmap : BITMAPINFOHEADER;
  co2 : TipoPaleta;
  aux,registro:CARDINAL;
  x,y,bpl4:LONGINT;
  byte1,r,g,b:CHAR;
  bol:BOOLEAN;
  ncol,bytesporlinea,n,paleta,i,j:CARDINAL;
  valor,r2,g2,b2:LONGCARD;
  real:REAL;
  imagenn:matriz;

BEGIN
    x:=y0;
    y0:=y1;
    y1:=x;
    y0:=200-y0;
    y1:=200-y1;
    FIO.Seek(F,10);(*Se posiciona el cursor en el sitio para empezar a leer*)
    aux:=FIO.RdBin(F,InfoFile.bfOffbits,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biSize,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biWidth,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biHeight,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biPlanes,SIZE(INTEGER));
    aux:=FIO.RdBin(F,InfoBitmap.biBitCount,SIZE(INTEGER));
    aux:=FIO.RdBin(F,InfoBitmap.biCompression,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biSizeImage,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biXpelsPerMeter,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biYpelsPerMeter,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biClrUsed,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biClrImportant,SIZE(LONGINT));
    IF InfoBitmap.biClrUsed=0 THEN
       ncol:=CARDINAL(Pow(2.0,LONGREAL(InfoBitmap.biBitCount)));
    ELSE
       ncol:=CARDINAL(InfoBitmap.biClrUsed);
    END;
    coge_paleta(F,co2);
    bytesporlinea:=(CARDINAL(InfoBitmap.biWidth)+3) DIV 4;
    bpl4:=LONGINT(bytesporlinea*4);
    FIO.Seek(F,LONGCARD(InfoFile.bfOffbits));(*Coloco la lectura al pricipio de los datos*)
    i:=0;
    j:=0;
    PonPaleta(co2);
    FOR y:=y0 TO y1 DO
        FIO.Seek(F,LONGCARD(InfoFile.bfOffbits+(y1+y0-y+1)*bpl4+x0));
        FOR x:=x0 TO x1 DO
            aux:=FIO.RdBin(F,byte1,SIZE(CHAR));
            registro:=ORD(byte1);
            imagenn[i,j]:=CHAR(registro);
            i:=i+1;
        END;
        j:=j+1;
        i:=0;
    END;
    RETURN(imagenn);
END coge_sprite;

PROCEDURE mascara(imagenn:matriz;x2,y2:LONGINT);
VAR
  x,y:LONGINT;
  i,j:CARDINAL;
  mascara: CHAR;
BEGIN
    i:=0;
    j:=0;
    mascara:= imagenn[1,1];
    FOR y:=y2 TO y2+ymax DO
        FOR x:=x2 TO x2+xmax DO
            IF imagenn[i,j] <> mascara THEN
               Plot(CARDINAL(x),CARDINAL(y),CARDINAL(imagenn[i,j]));
            END;
            i:=i+1;
        END;
        j:=j+1;
        i:=0;
    END;
END mascara;

(* ----------------------------- *)

PROCEDURE muestraXY(imagenn:matriz;x2,y2:LONGINT);
VAR
  x,y:LONGINT;
  i,j:CARDINAL;
  mascara: CHAR;
BEGIN
    i:=0;
    j:=0;
    FOR y:=y2 TO y2+ymax DO
        FOR x:=x2 TO x2+xmax DO
              Plot(CARDINAL(x),CARDINAL(y),CARDINAL(imagenn[i,j]));
            i:=i+1;
        END;
        j:=j+1;
        i:=0;
    END;
END muestraXY;

(* ------------------------------ *)

(* PROCEDURE mascara(sprite:matriz):matriz;
VAR resultado:matriz;
    i,j:CARDINAL;
BEGIN
    FOR i:=0 TO xmax DO
        FOR j:=0 TO ymax DO
            IF sprite[i,j]=CHR(0) THEN
               resultado[i,j]:=CHR(255);
            ELSE
               resultado[i,j]:=CHR(0);
            END;
        END;
    END;
    RETURN(resultado);
END mascara; *)




PROCEDURE FadeOut(paleta : TipoPaleta);
VAR palet,n:CARDINAL;
    contador : SHORTCARD;
    colores:TipoPaleta;
    valor,r,g,b:LONGCARD;
CONST velocidad=2;
BEGIN
  FOR n:=0 TO 255 DO
      colores[n]:=paleta[n];
  END;
  FOR contador:=0 TO 70 DO
    Delay(30);
    FOR n:=0 TO 255 DO
 (*       r:=colores[n] MOD 256; *)
 (*       g:=(colores[n] DIV 256) MOD 256; *)
 (*       b:=colores[n] DIV 65536; *)

        IF (colores[n].r>=velocidad) THEN
            colores[n].r:=colores[n].r-velocidad;
        END;
        IF (colores[n].g>=velocidad) THEN
            colores[n].g:=colores[n].g-velocidad;
        END;
        IF (colores[n].b>=velocidad) THEN
            colores[n].b:=colores[n].b-velocidad;
        END;
        Actualiza(SHORTCARD(n),colores[n].r,colores[n].g,colores[n].b);
     END;
  END;
END FadeOut;
(* ----------------------------------------------------------------*)
PROCEDURE Telon();
VAR
  cont : CARDINAL;
BEGIN
    FOR cont := 2 TO 100 DO
        Graph.Rectangle(0,cont - 2,320,cont,0,TRUE);
        Graph.Line(0,cont,320,cont,10);
        Graph.Rectangle(0,200-cont+2,320,200-cont,0,TRUE);
        Graph.Line(0,200-cont,320,200-cont,10);
        Delay(15);
    END;
    FOR cont:= 2 TO 160 DO
        Graph.Rectangle(cont-2,80,cont,110,0,TRUE);
        Graph.Rectangle(320-cont+2,80,320-cont,110,0,TRUE);
        Delay(5);
    END;
    Delay(100);
END Telon;

(* --------------------------------------------------------------- *)

PROCEDURE FadeIn(F : FIO.File);

VAR
  InfoFile : BITMAPFILEHEADER;
  InfoBitmap : BITMAPINFOHEADER;
  final, inicial : TipoPaleta;
  aux,registro:CARDINAL;
  x,y,bpl4:LONGINT;
  byte1,r,g,b:CHAR;
  bol:BOOLEAN;
  ncol,bytesporlinea,n,paleta,color,intensidad,i,j,Size:CARDINAL;
  valor,r2,g2,b2:LONGCARD;
  real:REAL;
  image,imag2:puntero;

BEGIN
    FOR n:= 0 TO 255 DO
    	inicial[n].r:= 0;
    	inicial[n].g:= 0;
    	inicial[n].b:= 0;
    END;	
    IF Storage.Available(CARDINAL(FIO.Size(F))) THEN
    NEW(image);
    FIO.Seek(F,10);(*Se posiciona el cursor en el sitio para empezar a leer*)
    aux:=FIO.RdBin(F,InfoFile.bfOffbits,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biSize,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biWidth,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biHeight,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biPlanes,SIZE(INTEGER));
    aux:=FIO.RdBin(F,InfoBitmap.biBitCount,SIZE(INTEGER));
    aux:=FIO.RdBin(F,InfoBitmap.biCompression,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biSizeImage,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biXpelsPerMeter,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biYpelsPerMeter,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biClrUsed,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biClrImportant,SIZE(LONGINT));
    IF InfoBitmap.biClrUsed=0 THEN
       ncol:=CARDINAL(Pow(2.0,LONGREAL(InfoBitmap.biBitCount)));
    ELSE
       ncol:=CARDINAL(InfoBitmap.biClrUsed);
    END;
    coge_paleta(F,final);
    bytesporlinea:=(CARDINAL(InfoBitmap.biWidth)+3) DIV 4;
    bpl4:=LONGINT(bytesporlinea*4);
    FIO.Seek(F,LONGCARD(InfoFile.bfOffbits));(*Coloco la lectura al pricipio de los datos*)
    aux:=FIO.RdBin(F,image^,64000);
	PonPaleta(inicial);
    FOR j:=1 TO 200 DO
        FOR i:=1 TO 320 DO
            Plot(i,200-j,CARDINAL(image^[j*320+i]));
        END;
    END;
    HLine(0,0,320,0);
    Line(319,0,319,200,0);
    FOR intensidad:= 0 TO 255 DO
    	FOR color:= 0 TO 255 DO
    		IF inicial[color].r < final[color].r THEN
    			INC(inicial[color].r);
    		END;
    		IF inicial[color].g < final[color].g THEN
    			INC(inicial[color].g);
    		END;	
    	    IF inicial[color].b < final[color].b THEN
    			INC(inicial[color].b);
    		END;
        END;
        Delay(5);
    	PonPaleta(inicial);
    END;
    END;
    DISPOSE(image);
END FadeIn;

(* ---------------------------------------------------------------- *)
PROCEDURE RotarPaleta(VAR palet : TipoPaleta);
VAR
  ant, sig : color;
  n : CARDINAL;
BEGIN
    ant:= palet[255];
    FOR n:= 255 TO
    2 BY -1 DO
        palet[n]:= palet[n - 1];
    END;
    palet[1]:= ant;
END RotarPaleta;

(* ---------------------------------------------------------------- *)

PROCEDURE LeerPaleta(VAR palett : TipoPaleta;fichero : ARRAY OF CHAR;VAR existe :BOOLEAN);
VAR
color : CARDINAL;
file : FIO.File;
BEGIN
     color:= 0;
     IF FIO.Exists(fichero) THEN
        existe:= TRUE;
        file:= FIO.Open(fichero);
        WHILE NOT(FIO.EOF) AND (color <= 255) DO
              palett[color].r:= FIO.RdShtCard(file);
              palett[color].g:= FIO.RdShtCard(file);
              palett[color].b:= FIO.RdShtCard(file);
              INC(color);
        END;
        FIO.Close(file);
     ELSE
        existe:= FALSE;
     END;
END LeerPaleta;

(* ----------------------------------------------------- *)

PROCEDURE UP();
VAR
regs: SYSTEM.Registers;
n : CARDINAL;
pulsa : CHAR;
F : FIO.File;
existe : BOOLEAN;
BEGIN
    regs.AL:= 1;
    regs.AH:= 06H;
    regs.BH:=  0;
    regs.CL:=  0;
    regs.CH:=  0;
    regs.DL:=  50;
    regs.DH:=  24;
    FOR n:= 1 TO 25 DO
        Intr(regs,16);
    END;

END UP;
(* ------------------------------------------------------------------- *)

PROCEDURE Zoom(sprite: matriz; x, y, Factor : CARDINAL);
VAR
  i,j, v,h : CARDINAL;
BEGIN
     i:=0;
     j:=0;
	 FOR v:=y TO y+(ymax*Factor) DO
        FOR h:=x TO x+(xmax*Factor) DO
            Plot(h,v,CARDINAL(sprite[i,j]));
            i:= (h-x) DIV Factor;
        END;
        j:= (v-y) DIV Factor;
        i:=0;
    END;

END Zoom;
(* ------------------------------------------------------------------ *)

PROCEDURE round(numero : LONGREAL): LONGINT;
VAR
  entera: LONGINT;
  decimal: LONGREAL;
BEGIN
    entera:= LONGINT(TRUNC(numero));
    decimal:= numero - LONGREAL(TRUNC(numero));
    IF decimal > 0.5 THEN
       entera:= entera + 1;
    END;
    RETURN entera;
END round;
(* --------------------------------- *)

(* ----------------- *)

PROCEDURE rotar(imagen: bmp.matriz; ang: LONGREAL;x2,y2: LONGINT; xc,yc: LONGINT);
VAR
  x,y:LONGINT;
  i,j, hor, vert:CARDINAL;
  mascara: CHAR;
  angulo: LONGREAL;
BEGIN
    i:=0;
    j:=0;
    mascara:= imagen[1,1];
    angulo:= ang*2.0*3.14/360.0;
    FOR y:=1 TO ymax DO
        FOR x:=1 TO xmax DO
            IF imagen[i,j] <> mascara THEN
               hor:=  CARDINAL(ABS( LONGREAL(xc) +
                      LONGREAL(x2+x-xc)*Cos(LONGREAL(angulo)) + LONGREAL(y2+y-yc)*Sin(LONGREAL(angulo))));
               vert:=  CARDINAL(ABS( LONGREAL(yc) +
                      LONGREAL(y+y2-yc)*Cos(LONGREAL(angulo)) - LONGREAL(x+x2-xc)*Sin(LONGREAL(angulo))));
               Plot(hor,vert,CARDINAL(imagen[i,j]));
            END;
            i:=i+1;
        END;
        j:=j+1;
        i:=0;
    END;
END rotar;
(* ------------------- *)




(* --------------------------------------------------------- *)
(* *)  (* PROCEDIMIENTOS DINAMICOS       *)               (* *)
(* *)                                                     (* *)
(* *)                                                     (* *)
(* --------------------------------------------------------- *)

(* ---------------   PROCEDIMIENTOS OPACOS INTERNOS -------------- *)

(* --------------------------------------------------------- *)

PROCEDURE Preparar(VAR sprite : SPRITE_D);
VAR
BEGIN
  sprite:= NIL;
END Preparar;

(* --------------------------------------------------------- *)

PROCEDURE Esfinx(x,xfin: LONGINT): BOOLEAN;
VAR
BEGIN
   RETURN (x = xfin);
END Esfinx;
(* --------------------------------------------------------- *)

PROCEDURE Insertar(VAR lista: SPRITE_D; finx: BOOLEAN; color: CHAR);
VAR
  ptr,aux: SPRITE_D;
BEGIN
    NEW(aux);
    aux^.sig:= NIL;
    aux^.color:= color;
    aux^.finx:= finx;
    IF lista = NIL THEN;
       lista:= aux;
    ELSE
       ptr:= lista;
       WHILE ptr^.sig <> NIL DO
             ptr:= ptr^.sig;
       END;
       ptr^.sig:= aux;
    END;

END Insertar;
(* ------------------------- *)
PROCEDURE Tamx(sprite: SPRITE_D): CARDINAL;
VAR
  TAM: CARDINAL;
  aux: SPRITE_D;
BEGIN
    TAM:= 0;
    aux:= sprite;
    WHILE (aux^.sig <> NIL) AND NOT (aux^.finx) DO
          INC(TAM);
    END;
    RETURN TAM;
END Tamx;


(* --------------------------------------------------------- *)
PROCEDURE PosInicio(x : LONGINT; VAR puntero: SPRITE_D);
VAR
  inicio: LONGINT;
BEGIN
    inicio:= ABS(x);
    WHILE (puntero^.sig # NIL) AND (inicio >= 0) DO
        DEC(inicio);
        puntero:= puntero^.sig;
    END;
END PosInicio;
(* --------------------------------------------------------- *)
PROCEDURE PosyInicio(VAR x : LONGINT; VAR puntero: SPRITE_D);
VAR
  inicio: LONGINT;
BEGIN


END PosyInicio;
(* --------------------------------------------------------- *)

(* ------------ PROCEDIMIENTOS EXPORTABLES ----------------- *)

(* --------------------------------------------------------- *)
PROCEDURE DESTRUIR(VAR sprite: SPRITE_D);
VAR
  aux: SPRITE_D;
BEGIN
    WHILE sprite <> NIL DO
          aux:= sprite;
          sprite:= sprite^.sig;
          DISPOSE(aux);
    END;
END DESTRUIR;
(* --------------------------------------------------------- *)

PROCEDURE DCSPRITE(F:FIO.File;x0,y0,x1,y1:LONGINT):SPRITE_D;
VAR
  InfoFile : BITMAPFILEHEADER;
  InfoBitmap : BITMAPINFOHEADER;
  co2 : TipoPaleta;
  aux,registro:CARDINAL;
  x,y,bpl4:LONGINT;
  byte1,r,g,b:CHAR;
  bol:BOOLEAN;
  ncol,bytesporlinea,n,paleta,i,j:CARDINAL;
  valor,r2,g2,b2:LONGCARD;
  real:REAL;
  imagenn: SPRITE_D;
BEGIN
    Preparar(imagenn);
    x:=y0;     (* Intercambio las y`es para que no salga al rev‚s *)
    y0:=y1;
    y1:=x;
    y0:=200-y0;
    y1:=200-y1;
    FIO.Seek(F,10);(*Se posiciona el cursor en el sitio para empezar a leer*)
    aux:=FIO.RdBin(F,InfoFile.bfOffbits,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biSize,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biWidth,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biHeight,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biPlanes,SIZE(INTEGER));
    aux:=FIO.RdBin(F,InfoBitmap.biBitCount,SIZE(INTEGER));
    aux:=FIO.RdBin(F,InfoBitmap.biCompression,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biSizeImage,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biXpelsPerMeter,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biYpelsPerMeter,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biClrUsed,SIZE(LONGINT));
    aux:=FIO.RdBin(F,InfoBitmap.biClrImportant,SIZE(LONGINT));
    IF InfoBitmap.biClrUsed=0 THEN
       ncol:=CARDINAL(Pow(2.0,LONGREAL(InfoBitmap.biBitCount)));
    ELSE
       ncol:=CARDINAL(InfoBitmap.biClrUsed);
    END;
    coge_paleta(F,co2);
    bytesporlinea:=(CARDINAL(InfoBitmap.biWidth)+3) DIV 4;
    bpl4:=LONGINT(bytesporlinea*4);
    FIO.Seek(F,LONGCARD(InfoFile.bfOffbits));(*Coloco la lectura al pricipio de los datos*)
    i:=0;
    j:=0;
    PonPaleta(co2);
    FOR y:=y0 TO y1 DO
        FIO.Seek(F,LONGCARD(InfoFile.bfOffbits+(y1+y0-y+1)*bpl4+x0));
        FOR x:=x0 TO x1 DO
            aux:=FIO.RdBin(F,byte1,SIZE(CHAR));
            registro:=ORD(byte1);
            Insertar(imagenn,Esfinx(x1,x),CHAR(registro));
        END;
    END;
    RETURN(imagenn);

END DCSPRITE;

(* ------------------------------------- *)

PROCEDURE DMASCARA( sprite : SPRITE_D; xPantalla, yPantalla : LONGINT; modo : BOOLEAN);
VAR
  x,y, xp, yp:LONGINT;
  i,j:LONGINT;
  mascara: CHAR;
  actual: SPRITE_D;
BEGIN
  xp:= xPantalla;
  yp:= yPantalla;
  mascara:= sprite^.color;
  actual:= sprite;
  y:= yp;
  x:=xp;
  WHILE (actual <> NIL) AND (y <= 200) DO
       IF (actual^.finx) THEN
          x:= xp;
          INC(y);
       ELSE
          INC(x);
       END;
       IF modo THEN
         IF (actual^.color <> mascara) THEN
           IF (x > 0) AND (y > 0) THEN
            Plot(CARDINAL(x),CARDINAL(y),CARDINAL(actual^.color));
           END;
         END;
       ELSE        (* Recortamos el sprite si la pos x es negativa, *)
          IF (x > 0) AND (y > 0) THEN
            Plot(CARDINAL(x),CARDINAL(y),CARDINAL(actual^.color));
           END;
       END;
       actual:= actual^.sig;
    END;

END DMASCARA;

(* --------------------------------------------------------- *)

(* ------------- *)
PROCEDURE Dcapa(sprite : bmp.SPRITE_D; xPantalla, yPantalla : LONGINT; modo : BOOLEAN;capa: CARDINAL);
VAR
  x,y, xp, yp:LONGINT;
  i,j:LONGINT;
  mascara: CHAR;
  actual: bmp.SPRITE_D;
  fondo: CARDINAL;
BEGIN
  xp:= xPantalla;
  yp:= yPantalla;
  mascara:= sprite^.color;
  actual:= sprite;
  y:= yp;
  x:=xp;
  WHILE (actual <> NIL) AND (y <= 200) DO
       IF (actual^.finx) THEN
          x:= xp;
          INC(y);
       ELSE
          INC(x);
       END;
       IF modo THEN
         IF (actual^.color <> mascara) THEN
           IF (x > 0) AND (y > 0) THEN
            fondo:= Graph.Point(CARDINAL(x),CARDINAL(y));
            IF fondo = capa THEN
	            Graph.Plot(CARDINAL(x),CARDINAL(y),CARDINAL(actual^.color));
	         END;
           END;
         END;
       ELSE        (* Recortamos el sprite si la pos x es negativa, *)
          IF (x > 0) AND (y > 0) THEN
            Graph.Plot(CARDINAL(x),CARDINAL(y),CARDINAL(actual^.color));
           END;
       END;
       actual:= actual^.sig;
    END;

END Dcapa;
(* --------------- *)


END bmp.

