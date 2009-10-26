<?php
		
		if (isset($_REQUEST['req']) and $_REQUEST['req'] == 'register2' and ($_REQUEST['password'] == $_REQUEST['password2'])) {
			
			//Try to insert
			$query = "INSERT INTO editors (name, password, comments) VALUES
			('{$_REQUEST['user_name']}', md5('{$_REQUEST['password']}'),'{$_REQUEST['comments']}') ";
			
			mysql_query($query);
			
			echo mysql_error();
			
			
			echo '<p><strong>Editor Created! Please <a href = "index.php"> Login </a></strong></p>';
		
			print_footer();
		}
		else {	
			print_form();
			print_footer();
		}
		
		
		
		//Print the login form
		function print_form(){
			echo '<p>Enter your new login information below</p>';
			echo '
			<form action = "' . $_SERVER['PHP_SELF'] . '" method = "post">
			<input type = "hidden" name = "req" value = "register2"/>
			<table class = "login">
			<tr><th>Email Address (your aris username)</th><td><input type = "text" name = "user_name"/></td></tr>
			<tr><th>Password</th><td><input type = "password" name = "password"/></td></tr>
			<tr><th>Password Verification</th><td><input type = "password" name = "password2"/></td></tr>
			<tr><th>Comments about yourself</th><td><textarea name = "comments"></textarea></td></tr>
			<tr><th>&nbsp;</th><td><input type = "submit"/></td></tr>
			</table></form>';
			
		}
	

?>