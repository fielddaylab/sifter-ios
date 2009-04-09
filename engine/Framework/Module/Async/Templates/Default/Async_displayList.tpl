<table class="contactList">
{foreach from=$things item=thing}
	<tr><td><a href="index.php?site={$site}&controller=Web&module={$thing.url}" target="_self"><img src="{$thing.icon}" /></a></td><td><a href="index.php?site={$site}&controller=Web&module={$thing.url}" target="_self">{$thing.label}</a></td></tr>
{/foreach}
</table>
<div id="asyncList" style="display: none;">{$defaultModule}</div>
<div id="notificationText" style="display: none;">{$notificationText}</div>