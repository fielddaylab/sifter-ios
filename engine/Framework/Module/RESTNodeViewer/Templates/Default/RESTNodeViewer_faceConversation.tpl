{if isset($npc.media)}
	<div class="npcImg">
		<img src="{$npc.media}" />
	</div>
{/if}
<div class="npcText">{$npc.text}</div>
<ul class="options">
{foreach from=$conversations item=msg}
	<li>{link text=$msg.text module="RESTNodeViewer" event="faceTalk&node_id=`$msg.node_id`&npc_id=`$npc.npc_id`&user_name=`$username`&password=`$password`"}</li>
{/foreach}
</ul>
<div style="display: none;" id="npcId">{$npc.npc_id}</div>