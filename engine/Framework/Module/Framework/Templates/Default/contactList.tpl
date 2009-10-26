{if count($npcs) > 0}
<table class="contactList">
<!--	<caption>Detected Interactions</caption> -->
{foreach from=$npcs item=npc}
	<tr>
		<td>
			{if $npc.media}
				{link module="NodeViewer" event="`$event`&npc_id=`$npc.npc_id`" text="<img src='`$npc.media`' />"}
			{/if}
		</td>
		<td>
			<ul class="contactList">
				<li>{link module="NodeViewer" event="`$event`&npc_id=`$npc.npc_id`" text=$npc.name}</li>
				<li>{$npc.description}</li>
			</ul>
		</td>	
	</tr>
{/foreach}
</table>
{/if}