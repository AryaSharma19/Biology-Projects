//Arya Sharma, 06/29/23
//input directory must have at least two folders: ROIs and Images with the same number of files 
//where each image in the Image folder has a respective roi in the ROIs folder
//images must be tiffs, with 5 or more images total
//Images subdirectory consists of tiffs labeled Exxx.tif
//ROIs subdirectory consists of .rois files labeled Exxx_roi.roi


//has the User select the input Working Directory manually
input = getDirectory("Input directory");

//change string below to name ouput directory, output directory made within the input directory
output = input + File.separator + "output ave_plus_half_stdev";											//change
File.makeDirectory(output);

//the measurements you want imageJ to take when you run Measure equivalent to Analyse->Set Measurements
run("Set Measurements...", "area mean standard min area_fraction display redirect=None decimal=3");


//call main function, giving the input directory and the output directory we created within the input directory
main(input, output);




//loads ROIS then iterates over each image
function main(input, output) {
	//makes a directory to store the images with the area measured overlayed in the output directory
	image_output = output + File.separator +"Images";
	File.makeDirectory(image_output);
	//open ROI Manager equivalent to Analyse->Tools->ROI Manager
	run("ROI Manager...");
	//load ROIs inot the ROI Manager via helper function open_rois(), stores the output array of the roi names in the rois_in_order variable
	//input folder must have the ROIs subdirectory
	rois_in_order = open_rois(input + "/ROIs");
	
	//creates an Array of the Image title from the Images subdirectory
	images = getFileList(input + "/Images");
	//create an empty array to store the Embryo name
	embryo_res = newArray();
	//create an empty array to store the Embryo's % vascular area
	percent_res = newArray();

	//iterate over image list
	for (i = 0; i < images.length; i++) {
	    //call image_processer() helper function for each image, passes in the full path, the image name, the list of ROI names, 
		//and the path to the ouput subdirectory where the overlayed images will be stored
		//image_processer() returns an array [Embryo name, % vascular area], save that as the row_vals variable
		row_vals = image_processer(input + "/Images" + File.separator + images[i], images[i], rois_in_order, image_output);
	    //append the row_vals array values to the arrays that store information for all embryos
		embryo_res = Array.concat(embryo_res, row_vals[0]);
	    percent_res = Array.concat(percent_res, row_vals[1]);
	}
	//make a table
	Table.create("results");
	//add two columns Embryo name and % vascular area. 
	Table.setColumn("Embryo", embryo_res);
	Table.setColumn("%Area", percent_res);
	Table.update();
	Table.save(output + File.separator + "results");
	saveAs("Results", output + File.separator + "results.csv");
	wait(250);
	run("Close");
	close("ROI Manager");
}


//image_output is the path to the subdirectory where all the images are stored, image is simply the image title
function image_processer(image_path, image, rois_in_order, image_output) {
	//open Image equivalent to File->Open
	open(image_path);
	wait(250);
	//convert image to 8-bit Image equivalent to Image->Type->8-bit
	run("8-bit");
	wait(250);
	//cut off the .tiff of the image name so it is just the embryo number Exxx
	image = substring(image, 0, 4);
	//make roi name based on the image name.
	roi_name = image + "_roi";
	//might not need to do this, but found it might help
	selectWindow(getTitle());
	
	//sometimes the ROI manager doesnt select the right roi the first time. We will call two wrong ROIs first time as a buffer
	//this is why there needs to be at least five images total. can be edited if there are less than five images
	roiManager("Select", 5);
	roiManager("Select", 4);
	//Declare and Initialize index variable
	index = 0;
	loop through roi list, saving the index of the matching roi by comparing the current roi in the list to the roi_name variable made above
    for (i = 0; i < rois_in_order.length; i++) {
        if current roi in list matches our roi_name then
		if (rois_in_order[i] == roi_name) {
            //select the correct roi
			roiManager("Select", i + 1);
			//save index
            index = i + 1;
        }
    }
	//doubly catious as sometimes the select was finnicky so we select again to be safe
    roiManager("Select", index);
    wait(250);
	//Do quantification via helper function, save the array get_percentage outputs
	//only pass in the image name which we earlier trimmed to be just EXXX
    row_vals = get_percentage(image);
    

	//save the image with the fire (filter?) equivalent to Image->Lookup Table->Fire
	run("Fire");
    wait(250);
	run("Flatten");
	//save as tiff equivalent to File->Save As->Tiff
	saveAs("Tiff", image_output + File.separator + image + " Fire.tif");
	wait(250); 
	run("Close All");
	wait(250);
	
	//return the array with the values from the quantification analysis
	return row_vals;
}


//the image is opened and the ROI selected before this function is called so it only needs the image name
function get_percentage(image_name) {
	//Measures the values we selected witht he Set Measurements line of code. equivalent to Analyse->Measure
	roiManager("Measure");
	//saves the average pixel intensity, the max pixel intensity, and the standard deviation
	average = Table.get("Mean", 0);
	stdev = Table.get("StdDev",0);
	max = Table.get("Max", 0);
	//pass the three values into the calculations helper function, save the value calculation() outputs as that is the threshold for that image
	subtract_val = calculation(average, stdev, max);
	//subtract the threshold from the Image, equivalent to Process->Math->Subtract
	run("Subtract...", "value=" + toString(subtract_val));
	//remeasure
	roiManager("Measure");
	//now only save the area% which is the % of pixels above our threshold, which is our vascular area
	percent = Table.get("%Area", 1);
	//close table
	close("Results");
	//return the image name and vascular area percentage in an array
	return newArray(image_name, toString(percent));
}

//the calculations function, change as you want depending on your analysis, just make sure you change the name of the output folder
function calculation(ave, stdev, max) {
	stdev = stdev * 0.5;
	value = ave + stdev ;
	return value	
}

//subfunction to add the saved ROIs into the ROI manager
//takes in the full path to the ROIs subdirectory
//outputs an array of ROI names corresponding to the order they are in the ROI manager
//indexes match so the first element in the array of names matches the first ROI in the ROI Manager
function open_rois(input_roi_folder) {
		//make the return array
		rois_in_order = newArray();
		//get the file list from the ROIs subdirectory
		rois = getFileList(input_roi_folder);
		//iterate over the roi files
		for (i = 0; i < rois.length; i++) {
	    	//open the ROI
			open(input_roi_folder + File.separator + rois[i]);
			//add it to the manager
			roiManager("Add");
			//add the name to the array
			rois_in_order = Array.concat(rois_in_order, substring(rois[i],0,8));
			//close the open ROI as it is now saved to the manager
			close();
		}
		//the first index is a 0 istead of name so take it out
		rois_in_order = Array.deleteIndex(rois_in_order, 0);
		
		//just to make sure no one ROI is selected when this function returns, instead they are all saved into the ROI Manager
		roiManager("Show All");
    	roiManager("Deselect");
    	
		//return the array of names in order to be used later
		return rois_in_order;
	}
