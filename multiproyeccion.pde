// multiproyección
// Author: David Montero - October 2012
// javacvPro library from X. HINAULT

import ipcapture.*; // Librería para captura de vídeo sobre IP
import processing.video.*;
import monclubelec.javacvPro.*;

// Definición de constantes
int ROWS=6;  // constante que define el número de filas
int COLUMNS=8;  // constante que define el número de columnas
int NBOXES=ROWS*COLUMNS; 
int FPS = 25; // Marcos por segundo

IPCapture cam;
//Capture cam;     // Capture class para la entrada de cámara
OpenCV opencv;         


PImage[] frameBuffer = new PImage[10*FPS]; // Array para almacenar todos los marcos de los últimos 10 segundos (a 25 fps)
int frameIdx = 0; // Índice para recorrer el array de marcos
int delayOne = 0; // Índice para recorrer el array de marcos con el primer retardo
int delayTwo = 0; // Índice para recorrer el array de marcos con el segundo retardo

int idx=0;

PImage gradientFrame; // Imágen de cámara con efecto halo
PImage whiteImage; // Imágen negra para "limpiar" las celdas
PImage modifiedFrame; 

int offset = 10; // Separación entre videos

int movementThreshold = 100; // Valor umbral para detectar si hay movimento, número de píxeles diferentes al anterior marco
boolean enabled = false; // Activado cuando hay un sujeto delante de la cámara

// Resolución de la captura de vídeo
int widthCapture=320;
int heightCapture=240;

int widthImg = widthCapture/2;
int heightImg = heightCapture/2;

// Parámetros para el algoritmo de eliminación del fondo
// valores por defecto : history = 16; varThreshold = 16, bShadowDetection= true
int threshold = 16;
int history = 1000;
boolean bShadowDetection = true;
boolean playDelayOne = false;
boolean playDelayTwo = false;

// Valor de incremento del canal de rojos
int redInc = 255;
// Valor de decremento de los canales verde y azul
int gbDec = 255;


void setup() { 
  frame.removeNotify(); 
  // Remove the windows frame
  frame.setUndecorated(true);
// set full screen
  size(displayWidth, displayHeight);  
  background(255);

  frameRate(FPS);

  gradientFrame = new PImage(widthCapture, heightCapture);
  whiteImage = new PImage(widthCapture, heightCapture);
  modifiedFrame = new PImage(widthCapture, heightCapture);

  // Crear una imágen negra para el fondo
  setWhite(whiteImage);

  // Inizializar el array de marcos
  for (int i=0; i<frameBuffer.length; i++) {
    frameBuffer[i] = new PImage(widthCapture, heightCapture);
    setWhite(frameBuffer[i]);
  }
  // Poner aquí la URL el username y el password the la cámara, si no tiene username ni password símplemente escribir "" (dobles comillas)
  cam = new IPCapture(this, "http://10.64.123.200:80/video1.mjpg", "username", "password");
  //cam = new Capture(this, widthCapture, heightCapture, FPS);  // Initializar la captura de cámara
  cam.start();  // arrancar la cámara

  opencv = new OpenCV(this); // Inicialización de los objetos OpenCV (librería javacvPro : tratamiento de imagen y reconocimiento visual) 
  opencv.allocate(widthCapture, heightCapture); // Crear el buffer para las imágenes procesadas por OpenCV

  //--- Initialización del objeto MOG que nos permite eliminar el fondo
  opencv.bgsMOG2Init(history, threshold, bShadowDetection); 

//  size((widthImg+offset)*COLUMNS, (heightImg+offset)*ROWS); //Tamaño de la pantalla
//  if (frame != null) {
//    frame.setResizable(true);
//  }
}


void  draw() { // función que se ejecuta 60 veces por segundo (valor por defecto)
  PImage diff=new PImage(widthCapture, heightCapture); // Imágen que contiene la diferencia de marcos
  PImage invertedFrame=new PImage(widthCapture, heightCapture); // Imágen que contiene la vista de cámara invertida horizontalmente

    //if (cam.available() == true) { // si hay un nuevo marco disponible en la cámara
    if (cam.isAvailable() == true) { // si hay un nuevo marco disponible en la cámara
    cam.read(); // leemos un marco
    opencv.copy(cam); // copiamos el marco en el buffer de openCV
    opencv.flip(opencv.HORIZONTAL); // invertimos la imagen horizontalmente para hacer efecto espejo
    invertedFrame = opencv.getBuffer();
    opencv.blur(7); // Le aplicamos un filtro de difusión para suavizar los colores (ayuda a eliminar el ruido en la substracción de fondo)
    opencv.bgsMOG2Apply(opencv.Buffer, opencv.BufferGray, -1); // eliminamos el fondo y copiamos el resultado en el buffer de escala de grises de OpenCV
    diff = opencv.getBufferGray(); // copiamos el buffer de escala de grises en la imagen diff

    createFrame(invertedFrame, diff); // Modificamos la imágen y generamos el resultado

    displayGrid(); // Mostramos los videos en pantalla
  }
  if (redInc > 0) redInc--;
  if (gbDec > 0) gbDec--;
}

void createFrame(PImage camFrame, PImage diff) {
  PImage redFrame = new PImage(widthCapture, heightCapture);
  int amountMovement=0; // Variable para detectar si hay movimiento
  diff.loadPixels();
  gradientFrame.loadPixels();
  redFrame.loadPixels();
  camFrame.loadPixels();
  for (int x=0;x< diff.width;x++) {
    for (int y=0;y< diff.height;y++) {
      int loc = x + y*diff.width;
      // Extraemos los valores RGB del marco de video
      float r = red(camFrame.pixels[loc]); 
      float g = green(camFrame.pixels[loc]);
      float b = blue(camFrame.pixels[loc]);
      if (diff.pixels[loc]!=color(0, 0, 0)) {
        amountMovement++; // Si encontramos un pixel diferente al fondo quiere decir que hay movimiento, incrementamos el valor
        // Creamos un efecto halo en la imágen modificada
        float maxdist = camFrame.height/4;
        float d = dist(x, y, camFrame.width/2, camFrame.height/2);
        float adjustbrightness = 255*(maxdist-d)/maxdist;
        r += adjustbrightness;
        g += adjustbrightness;
        b += adjustbrightness;
        redFrame.pixels[loc]=color(r+redInc, g-gbDec, b-gbDec);//Aumentamos el canal de rojos y disminuimos el de azul y verde
      }
      else {
        // Ponemos el fondo de la imagen a blanco
        redFrame.pixels[loc]=color (255);
      }
      // Creamos un efecto halo en la imágen de cámara
      float maxdist = camFrame.height/4;
      float d = dist(x, y, camFrame.width/2, camFrame.height/2);
      float adjustbrightness = 200*(d-maxdist)/maxdist;
      r += adjustbrightness;
      g += adjustbrightness;
      b += adjustbrightness;
      // Nos aseguramos que los valores RGB están dentro del rango de color 0-255
      r = constrain(r, 0, 255);
      g = constrain(g, 0, 255);
      b = constrain(b, 0, 255);
      // Asignamos el nuevo color a la imagen que mostraremos en pantalla
      gradientFrame.pixels[loc] = color(r, g, b);
    }
  }
  redFrame.updatePixels();
  gradientFrame.updatePixels();
  if (amountMovement > movementThreshold) {
    //Si hay suficiente cantidad de movimiento mostrar la imagen, si no mostrar la imagen de cámara e inicializar los contadores de RGB  
    enabled = true; // Se activa mostrar la silueta
    frameBuffer[frameIdx]=redFrame;
    modifiedFrame = redFrame;
    if (frameIdx > FPS/2) {
      playDelayOne=true; // Tras dos segundos empezamos a reproducir el vídeo en otras celdas
      if (++delayOne == frameBuffer.length-1) delayOne = 0; // Reinicializar el índice del último segundo cuando alcanzamos el final del array
    }
    if (frameIdx > FPS) {
      playDelayTwo=true; // Tras dos segundos empezamos a reproducir el vídeo en otras celdas
      if (++delayTwo == frameBuffer.length-1) delayTwo = 0; // Reinicializar el índice de los últimos 2 segundos cuando alcanzamos el final del array
    }
    if (++frameIdx == frameBuffer.length-1) frameIdx= 0; // Poner el índice a cero cuando hemos llenado el buffer
  }
  else {
    // Si no mostramos la imágen de la cámara con el efecto halo y reinicializamos los incrementos/decrementos de RGB
    enabled = false; 
    redInc=255;
    gbDec=255;
    frameIdx=0;
    delayOne=0;
    delayTwo=0;
  }
}

void displayGrid() {
  PImage displayFrame = new PImage(widthCapture, heightCapture);
  for (int gridX=0; gridX < COLUMNS*(widthImg+offset); gridX+=widthImg+offset) {
    for (int gridY=0; gridY < ROWS*(heightImg+offset); gridY+=heightImg+offset) {
      int i = gridX + gridY*COLUMNS;
      if (enabled) {
        switch (i%3) {
        case 0:
          displayFrame=modifiedFrame.get();
          break;
        case 1:
          if (playDelayOne) {
            displayFrame=frameBuffer[delayOne].get();
          }
          else {
            displayFrame=whiteImage.get();
          }
          break;
        case 2:
          if (playDelayTwo) {
            displayFrame=frameBuffer[delayTwo].get();
          }
          else {
            displayFrame=whiteImage.get();
          }
          break;
        }
      }
      else {
        displayFrame=gradientFrame.get();
      }    
      // Reducimos el tamaño de la imagen a mostrar en pantalla
      displayFrame.resize(widthImg, heightImg);
      set(gridX, gridY, displayFrame);
    }
  }
}

void setWhite(PImage img) {
  img.loadPixels();
  for (int i=0; i<img.pixels.length; i++) {
    img.pixels[i]=color(255);
  }
  img.updatePixels();
}

void keyPressed() {    
  switch (key) {
  case CODED:
    switch (keyCode)
    {
    case UP:
      threshold++;
      println("Threshold ++ : "+threshold);
      break;
    case DOWN:
      threshold--;
      println("Threshold -- : "+threshold);
      break;
    case LEFT:
      history--;
      println("History -- : "+history);
      break;
    case RIGHT:
      history++;
      println("History ++ : "+history);
      break;
    }
    break;
  case '+':
    offset++;
    println("Offset ++ : "+offset);
    //frame.setSize((widthImg+offset)*COLUMNS, (heightImg+offset)*ROWS);
    background(255);
    break;
  case '-':
    offset--;
    println("Offset -- : "+offset);
    background(255);
    //frame.setSize((widthImg+offset)*COLUMNS, (heightImg+offset)*ROWS);
    break;
  default:
    if (bShadowDetection) {
      bShadowDetection=false;
      println("Shadow Detection DISABLED");
    }
    else {
      bShadowDetection=true;
      println("Shadow Detection ENABLED");
    }
    break;
  }
}

