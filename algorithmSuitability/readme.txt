Code might not work straight out of the box. The random forest should be fine but you will have to fix the matlab. 

You basically want to find the areas in the .flo files where there is no flow (ie point gets occluded) and set that as one class. Then the other class will be any point that doesnt get occluded. There will be to much data for the second class so you will have to pick a subsample of it. 
