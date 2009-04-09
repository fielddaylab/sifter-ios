<form id="login" title="{$company} {$title}" action="index.php?module=Login&site={$site}" method="post" class="blackpanel" selected="true">
	<h2>Welcome to {$title}.</h2>
	<fieldset>
		<div class="blackmain">
			<div class="row">
				<label>Username</label>
				<input type="text" name="user_name" />
			</div>
			<div class="row last">
				<label>Password</label>
				<input type="password" name="password" />
			</div>
		</div>
		<input type="hidden" name="req" value="login" />
		<input type="hidden" name="location_detection" value="none" />
		<div class="submit"><input type="submit" value="Login" /></div>
	</fieldset>
</form>