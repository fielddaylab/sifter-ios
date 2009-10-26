<table class="questList">
	<caption>Active Tasks</caption>
	<tbody>
{if count($activeQuests) > 0}
{foreach from=$activeQuests item=quest}
	<tr>
		<td><img src="{$quest.media}"></td>
		<td>
			<ul>
				<li>{$quest.name}</li>
				<li>{$quest.description}</li>
			</ul>
		</td>
	</tr>
{/foreach}
	</tbody>
{else}
	<tr><td></td><td>No active tasks.</td></tr>
{/if}
</table>
<table class="questList">
	<caption>Completed Tasks</caption>
	<tbody>
{if count($completedQuests) > 0}
{foreach from=$completedQuests item=quest}
	<tr>
		<td><img src="{$quest.media}"></td>
		<td>
			<ul>
				<li>{$quest.name}</li>
				<li>{$quest.text_when_complete}</li>
			</ul>
		</td>
	</tr>
{/foreach}
{else}
	<tr><td></td><td>No completed tasks.</td></tr>
{/if}
	</tbody>
</table>