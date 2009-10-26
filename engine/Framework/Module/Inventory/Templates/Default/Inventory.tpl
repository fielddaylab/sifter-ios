<table class="inventoryList">
{if count($inventory) > 0}
{foreach from=$inventory item=item}
	<tr>
		<td><img src="{$item.icon}" width = "50px"></td>
		<td>
			<table>
				<tr><td>
					{if $item.isImage}
						{link text=$item.name module=Inventory event="displayItem&item_id=`$item.item_id`"}
					{else}
						<a href = "{$item.link}" target="_self">{$item.name}</a>
					{/if}
				</td></tr>
				<tr><td>{$item.description}</td></tr>
			</table>
		</td>
	</tr>
{/foreach}
{else}
	<tr><td></td><td>No Items</td></tr>
{/if}
</table>