run("Colors...", "foreground=white background=black selection=yellow");
imageDirectory = File.directory;
imageTitle = getTitle();

//change the image channel order numbers if neccessary
//choose the appropriate the Z-slice below (next line) ================
run("Duplicate...", "title=test duplicate slices=5"); 
Stack.setXUnit("pixel");
Stack.setYUnit("pixel");
run("Properties...", "channels=4 slices=1 frames=1 pixel_width=1 pixel_height=1 voxel_depth=1");
setOption("ScaleConversions", true);
run("8-bit");
run("Split Channels");
selectImage("C4-test");
rename("nucleus");
selectImage("C2-test");
rename("mfl2-blebs");
selectImage("C3-test");
rename("plin2");
selectImage("C1-test");
rename("LD");


//plin2 quantification
selectImage("LD");
run("Subtract Background...", "rolling=50");
setAutoThreshold("Otsu dark");
setOption("BlackBackground", true);
run("Convert to Mask");

selectImage("LD");
run("Analyze Particles...", "size=10-Infinity add");
roiManager("Show All without labels");
roiManager("Show None");

//change the size of the image below if its not 512x512
newImage("LD-clean", "8-bit black", 512, 512, 1);
roiManager("Show None");
roiManager("Show All");
roiManager("Fill");
roiManager("Show None");
run("Options...", "iterations=1 count=1 black do=Nothing");
setOption("BlackBackground", true);
run("Dilate");
run("Watershed");
//run("Options...", "iterations=1 count=1 black do=Nothing");
roiManager("Reset");

selectImage("plin2");
run("Subtract Background...", "rolling=50");
run("Set Measurements...", "area mean integrated display redirect=None decimal=1");
run("Measure");
selectImage("LD-clean");
run("Set Measurements...", "area mean integrated display redirect=plin2 decimal=1");
run("Analyze Particles...", "size=10-Infinity display add");
//first row is general mean intensity to quantify fold change of plin2 signal around the LD
selectWindow("Results");
saveAs("Results", File.directory + imageTitle + "_plin2_results.csv");
roiManager("Reset");
run("Clear Results");


//bleb quantification
selectImage("nucleus");
run("Enhance Contrast...", "saturated=0.35");
run("Gaussian Blur...", "sigma=4");
setAutoThreshold("Otsu dark");
setOption("BlackBackground", true);
run("Convert to Mask");
run("Set Measurements...", "area mean integrated display redirect=None decimal=1");
run("Clear Results");
roiManager("Reset");
run("Analyze Particles...", "display clear add");

// === Identify largest nucleus ===
roiCount = roiManager("count");
maxArea = 0;
maxIndex = -1;

for (i = 0; i < roiCount; i++) {
    area = getResult("Area", i);
    if (area > maxArea) {
        maxArea = area;
        maxIndex = i;
    }
}

// === Create blank image and fill largest ROI ===
getDimensions(width, height, channels, slices, frames);
newImage("nucleus-single", "8-bit black", width, height, 1);

// Copy ROI from original image and paste into blank image
roiManager("Select", maxIndex);
run("Copy");
selectWindow("nucleus-single");
run("Paste");
run("Fill", "slice");

run("Options...", "iterations=3 count=1 black do=Nothing");
selectImage("nucleus-single");
roiManager("Show All");
roiManager("Show None");
run("Duplicate...", "title=nucleus-dilated");
run("Dilate");
run("Watershed");
selectImage("nucleus-single");
run("Watershed");
run("Duplicate...", "title=nucleus-eroded");
run("Erode");
run("Options...", "iterations=1 count=1 black do=Nothing");
imageCalculator("Subtract create", "nucleus-dilated","nucleus-eroded");
selectImage("Result of nucleus-dilated");
setOption("BlackBackground", true);
run("Dilate");
selectImage("mfl2-blebs");
run("Subtract Background...", "rolling=50");
run("Enhance Contrast...", "saturated=0.35");
setAutoThreshold("MaxEntropy dark");
run("Convert to Mask", "method=MaxEntropy background=Dark calculate black");
run("Find Maxima...", "prominence=10 output=[Single Points]");
rename("blebs");
imageCalculator("AND create", "Result of nucleus-dilated","blebs");
selectImage("Result of Result of nucleus-dilated");
rename("mfl2 on nuclear membrane");
run("Set Measurements...", "perimeter display redirect=None decimal=1");
selectImage("nucleus-single");
run("Analyze Particles...", "display clear add");
selectImage("mfl2 on nuclear membrane");
run("Analyze Particles...", "display add");
imageCalculator("AND create", "blebs","nucleus-eroded");
selectImage("Result of blebs");
selectImage("blebs");
selectImage("Result of blebs");
rename("mfl2-inside-nucleus");
run("Analyze Particles...", "display add");
selectWindow("Results");
saveAs("Results", File.directory + imageTitle + "_nuclear_blebs.csv");
roiManager("Reset");
run("Clear Results");


//LD quantification
selectImage("LD");
run("Watershed");
run("Set Measurements...", "area center perimeter shape display redirect=None decimal=1");
run("Analyze Particles...", "size=10-Infinity display clear add");
selectWindow("Results");
saveAs("Results", File.directory + imageTitle + "_LDs.csv");
roiManager("Reset");
run("Clear Results");

//close unnecessary images
selectWindow("Results");
close();
//selectWindow("Summary");
//close();
selectImage("nucleus");
close;
selectImage("nucleus-dilated");
close;
selectImage("nucleus-single");
//close;
selectImage("nucleus-eroded");
close;
selectImage("plin2");
close;
selectImage("Result of nucleus-dilated");
close;
selectImage("mfl2 on nuclear membrane");
//close;
selectImage("mfl2-blebs");
selectImage("blebs");
selectImage("LD-clean");
