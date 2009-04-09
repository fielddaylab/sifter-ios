<form enctype="multipart/form-data" action="../../index.php" method="POST">
<input type="hidden" name="MAX_FILE_SIZE" value="100000" />

Choose an image to upload: <input name="image" type="file" /><br />
Name this image (optional): <input name="name" type="text" /><br />
Description (optional): <input name="description" type="text" /><br />

<input type = "hidden" name = "module" value = "RESTCamera"/>
<input type = "hidden" name = "site" value = "test"/>
<input type = "hidden" name = "user_name" value = "test"/>
<input type = "hidden" name = "password" value = "test"/>

<input type="submit" value="Upload Image" />

</form>
