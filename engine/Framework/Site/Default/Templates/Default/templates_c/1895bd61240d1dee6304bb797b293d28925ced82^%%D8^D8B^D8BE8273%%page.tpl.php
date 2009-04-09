<?php /* Smarty version 2.6.19, created on 2008-10-24 16:34:00
         compiled from page.tpl */ ?>
<?php require_once(SMARTY_CORE_DIR . 'core.load_plugins.php');
smarty_core_load_plugins(array('plugins' => array(array('function', 'application', 'page.tpl', 52, false),)), $this); ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" 	
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	<meta name="viewport" content="width=320; initial-scale=1.0; maximum-scale=1.0; user-scalable=0;"/>
	<title><?php echo $this->_tpl_vars['title']; ?>
</title>
	<link rel="stylesheet" href="<?php echo $this->_tpl_vars['frameworkTplPath']; ?>
/iui/iui.css" type="text/css" media="all" />
	<link rel="StyleSheet" href="<?php echo $this->_tpl_vars['frameworkTplPath']; ?>
/common.css" type="text/css" media="all" />
	
	<?php if (isset ( $this->_tpl_vars['links'] )): ?>
		<?php $_from = $this->_tpl_vars['links']; if (!is_array($_from) && !is_object($_from)) { settype($_from, 'array'); }if (count($_from)):
    foreach ($_from as $this->_tpl_vars['link']):
?>
			<link rel="stylesheet" href="<?php echo $this->_tpl_vars['link']; ?>
" type="text/css" media="all" />		
		<?php endforeach; endif; unset($_from); ?>
	<?php endif; ?>
	<script type="application/x-javascript">
	<!--
		var site = '<?php echo $this->_tpl_vars['site']; ?>
';
	//-->
	</script>
	<script type="application/x-javascript" src="<?php echo $this->_tpl_vars['frameworkTplPath']; ?>
/iui/iui.js"></script>
	<script type="application/x-javascript" src="<?php echo $this->_tpl_vars['frameworkTplPath']; ?>
/location.js"></script>
	<?php if ($this->_tpl_vars['isIphone']): ?>
	<link rel="StyleSheet" href="<?php echo $this->_tpl_vars['frameworkTplPath']; ?>
/fixed.css" type="text/css" media="all" />
	<script type="application/x-javascript" src="<?php echo $this->_tpl_vars['frameworkTplPath']; ?>
/fixed.js"></script>
	<?php endif; ?>
	<?php if (isset ( $this->_tpl_vars['scripts'] )): ?>
		<?php $_from = $this->_tpl_vars['scripts']; if (!is_array($_from) && !is_object($_from)) { settype($_from, 'array'); }if (count($_from)):
    foreach ($_from as $this->_tpl_vars['script']):
?>
<script type="application/x-javascript" src="<?php echo $this->_tpl_vars['frameworkTplPath']; ?>
/<?php echo $this->_tpl_vars['script']; ?>
"></script>
		<?php endforeach; endif; unset($_from); ?>
	<?php endif; ?>
	<?php if (isset ( $this->_tpl_vars['rawHead'] )): ?>
		<?php echo $this->_tpl_vars['rawHead']; ?>

	<?php endif; ?>
</head>
<body orient="portrait" <?php if (isset ( $this->_tpl_vars['onLoad'] )): ?>onload="<?php echo $this->_tpl_vars['onLoad']; ?>
"<?php endif; ?>>
<div class="toolbar black" id="header">
	<h1 id="pageTitle"><?php echo $this->_tpl_vars['title']; ?>
</h1>
	<!-- Back button support? -->
</div>
<div id="container">
	<div id="content">
<?php if (isset ( $this->_tpl_vars['notification'] )): ?>
	<p class="notification"><?php echo $this->_tpl_vars['notification']; ?>
</p>
<?php endif; ?>
<?php $_smarty_tpl_vars = $this->_tpl_vars;
$this->_smarty_include(array('smarty_include_tpl_file' => ($this->_tpl_vars['modulePath'])."/".($this->_tpl_vars['tplFile']), 'smarty_include_vars' => array()));
$this->_tpl_vars = $_smarty_tpl_vars;
unset($_smarty_tpl_vars);
 ?>
	</div>
</div>
<?php if (isset ( $this->_tpl_vars['session']->applications )): ?>
<div class="appbar" id="footer">
	<?php $_from = $this->_tpl_vars['session']->applications; if (!is_array($_from) && !is_object($_from)) { settype($_from, 'array'); }if (count($_from)):
    foreach ($_from as $this->_tpl_vars['app']):
?>
		<?php echo smarty_function_application(array('module' => $this->_tpl_vars['app']), $this);?>

	<?php endforeach; endif; unset($_from); ?>
	<?php if (isset ( $this->_tpl_vars['adminApplications'] )): ?>
		<?php $_from = $this->_tpl_vars['adminApplications']; if (!is_array($_from) && !is_object($_from)) { settype($_from, 'array'); }if (count($_from)):
    foreach ($_from as $this->_tpl_vars['app']):
?>
			<?php echo smarty_function_application(array('module' => $this->_tpl_vars['app']), $this);?>

		<?php endforeach; endif; unset($_from); ?>
	<?php endif; ?>
	<div class="application" id="notify"></div>
</div>
<?php elseif (isset ( $this->_tpl_vars['techEmail'] )): ?>
<div class="help" id="footer">
	<p>Email <a href="mailto:<?php echo $this->_tpl_vars['techEmail']; ?>
"><?php echo $this->_tpl_vars['techEmail']; ?>
</a> with help requests or feedback.</p>
</div>
<?php endif; ?>
</body>
</html>