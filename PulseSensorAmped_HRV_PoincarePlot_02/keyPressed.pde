



void keyPressed(){
// take a picture of the screen by pressign the S key 
 if (key =='S'){
  saveFrame("Poincare_####.jpg");      // take a shot of that!
 }
// clear the Poincare plot arrays and clear the phase space by pressing C key 
 if (key == 'C'){
   for (int i=numPoints-1; i>=0; i--){  // 
      beatTimeY[i] = 0;
      beatTimeX[i] = 0;
    }
 }
// show a trace of the last 20 points in the time series, or not
 if (key == 'L'){
   makeLine = !makeLine; 
 }
}  // END OF KEYPRESSED
