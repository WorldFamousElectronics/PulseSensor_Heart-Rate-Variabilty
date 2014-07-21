



void keyPressed(){
// take a picture of the screen by pressing the s key 
 if (key =='S'){
  saveFrame("HRV-####.jpg");      // take a shot of that!
 }
// clear the IBI data array by pressing c key 
 if (key == 'C'){
   for (int i=beatTime.length-1; i>=0; i--){  // reset the data array to default value
      beatTime[i] = 1000;
    }
 }
}  // END OF KEYPRESSED
