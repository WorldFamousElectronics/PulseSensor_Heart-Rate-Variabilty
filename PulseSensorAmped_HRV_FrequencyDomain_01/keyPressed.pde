



void keyPressed(){
// take a picture of the screen by pressing the s key 
 if (key =='S'){
  saveFrame("HRV-####.jpg");      // take a shot of that!
 }
// clear the screen when you press 'C' 
 if (key == 'C'){
   for (int i=beatTime.length-1; i>=0; i--){  // reset the data array to default value
      beatTime[i] = 300;
    }
   for (int i=0; i<150; i++){                 // reset the frequency plot to default values
     powerPointX[i] = 625;
     powerPointY[i] = height - 35;
   }
 }
 if (key == 'W'){
   showWave = !showWave;
 }
}  // END OF KEYPRESSED
