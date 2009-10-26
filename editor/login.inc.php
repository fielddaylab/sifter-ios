<?php
	
	if (isset($_REQUEST['req']) and $_REQUEST['req'] == 'login') {
		
		//Try to login
		$query = "SELECT * FROM editors WHERE
		name = '{$_REQUEST['user_name']}'
		AND
		password = md5('{$_REQUEST['password']}')";
		
		$result = mysql_query($query);
		
		echo mysql_error();
		
		if ($row = mysql_fetch_array($result)) {
			echo '<h3>Login Successfull</h3>';
			$_SESSION['user_name'] = $row['name'];
			$_SESSION['user_id'] = $row['editor_id'];
			echo '<script language="javascript">window.location = \'index.php\';</script>';
		}
		else {
			echo '<h3>Email / Password not valid</h3>';
			print_form();
			print_footer();
		}	
	}
	
	else {	
		print_form();
		print_footer();
	}
	
	
	
	//Print the login form
	function print_form(){
		echo '<p>Enter your login information below or <a href = "index.php?req=register">Create a New Account</a></p>';
		echo '
		<form action = "' . $_SERVER['PHP_SELF'] . '" method = "post">
		<input type = "hidden" name = "req" value = "login"/>
		<table class = "login">
		<tr><th>Email Address (your ARIS username)</th><td><input type = "text" name = "user_name"/></td></tr>
		<tr><th>Password</th><td><input type = "password" name = "password"/></td></tr>
		<tr><th>&nbsp;</th><td><input type = "submit"/></td></tr>
		</table></form>';
		
	}
?>