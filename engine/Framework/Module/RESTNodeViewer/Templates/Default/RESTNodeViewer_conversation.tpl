<table id="dialog" width="295px">
	<tbody>
	<tr><td><div style="padding-top: 10px; font-style: italic;">Chat started at {$time}.</div></td></tr>
	<tr><td><div><img src = '{$npc.media}' width = '48px'/>{$npc.text}</div></td></tr>
	</tbody>
</table>
<input id="message" value=" " disabled="true" />
<select id="playerMessageSelection" onchange="postSelection();">
	<option value="">Say...</option>
</select>
<input type="button" id="playerMessageSendButton" value="Send" disabled="true" onclick="postPlayerMessage();"/>
<div id="viewAnchor" style="height: 20px;"></div>
<div id="rawMessage"></div>
<script language="JavaScript" type="text/javascript">
<!--
{foreach from=$conversations item=msg}
	prepOptions({$msg.node_id}, "{$msg.text|strip}");
	startOptions();
{/foreach}
//-->
</script>
