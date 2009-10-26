<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" 	
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	<meta name="viewport" content="width=320; initial-scale=1.0; maximum-scale=1.0; user-scalable=0;"/>
	<title>{$title}</title>
	<link rel="stylesheet" href="{$frameworkTplPath}/iui/iui.css" type="text/css" media="all" />
	<link rel="StyleSheet" href="{$frameworkTplPath}/common.css" type="text/css" media="all" />
	
	{if isset($links)}
		{foreach from=$links item=link}
			<link rel="stylesheet" href="{$link}" type="text/css" media="all" />		
		{/foreach}
	{/if}
	<script type="application/x-javascript">
	<!--
		var site = '{$site}';
	//-->
	</script>
	<script type="application/x-javascript" src="{$frameworkTplPath}/iui/iui.js"></script>
	<script type="application/x-javascript" src="{$frameworkTplPath}/location.js"></script>
	{if $isIphone}
	<link rel="StyleSheet" href="{$frameworkTplPath}/fixed.css" type="text/css" media="all" />
	<script type="application/x-javascript" src="{$frameworkTplPath}/fixed.js"></script>
	{/if}
	{if isset($scripts)}
		{foreach from=$scripts item=script}
<script type="application/x-javascript" src="{$frameworkTplPath}/{$script}"></script>
		{/foreach}
	{/if}
	{if isset($rawHead)}
		{$rawHead}
	{/if}
</head>
<body orient="portrait" {if isset($onLoad)}onload="{$onLoad}"{/if}>
{if !isset($chromeless)}
<div class="toolbar black" id="header">
	<h1 id="pageTitle">{$title}</h1>
	<!-- Back button support? -->
</div>
{/if}
<div id="container">
	<div id="content">
{if isset($notification)}
	<p class="notification">{$notification}</p>
{/if}
{include file="$modulePath/$tplFile"}
	</div>
</div>
{if isset($session->applications)}
{if !isset($chromeless)}
<div class="appbar" id="footer">
	{foreach from=$session->applications item=app}
		{application module=$app}
	{/foreach}
	{if isset($adminApplications)}
		{foreach from=$adminApplications item=app}
			{application module=$app}
		{/foreach}
	{/if}
	<div class="application" id="notify"></div>
</div>
{/if}
{elseif isset($techEmail)}
{if !isset($chromeless)}
<div class="help" id="footer">
	<p>Email <a href="mailto:{$techEmail}">{$techEmail}</a> with help requests or feedback.</p>
</div>
{/if}
{/if}
</body>
</html>