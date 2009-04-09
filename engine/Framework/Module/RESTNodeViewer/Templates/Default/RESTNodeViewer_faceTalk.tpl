{if isset($npc.media)}
	<div class="npcImg">
		<img src="{$npc.media}" />
	</div>
{/if}
<div class="npcText">
{$node.text}
</div>
{if !empty($node.require_answer_string)}
<form method="GET" action="index.php">
    <input name="module" type="hidden" value="RESTNodeViewer" />
    <input name="event" type="hidden" value="faceTalk" />
    <input name="site" type="hidden" value="{$site}" />
    <input name="node_id" type="hidden" value="{$node.node_id}" />
    <input name="npc_id" type="hidden" value="{if is_null($npc)}-1{else}{$npc.npc_id}{/if}" />
    <input id="answer_string" name="answer_string" style="width: 50%; margin: 5px;" />
    <input id="submit" type="submit" style="width: 25%;" />
</form>
{else}
<ul class="options">
{foreach from=$conversations item=msg}
	<li>{link text=$msg.text module="RESTNodeViewer" event="faceTalk&node_id=`$msg.node_id`&npc_id=`$npc.npc_id`&user_name=`$username`&password=`$password`"}</li>
{/foreach}
</ul>
{/if}
<div style="display: none;" id="npcId">{$npc.npc_id}</div>
