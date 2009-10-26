<nearbyLocations>
{foreach from=$links item=object}
	{if $object.object_type == 'Item'}
		<item id="{$object.item_id}" locationID="{$object.location_id}" name="{$object.name}" type="{$object.type}" description="{$object.description}" forceView="{$object.force_view}" iconURL="{$object.icon}" mediaURL="{$object.mediaURL}" />
	{else}
		<nearbyLocation type="{$object.type}" forceView="{$object.force_view}" id="{$object.id}" label="{$object.label}" iconURL="{$object.icon}" URL = "{$object.url}"/>
	{/if}
{/foreach}
</nearbyLocations>