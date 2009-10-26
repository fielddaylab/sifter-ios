<?php
	foreach( $_FILES AS $key => $val ){
		if ( !empty ( $_FILES[$key]['name'] ) ) {
			$fileN = $_FILES[$key]['name'];
			$fileN  = str_replace( " ", "_", $fileN  );
			$fileN  = str_replace( "\'", "", $fileN  );
			$fileN  = str_replace( "%20", "_", $fileN  );
			$fileName[] = $fileN;
		}  # END if !empty
	}  ## END for


	## write new tempname into array
	foreach( $_FILES AS $key => $val ){
		if ( !empty ( $_FILES[$key]['name'] ) ) {
			$fileTempName[] =  $_FILES[$key]["tmp_name"];
		}	
	}  # END for
	
	
	
	for ($k = 0; $k < $this->num_fds; $k++) {
		if ($this->fdd[$k]['imagepath'] <> "") {
			$pathArray[] = $this->fdd[$k]['imagepath'];
		}
	}
	//kill any paths from the array for image fields that may have been left blank - so paths correspond to images
	foreach( $_FILES AS $key => $val ){
		$b = 0;
		if ( empty ( $_FILES[$key]['name'] ) ) {
			array_splice($pathArray, $b,1);
		}
		$b++;
	}
	 
	
	for ( $i=0; $i < sizeof( $fileName ); $i++ )  {  # tested thoroughly	
		//copy the file to a permanent location 
		if (move_uploaded_file( $fileTempName[$i], 
			$pathArray[$i] . /* $this->rec . "." . */ $fileName[$i] )) {
				// echo("file uploaded. Voila! <br>");
		} 
		else {
			echo "<div align='center'>ERROR!  Image named: " . $pathArray[$i] . $fileName[$i] . "  not uploaded </div><br> ";
		}	
	}
?>
