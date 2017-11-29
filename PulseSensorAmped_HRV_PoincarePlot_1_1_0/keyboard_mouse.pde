
void mousePressed(){
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

void mouseReleased(){
}

void keyPressed(){

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
