import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.serial.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class PulseSensorAmped_HRV_PoincarePlot_1_1_0 extends PApplet {

/*     PulseSensor Amped HRV Poincare Plotter v1.1.0

This is an HRV visualizer code for Pulse Sensor.
Use this with PulseSensorAmped_Arduino_1.5.0 Arduino code and the Pulse Sensor Amped hardware.
This code will draw a Poincare Plot of the IBI (InterBeat Interval) passed from Arduino.
The Poincare method of visualizing HRV trends is to plot the current IBI against the last IBI.
key press commands included in this version:
  press 'S' to save a picture of the Processing window (JPG image saved in Sketch folder)
  press 'C' to clear the Poincare Plot
  press 'L' to trace a line through the last 20 data points
Created by Joel Murphy, Early 2013.
Updated Summer 2013 for efficiency and readability
This code released into the public domain without promises that it will work for your intended application.
Or that it will work at all, for that matter. I hereby disclaim.
*/

  // Serial library makes it possible to talk to Arduino
PFont font;                  // we will use text in this sketch
Serial port;                 // instantiate the Serial port

int IBI;                  // length of time between heartbeats in milliseconds (updated in serialEvent)
int[] PPG;                // array of live PPG datapoints
int[] beatTimeX;          // array of X coordinates of Poincare Plot
int[] beatTimeY;          // array of Y coordinates of Poincare Plot
int numPoints = 100;      // size of coordinate arrays. ths sets number of displayed datapoints
int eggshell = color(255, 253, 248);
// initializing flags here
boolean pulse = false;    // pulse is made true in serialEvent when arduino sends new IBI value
boolean makeLine = false; // press 'L' to toggle a trace the last 20 dots on the Poincare Plot

// SERIAL PORT STUFF TO HELP YOU FIND THE CORRECT SERIAL PORT
String serialPort;
String[] serialPorts = new String[Serial.list().length];
boolean serialPortFound = false;
Radio[] button = new Radio[Serial.list().length*2];
int numPorts = serialPorts.length;
boolean refreshPorts = false;

public void setup() {                     // do all the sett'n up in the setup
                     // Stage size
frameRate(60);
beatTimeX = new int[numPoints];    // these two arrays hold the Poincare Plot data
beatTimeY = new int[numPoints];    // size of numPoints determines number of displayed points
PPG = new int[150];                // PPG array that that prints heartbeat waveform
// initialize data traces
resetDataTraces();

font = loadFont("Arial-BoldMT-36.vlw");
textFont(font);                    // general house-keeping in Processing
textAlign(CENTER);                 // text and shapes will be referenced to their center point
rectMode(CENTER);

background(0);
drawDataWindows();

// GO FIND THE ARDUINO
  fill(eggshell);
  text("Select Your Serial Port",350,50);
  listAvailablePorts();

}  // END OF SETUP


public void draw(){
if(serialPortFound){

   background(0);
//  DRAW THE BACKGROUND ELEMENTS AND TEXT
  drawDataWindows();
  writeAxisLabels();


//    DRAW THE POINCARE PLOT
  if (pulse == true){                    // check for new data from arduino
    pulse = false;                       // drop the pulse flag. it gets set in serialEvent
    for (int i=numPoints-1; i>0; i--){   // shift the data in n and n-1 arrays
      beatTimeY[i] = beatTimeY[i-1];
      beatTimeX[i] = beatTimeX[i-1];     // shift the data point through the array
    }
      beatTimeY[0] = beatTimeX[1];       // toss the old n into the n-1 spot
      beatTimeX[0] = IBI;                // update n with the current IBI value
    }

  fill(0,0,255);                         //  draw a history of the data points as blue dots
  for (int i=1; i<numPoints; i++){
    beatTimeX[i] = constrain(beatTimeX[i],0,1500);  // keep the values from escaping the Plot window!
    beatTimeY[i] = constrain(beatTimeY[i],0,1500);
    float  x = map(beatTimeX[i],0,1500,75,600);  // scale the data to fit the screen
    float  y = map(beatTimeY[i],0,1500,615,25);  // invert Y so it looks normal
    ellipse(x,y,2,2);                            // print datapoints as dots 2 pixel diameter
 }
   fill(250,0,0);                               // draw the most recent data point as a red dot
   float  x = map(beatTimeX[0],0,1500,75,600);  // scale the data to fit the screen
   float  y = map(beatTimeY[0],0,1500,615,25);  // invert Y so it looks normal
   ellipse(x,y,5,5);                            // print datapoint as a dot 5 pixel diameter
   fill(255,253,248);                           // eggshell white
   text("n: "+IBI+"mS",width-85,50);            // print the latest IBI value

//  TRACE THE LAST 20 DATAPOINTS IF THE OPTION IS SELECTED
  if(makeLine){                                         // toggle the makeLine flag by pressing 'L'
  stroke(0,0,255);                                      // trace the points in blue line
  noFill();
  beginShape();
  for (int i=0; i<20; i++){                             // trace the arc of n/n-1 for the last 20 points
    if(beatTimeX[i] == 0 || beatTimeY[i] == 0){break;}  // this solves for small data sets or long lines
    x = map(beatTimeX[i],0,1500,75,600);                // scale the data to fit the screen
    y = map(beatTimeY[i],0,1500,615,25);                // invert Y so it looks normal
    vertex(x,y);                                        // set the vertex coordinates
  }
  endShape();                                           // connect the vertices
  }

//   GRAPH THE PULSE SENSOR DATA
 stroke(250,0,0);                                       // use red for the pulse wave
  beginShape();                                         // beginShape is a fast way to draw lines!
  for (int i=1; i<PPG.length-1; i++){                   // scroll through the PPG array
    x = width-160+i;
    y = PPG[i];
    vertex(x,y);                                        // set the vertex coordinates
  }
  endShape();                                           // connect the vertices
  noStroke();

} else { // SCAN BUTTONS TO FIND THE SERIAL PORT

  autoScanPorts();

  if(refreshPorts){
    refreshPorts = false;
    drawDataWindows();
    listAvailablePorts();
  }

  for(int i=0; i<numPorts+1; i++){
    button[i].overRadio(mouseX,mouseY);
    button[i].displayRadio();
  }


}
}  //END OF DRAW

public void drawDataWindows(){
  noStroke();
  fill(eggshell);
  rect(width/2-50,height/2+15,550,550);     // draw Poincare Plot window
  rect(width-85,(height/2)+15,150,550);     // draw the Pulse Sensor data window

}

public void writeAxisLabels(){
  noStroke();
  fill(eggshell);                        // eggshell white
  text("Pulse Sensor HRV Poincare Plot",width/2-50,40);  // title
  fill(200);                                // draw the Plot coordinate values in grey
  text("0mS",40,height-25);                 // origin, scaled in mS
  for (int i=500; i<=1500; i+=500){         // print x axis values
    text(i, 40,map(i,0,1500,615,75));
  }
  for (int i=500; i<=1500; i+=500){         // print  Y axis values
    text(i, 75+map(i,0,1500,0,550), height-10);
  }
  stroke(250,30,250);                       // draw gridlines in purple
  for (int i=0; i<1500; i+=100){            // draw grid lines on axes
    line(75,map(i,0,1500,614,26),85,map(i,0,1500,614,26)); //y axis
    line(75+map(i,0,1500,0,549),height-35,75+map(i,0,1500,0,549),height-45); // x axis
  }
  noStroke();
  fill(255,253,10);                                    // print axes legend in yellow, for fun
  text("n", 75+map(750,0,1500, 0, 550), height-10);    // n is the most recent IBI value
  text("n-1",40,map(750,0,1500,615,75));               // n-1 is the one we got before n
}


public void listAvailablePorts(){
  println(Serial.list());    // print a list of available serial ports to the console
  serialPorts = Serial.list();
  fill(0);
  textFont(font,16);
  textAlign(LEFT);
  // set a counter to list the ports backwards
  int yPos = 0;
  int xPos = 150;
  for(int i=numPorts-1; i>=0; i--){
    button[i] = new Radio(xPos, 130+(yPos*20),12,color(180),color(80),color(255),i,button);
    text(serialPorts[i],xPos+15, 135+(yPos*20));
    yPos++;
    if(yPos > height-30){
      yPos = 0; xPos+=100;
    }
  }
  int p = numPorts;
  fill(233,0,0);
  button[p] = new Radio(xPos, 130+(yPos*20),12,color(180),color(80),color(255),p,button);
  text("Refresh Serial Ports List",xPos+15, 135+(yPos*20));

  textFont(font);
  textAlign(CENTER);
}

 public void autoScanPorts(){
  if(Serial.list().length != numPorts){
    if(Serial.list().length > numPorts){
      println("New Ports Opened!");
      int diff = Serial.list().length - numPorts;	// was serialPorts.length
      serialPorts = expand(serialPorts,diff);
      numPorts = Serial.list().length;
    }else if(Serial.list().length < numPorts){
      println("Some Ports Closed!");
      numPorts = Serial.list().length;
    }
    refreshPorts = true;
    return;
  }
 }

public void resetDataTraces(){
  // initialize the PPG
  for (int i=0; i<150; i++){
   PPG[i] = height/2+15;             // initialize PPG widow with dataline at midpoint
  }
  // initialize the poncaire points
  for (int i=numPoints-1; i>=0; i--){  //
    beatTimeY[i] = 0;
    beatTimeX[i] = 0;
  }



}

public void mousePressed(){
  if(!serialPortFound){
    for(int i=0; i<=numPorts; i++){
      if(button[i].pressRadio(mouseX,mouseY)){
        if(i == numPorts){
          if(Serial.list().length > numPorts){
            println("New Ports Opened!");
            int diff = Serial.list().length - numPorts;	// was serialPorts.length
            serialPorts = expand(serialPorts,diff);
            numPorts = Serial.list().length;
          }else if(Serial.list().length < numPorts){
            println("Some Ports Closed!");
            numPorts = Serial.list().length;
          }else if(Serial.list().length == numPorts){
            return;
          }
          refreshPorts = true;
          return;
        }else

        try{
          port = new Serial(this, Serial.list()[i], 115200);  // make sure Arduino is talking serial at this baud rate
          delay(1000);
          println(port.read());
          port.clear();            // flush buffer
          port.bufferUntil('\n');  // set buffer full flag on receipt of carriage return
          serialPortFound = true;
        }
        catch(Exception e){
          println("Couldn't open port " + Serial.list()[i]);
          fill(255,0,0);
          textFont(font,16);
          textAlign(LEFT);
          text("Couldn't open port " + Serial.list()[i],165,90);
          textFont(font);
          textAlign(CENTER);
        }
      }
    }
  }
}

public void mouseReleased(){
}

public void keyPressed(){

 switch(key){
   case 's':    // pressing 's' or 'S' will take a jpg of the processing window
   case 'S':
     saveFrame("Poincare_####.jpg");      // take a shot of that!
     break;
     // clear the Poincare plot arrays and clear the phase space by pressing C key
     // clear the screen when you press 'R' or 'r'
  case 'r':
  case 'R':
    resetDataTraces();
    break;
     // show a trace of the last 20 points in the time series, or not
    case 'L':
    case 'l':
        makeLine = !makeLine;
      break;

   default:
     break;
 }
}


class Radio {
  int _x,_y;
  int size, dotSize;
  int baseColor, overColor, pressedColor;
  boolean over, pressed;
  int me;
  Radio[] radios;

  Radio(int xp, int yp, int s, int b, int o, int p, int m, Radio[] r) {
    _x = xp;
    _y = yp;
    size = s;
    dotSize = size - size/3;
    baseColor = b;
    overColor = o;
    pressedColor = p;
    radios = r;
    me = m;
  }

  public boolean pressRadio(float mx, float my){
    if (dist(_x, _y, mx, my) < size/2){
      pressed = true;
      for(int i=0; i<numPorts+1; i++){
        if(i != me){ radios[i].pressed = false; }
      }
      return true;
    } else {
      return false;
    }
  }

  public boolean overRadio(float mx, float my){
    if (dist(_x, _y, mx, my) < size/2){
      over = true;
      for(int i=0; i<numPorts+1; i++){
        if(i != me){ radios[i].over = false; }
      }
      return true;
    } else {
      over = false;
      return false;
    }
  }

  public void displayRadio(){
    noStroke();
    fill(baseColor);
    ellipse(_x,_y,size,size);
    if(over){
      fill(overColor);
      ellipse(_x,_y,dotSize,dotSize);
    }
    if(pressed){
      fill(pressedColor);
      ellipse(_x,_y,dotSize,dotSize);
    }
  }
}

public void serialEvent(Serial port){
try{
   String inData = port.readStringUntil('\n');
   inData = trim(inData);                 // cut off white space (carriage return)

   if (inData.charAt(0) == 'S'){          // leading 'S' means sensor data
     inData = inData.substring(1);        // cut off the leading 'S'
     int newPPG = PApplet.parseInt(inData);            // convert the ascii string to ppgY
     // move the Y coordinate of the Pulse Sensor data waveform over one pixel left
     for (int i = 0; i < PPG.length-1; i++){
       PPG[i] = PPG[i+1];   // new data enters on the right at pulseY.length-1
     }
     // scale and constrain incoming Pulse Sensor value to fit inside the pulse window
     PPG[PPG.length-1] = PApplet.parseInt(map(newPPG,50,950,(height/2+15)+225,(height/2+15)-225));
     return;
   }

   if (inData.charAt(0) == 'Q'){          // leading 'Q' means time between beats in milliseconds
     inData = inData.substring(1);        // cut off the leading 'Q'
     IBI = PApplet.parseInt(inData);                   // convert ascii string to integer IBI
     pulse = true;                        // set the pulse flag
     return;
   }
} catch(Exception e) {
  // println(e.toString());
}

}
  public void settings() { 
size(800,650); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "PulseSensorAmped_HRV_PoincarePlot_1_1_0" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
