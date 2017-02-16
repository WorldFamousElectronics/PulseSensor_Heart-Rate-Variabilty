
void serialEvent(Serial port){
try{
   String inData = port.readStringUntil('\n');  // read the ascii data into a String
   inData = trim(inData);                 // cut off white space (carriage return)

  if (inData.charAt(0) == 'S'){           // leading 'S' means Pulse Sensor data packet
     inData = inData.substring(1);        // cut off the leading 'S'
     int newPPG = int(inData);            // convert ascii string to integer
     for (int i = 0; i < PPG.length-1; i++){
       PPG[i] = PPG[i+1]; // move the Y coordinates of the pulse wave one pixel left
     }
      // new data enters on the right at pulseY.length-1
      // scale and constrain incoming Pulse Sensor value to fit inside the pulse window
      PPG[PPG.length-1] = int(map(newPPG,50,950,(height/2+15)+225,(height/2+15)-225));
     return;
   }

    if (inData.charAt(0) == 'Q'){         // leading 'Q' means IBI data packet
     inData = inData.substring(1);        // cut off the leading 'Q'
     IBI = int(inData);                   // convert ascii string to integer
     pulse = true;                        // set the pulse flag
     return;
    }
}catch(Exception e) {
   //println(e.toString());
}
}// END OF SERIAL EVENT
