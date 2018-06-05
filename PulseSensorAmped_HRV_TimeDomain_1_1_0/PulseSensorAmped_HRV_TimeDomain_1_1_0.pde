/*     PulseSensor Amped HRV Time Domain Plotter v1.1.0

This is an HRV visualizer code for Pulse Sensor.  www.pulsesensor.com
Use this with PulseSensorAmped_Arduino_1.5.0 code and the Pulse Sensor Amped hardware.
This code will draw a line graph of the IBI (InterBeat Interval) over time as it is passed from Arduino.
The IBI plot is updated and the graph advances 3 pixels every heart beat.
key press commands included in this version:
  press 'S' to take a picture of the data window. (JPG image saved in Sketch folder)
  press 'C' to refresh the graph
Created by Joel Murphy, Spring 2013
Updated Summer 2013 for efficiency and readability
This code released into the public domain without promises that it will work for your intended application.
Or that it will work at all, for that matter. I hereby disclaim.
*/

import processing.serial.*;  // serial library lets us talk to Arduino
PFont font;
PFont portsFont;
Serial port;


int IBI;                  // length of time between heartbeats in milliseconds (updated in serialEvent)
int[] PPG;                // array of raw Pulse Sensor datapoints
int[] beatTime;           // array of IBI values to graph on Y axis
int windowWidth = 550;    // width of data window
int windowHeight = 550;   // height  of data window
color eggshell = color(255, 253, 248);

// initializing flags
boolean pulse = false;    // made true in serialEvent when new IBI value sent from arduino

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
  font = loadFont("Arial-BoldMT-36.vlw");
  textFont(font);
  textAlign(CENTER);
  rectMode(CENTER);
  ellipseMode(CENTER);

  beatTime = new int[windowWidth];   // the beatTime array holds IBI graph data
  PPG = new int[150];                // PPG array that that prints heartbeat waveform
  // initialze Data traces
  resetDataTraces();


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
   noStroke();
   drawDataWindows();
   writeAxisLabels();


//    UPDATE THE IBI ARRAY IF THERE HAS NEW DATA
  if (pulse == true){                           // check for new data from arduino
    pulse = false;                              // drop the pulse flag. it gets set in serialEvent
    for (int i=0; i<beatTime.length-3; i+=3){   // shift the data in beatTime array 3 pixels left
      beatTime[i] = beatTime[i+3];              // shift the data points through the array
    }
      IBI = constrain(IBI,300,1200);            // don't let the new IBI value escape the data window!
      beatTime[beatTime.length-1] = IBI;        // update the current IBI
    }
//    DRAW THE IBI PLOT
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
  fill(255,253,248);                              // eggshell white
  text("IBI: "+IBI+"mS",width-85,50);             // print latest IBI value above pulse wave window



//   GRAPH THE LIVE PULSE SENSOR DATA
// stroke(250,0,0);                         // use red for the pulse wave
// for (int i=1; i<PPG.length-1; i++){      // draw the waveform shape
//   line(width-160+i,PPG[i],width-160+(i-1),PPG[i-1]);
// }
 //   GRAPH THE PULSE SENSOR DATA
 stroke(250,0,0);                                       // use red for the pulse wave
  beginShape();                                         // beginShape is a nice way to draw graphs!
  for (int i=1; i<PPG.length-1; i++){                   // scroll through the PPG array
    float x = width-160+i;
    y = PPG[i];
    vertex(x,y);                                        // set the vertex coordinates
  }
  endShape();


} else { // SCAN BUTTONS TO FIND THE SERIAL PORT

  autoScanPorts();

  if(refreshPorts){
    refreshPorts = false;
    drawDataWindows();
//    drawHeart();
    listAvailablePorts();
  }

  for(int i=0; i<numPorts+1; i++){
    button[i].overRadio(mouseX,mouseY);
    button[i].displayRadio();
  }

}

}  //end of draw loop


void drawDataWindows(){
  noStroke();
  fill(eggshell);                                         // eggshell white

  rect(width/2-50,height/2+15,windowWidth,windowHeight);     // draw IBI data window
  rect(width-85,(height/2)+15,150,550);                      // draw the pulse waveform window
  fill(200);                                                 // print scale values in grey
  for (int i=300; i<=1200; i+=450){                          // print Y axis scale values
    text(i, 40,map(i,300,1200,615,75));
  }
  for (int i=30; i<=180; i+=30){                             // print X axis scale values
    text(i, map(i,180,0,75,windowWidth+75),height-10);
  }
  stroke(200,10,250);                       // draw Y gridlines in purple, for fun
  for (int i=300; i<=1200; i+=100){         // draw Y axis lines with 100mS resolution
    line(75,map(i,300,1200,614,66),85,map(i,300,1200,614,66)); //grid the Y axis
  }
  for (int i=0; i<=180; i+=10){             // draw X axis lines with 10 beat resolution
    line(map(i,0,180,625,75),height-35,map(i,0,180,625,75),height-45); // grid the X axis
  }
  noStroke();
}

void writeAxisLabels(){
  fill(eggshell);
  text("Pulse Sensor IBI Trace",width/2-50,40);              // title
  fill(116,255,160);                            // print axix labels in green, for fun
  text("IBI", 40,200);                          // Y axis label
  text("mS",40,230);
  text("Beats", 75+windowWidth-25, height-10);  // X axis advances 3 pixels with every beat
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
  // initialize PPG trace
  for (int i=0; i<=PPG.length-1; i++){
   PPG[i] = height/2+15;             // initialize PPG widow with data line at midpoint
  }
  // initialize beatTime trace
  for (int i=beatTime.length-1; i>=0; i--){  // reset the data array to default value
    beatTime[i] = 1000;
  }
}
