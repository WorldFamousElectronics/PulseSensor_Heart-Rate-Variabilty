/*     PulseSensor Amped HRV Frequency Domain Plotter v1.1.0

This is an HRV visualizer code for Pulse Sensor.  www.pulsesensor.com
Use this with PulseSensorAmped_Arduino_1.5.0 code and the Pulse Sensor Amped hardware.
This code will track Heart Rate Variabilty by tracing the changes in IBI values
over the frequency domain. The code looks for a change in the trend of IBI values,
up or down, and calculates the frequency using the last peak or trough.
Thus deriving the IBI frequency based on 1/2 wave data.

key press commands included in this version:
  press 'S' to take a picture of the data window. (JPG image saved in Sketch folder)
  press 'C' to refresh the graph
  press 'W' to show or hide the IBI waveform (as seen in Time Domain example)
Created by Joel Murphy, Summer 2013
This code released into the public domain without promises that it will work for your intended application.
Or that it will work at all, for that matter. I hereby disclaim.
*/

import processing.serial.*;  // serial library lets us talk to Arduino
PFont font;
Serial port;

float freq;               // used to hold derived HRV frequency
float runningTotal = 1;   // can't initialize as 0 because math
float mean;               // useful for VLF derivation...........
int IBI;                  // length of time between heartbeats in milliseconds (sent from Arduino, updated in serialEvent)
int P;                    // peak value of IBI waveform
int T;                    // trough value of IBI waveform
int amp;                  // amplitude of IBI waveform
int lastIBI;              // value of the last IBI sent from Arduino
int[] PPG;                // array of raw Pulse Sensor datapoints
int[] beatTime;           // array of IBI values to graph on Y axis
float[] powerPointX;      // array of power spectrum power points
float[] powerPointY;      // used to plot on screen
int pointCount = 0;       // used to help fill the powerPoint arrays
int windowWidth = 550;    // width of data window
int windowHeight = 550;   // height  of data window
color eggshell = color(255, 253, 248);

String direction = "none";  // used in verbose feedback

// initializing flags
boolean pulse = false;    // made true in serialEvent when new IBI value sent from arduino
boolean first = true;     // try not to screw up if it's the first time
boolean showWave = false; // show or not show the IBI waveform on screen
boolean goingUp;          // used to keep track of direction of IBI wave

// SERIAL PORT STUFF TO HELP YOU FIND THE CORRECT SERIAL PORT
String serialPort;
String[] serialPorts = new String[Serial.list().length];
boolean serialPortFound = false;
Radio[] button = new Radio[Serial.list().length*2];
int numPorts = serialPorts.length;
boolean refreshPorts = false;

void setup() {
  size(800,650);                     // stage size
  frameRate(60);                     // frame rate
  beatTime = new int[windowWidth];   // the beatTime array holds IBI graph data
  PPG = new int[150];                // PPG array that that prints heartbeat waveform
  powerPointX = new float[150];      // these arrays hold the power spectrum point coordinates
  powerPointY = new float[150];

  // set data traces to default
  resetDataTraces();


  font = loadFont("Arial-BoldMT-36.vlw");
  textFont(font);        // general Processing tasks when using text
  textAlign(CENTER);     // text and shapes will be referenced to their center points
  rectMode(CENTER);

  background(0);
  drawDataWindows();

// GO FIND THE ARDUINO
  fill(eggshell);
  text("Select Your Serial Port",350,50);
  listAvailablePorts();

}  // END OF SETUP


void draw(){
if(serialPortFound){
  // ONLY RUN THE VISUALIZER AFTER THE PORT IS CONNECTED
   background(0);
//  DRAW THE BACKGROUND ELEMENTS AND TEXT
    drawDataWindows();
    writeAxisLabels();



//  when we get heartbeat data, try to find the latest HRV freq if it is available
  if (pulse == true){                           // check for new data from arduino
    pulse = false;                              // drop the pulse flag, it gets set in serialEvent

    if (IBI < lastIBI && goingUp == true){  // check for IBI wave peak
      goingUp = false;                 // now changing direction from up to down
      direction = "down";              // used in verbose feedback
      freq = (runningTotal/1000) *2;   // scale milliseconds to seconds account for 1/2 wave data
      freq = 1/freq;                   // convert time IBI trending up to Hz
      runningTotal = 0;                // reset this for next time
      amp = P-T;                       // measure the size of the IBI 1/2 wave that just happend
      mean = P-amp/2;                  // the average is useful for VLF derivation.......
      T = lastIBI;                     // set the last IBI as the most recent trough cause we're going down
      powerPointX[pointCount] = map(freq,0,1.2,75,windowWidth+75);  // plot the frequency
      powerPointY[pointCount] = height-(35+amp);  // amp determines 'power' of signal
      pointCount++;                    // build the powerPoint array
      if(pointCount == 150){pointCount = 0;}      // overflow the powerPoint array
    }

    if (IBI > lastIBI && goingUp == false){  // check for IBI wave trough
      goingUp = true;                  // now changing direction from down to up
      direction = "up";                // used in verbose feedback
      freq = (runningTotal/1000) * 2;  // scale milliseconds to seconds, account for 1/2 wave data
      freq = 1/freq;                   // convert time IBI trending up to Hz
      runningTotal = 0;                // reset this for next time
      amp = P-T;                       // measure the size of the IBI 1/2 wave that just happend
      mean = P-amp/2;                  // the average is useful for VLF derivation.......
      P = lastIBI;                     // set the last IBI as the most recent peak cause we're going up
      powerPointX[pointCount] = map(freq,0,1.2,75,windowWidth+75);  // plot the frequency
      powerPointY[pointCount] = height-(35+amp); // amp determines 'power' of signal
      pointCount++;                    // build the powerPoint array
      if(pointCount == 150){pointCount = 0;}      // overflow the powerPoint array
    }

    if (IBI < T){                        // T is the trough
      T = IBI;                         // keep track of lowest point in pulse wave
    }
    if (IBI > P){                        // P is the trough
      P = IBI;                         // keep track of highest point in pulse wave
    }
    lastIBI = IBI;                     // keep track to measure the trend
    runningTotal += IBI;               // how long since IBI wave changed direction?

//  >>> this part is for IBI waveform graphing
    for (int i=0; i<beatTime.length-3; i+=3){   // shift the data in beatTime array 3 pixels left
      beatTime[i] = beatTime[i+3];              // shift the data points through the array
    }
      IBI = constrain(IBI,300,1200);            // don't let the new IBI value escape the data window!
      beatTime[beatTime.length-1] = IBI;        // update the current IBI

 }

//    DRAW THE SPECTRUM PLOT
  String F = nf(freq,1,3);  // format the freq variable so it's nice to print
  text(F+"Hz",200,100);     // print the freq variable for verbose feedback
  // first, make a vertical line at the most recent plot point in red
  stroke(250,5,180);
  line(map(freq,0,1.2,75,windowWidth+75),height-35,map(freq,0,1.2,75,windowWidth+75),(height-(35+amp)));
  stroke(255,0,0);
  for(int i=0; i<150; i++){
    ellipse(powerPointX[i],powerPointY[i],2,2);    // plot a history of data points in red
  }



//    DRAW THE IBI PLOT
if(showWave){
  stroke(0,0,255);                                // IBI graph in blue
  noFill();
  beginShape();                                   // use beginShape to draw the graph
  for (int i=0; i<=beatTime.length-1; i+=3){      // set a datapoint every three pixels
    float  y = map(beatTime[i],300,1200,615,65);  // invert and scale data so it looks normal
    vertex(i+75,y);                               // set the vertex coordinates
  }
  endShape();                                     // connect the vertices
  noStroke();
  fill(250,0,0);                                  // draw the current data point as a red dot for fun
  float  y = map(beatTime[beatTime.length-1],300,1200,615,65);  // invert and scale data so it looks normal
  ellipse(windowWidth+75,y,6,6);                  // draw latest data point as a red dot

}


 //   GRAPH THE PULSE SENSOR DATA
 fill(255,253,248);                              // eggshell white
 text("IBI: "+IBI+"mS",width-85,50);             // print latest IBI value above pulse wave window
 noFill();
 stroke(250,0,0);                                       // use red for the pulse wave
  beginShape();                                         // beginShape is a nice way to draw graphs!
  for (int i=1; i<PPG.length; i++){                   // scroll through the PPG array
    float x = width-160+i;
    float y = PPG[i];
    vertex(x,y);                                        // set the vertex coordinates
  }
  endShape();

} else { // SCAN BUTTONS TO FIND THE SERIAL PORT

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

void drawDataWindows(){
  noStroke();
  fill(eggshell);
  rect(width/2-50,height/2+15,windowWidth,windowHeight);     // draw IBI data window
  rect(width-85,(height/2)+15,150,550);                      // draw the pulse waveform window
}

void writeAxisLabels(){
  fill(eggshell);                                         // eggshell white
  text("Pulse Sensor HRV Frequency Domain",width/2-50,40);   // title
  fill(200);    // print scale values in grey
  stroke(20);
  //  X axis scale values frequency range from 0.0Hz to 1.2Hz
  for (float i=0.0; i<=1.2; i+=0.3){
    String si = nf(i,0,1);
    text(si, map(i,0,1.2,75,windowWidth+75),height-10);
    line(map(i,0,1.2,625,75),height-35,map(i,0,1.2,625,75),height-45); // grid the X axis
  }
  //  Y axis represents IBI in milliseconds
  for (int i=0; i<=1000; i+=100){         // draw Y axis lines with 100mS resolution
    if(i%200 > 0){
      text(i,40,map(i,0,1000,620,70));    // Y axis shows change in IBI (mS) since last 1/2 wave
    }
    line(75,map(i,0,1000,614,66),85,map(i,0,1000,614,66)); //grid the Y axis
  }

  noStroke();
  fill(0,200,150);                            // print axix labels in green, for fun
  text("amp", 40,170);                        // Y axis label
  text("Hz", windowWidth+30, height-10);      // X axis label
}

 void listAvailablePorts(){
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

 void autoScanPorts(){
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

void resetDataTraces(){
  // reset IBI trace
  for(int i=0; i<beatTime.length; i++){
    beatTime[i] = 300;              // initialize the IBI graph with data line at base
  }
  // reset PPG trace
  for (int i=0; i<=PPG.length-1; i++){
   PPG[i] = height/2+15;             // initialize PPG widow with data line at midpoint
  }
  // reset power point coordinates
  for (int i=0; i<150; i++){       // startup values place the coordinates at the bottom right corner
    powerPointX[i] = 625;
    powerPointY[i] = height - 35;
  }
}
