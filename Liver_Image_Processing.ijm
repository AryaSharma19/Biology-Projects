//Full Batch Processing for Embryo Stainings
//Arya Sharma, 12/16/22, ideas and source code from Morgan Oatley 
//Inputs: 
//	User selected Directory containing only sub directories from the fluoview 
//	Each subdirectory should be titled EXXX where XXX is a 3 digit number
//	Each subdirectory must have the same chanel sequence and the same Florescent proteins
//	Florescent proteins in correct chanel sequence must be manually input as strings on line 19
//	Each sub directory must contain a stiched image file with the name Stitch_A01_G001.oir (the default name from the fluoview software)
	 
//Outputs: 
//	Each sub directory contains a Processed Images Directory with: 
//		-A Colored and a grayscale image of each florescent protein labeled EXXX <Protein Name> [""|Grayscale]
//		-A Merged Picture
//	Named and created to make it easy to extraxt all photos of a certain type with a python script TOD0



//change to fit your channels, must be constant across batches, and match the channels set by the fluoview machine
cns = newArray("DAPI","Endomucasin","aSMA","LIV1");

//input the cns index for the channels you want (0 offset so first element is array 0 and last element is cns.length - 1)
//TODO
selectedchannels = newArray(0,3);



//has the User select the Working Directory manually
entrypoint = getDirectory("Input directory");
main(entrypoint)

//loops through the subdirectories and calls the helper functions
function main(entrypoint) {
	//gets the subdirectories
	list = getFileList(entrypoint);
	
	//iterates through the subdirectories
	for (i = 0; i < list.length; i++) {
	    print("Started on " + i+1 + " of "+ list.length);
	    
	    //the fullpath for each subdirectory,
	    input = entrypoint + list[i];
	   	
	   	//makes the Processed Images fullpath and then creates it within the subdirectory
		output = input + File.separator + "Processed Images";
		File.makeDirectory(output);
		
		//this makes a string with the Embryo ID (ex.E490), by taking a the first for characters of each subdirectory name
		//this is why each subdirectory name must start with the Embryo number in the format EXXX
		embryo = substring(list[i],0,4);
		
		//helper functions
		merge(input, output);
		individuals(input, output, embryo);
		
		
		print("Finished " + i+1 + " of "+ list.length);
	}

}

//puts greyscale and colored images in the directories
function individuals(input, output, embryo) {
	print(input + "Stitch_A01_G001.oir");
	//opens the stiched file
	open(input + "Stitch_A01_G001.oir");
	rename("original");
	
	//combines the Z stacks, also makes the MAX_stich... window
	run("Z Project...", "projection=[Max Intensity]");
	rename("MAX_original");
	
	//closes the stiched file window, as all work will now be done on the layered Z stack MAX_image window
	selectWindow("original");
	close();
	
	//split the chanels
	run("Split Channels");
	
	//renames channels and close MAX_Window
	rename("C" + cns.length);
	for (i = cns.length - 1; i > 0; i--) {
		selectWindow("C"+ i +"-MAX_original");
		
		//this renaming to C1,C2...CN is used later to iterate through all the channels
		//the order of 1..N is set by the user when the enter the Marker protein names into the cns array on line 19 
		rename("C" + i);
	}
	
	//Flatten and saves the channels with the embryo name and Marker Protein Name
	for (i = cns.length; i > 0; i--) {
		selectWindow("C"+ i);
		run("Flatten");
		saveAs("Tiff", output + File.separator + embryo + " " + cns[i-1] +".tif");
		wait(250);
		close();
	}
	
	//Converts the channels to Grayscale, Flattens and saves images
	for (i = cns.length; i > 0; i--) {
		selectWindow("C"+ i);
		run("Grays");
		wait(250);
		run("Flatten");
		saveAs("Tiff", output + File.separator + embryo + " " + cns[i-1] + " "+"Greyscale.tif");
		wait(250);
		close();
	}
	
	//closes the channel windows
	run("Close All");
}


//puts the merged stich file from the input folder into an output folder
function merge(input, output) {
	print(input + "Stitch_A01_G001.oir");
	//opens the stiched file
	open(input + "Stitch_A01_G001.oir");
	rename("Stitch_A01_G001.oir");
	
	//combines the Z stacks, also makes the MAX_stich... window
	run("Z Project...", "projection=[Max Intensity]");
	rename("MAX_Stitch_A01_G001.oir");
	
	//closes the stiched file window, as all work will now be done on the layered Z stack image window
	selectWindow("Stitch_A01_G001.oir");
	close();
	
	//"Make Composite" layers all channels, to create the merged image
	selectWindow("MAX_Stitch_A01_G001.oir");
	run("Make Composite");
	
	//saves this combined Z stack 
	run("Flatten");
	saveAs("Tiff", output + File.separator + "Merged Picture.tif");
	close(); 
	selectWindow("MAX_Stitch_A01_G001.oir");
	close();
}
 