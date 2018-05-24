
void mousePressed(){
  if(!serialPortFound){
    for(int i=0; i<=numPorts; i++){
      if(button[i].pressRadio(mouseX,mouseY)){
        if(i == numPorts){
          if(Serial.list().length > numPorts){
            println("New Ports Opened!");
            int diff = Serial.list().length - numPorts;	// was serialPorts.length
            serialPorts = expand(serialPorts,diff);
            //button = (Radio[]) expand(button,diff);
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
     saveFrame("HRV-####.jpg");      // take a shot of that!
     break;
  // clear the screen when you press 'R' or 'r'
   case 'r':
   case 'R':
     resetDataTraces();
     break;
   case 'W':
   case 'w':
     showWave = !showWave;
     break;
   case '1':
     breathCycle = 4.0;
     break;
   case '2':
     breathCycle = 4.5;
     break;
   case '3':
     breathCycle = 5.0;
     break;
   case '4':
     breathCycle = 5.5;
     break;
   case '5':
     breathCycle = 6.0;
     break;
   case '6':
     breathCycle = 6.5;
     break;
   case '7':
     breathCycle = 7.0;
     break;
   case '8':
     breathCycle = 7.5;
     break;
   case '9':
     breathCycle = 8.0;
     break;
   default:
     break;
 }
}
