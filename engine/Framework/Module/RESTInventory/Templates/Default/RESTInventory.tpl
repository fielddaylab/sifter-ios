<playerInventory>
{foreach from=$inventory item=item}
	<item id="{$item.item_id}" name="{$item.name}" type="{$item.type}" description="{$item.description}" iconURL="{$item.icon}" mediaURL="{$item.mediaURL}" />
{/foreach}
</playerInventory>
