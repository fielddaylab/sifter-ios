<QRCodes>
{if $object.QRType == 'Item'}
	<Item id="{$object.item_id}" name="{$object.name}" itemType="{$object.type}" description="{$object.description}" iconURL="{$object.icon}" mediaURL="{$object.mediaURL}" />
{else}
	<QRCode type="{$object.type}" forceView="{$object.force_view}" id="{$object.id}" name="{$object.name}" iconURL="{$object.icon}" URL = "{$object.url}"/>
{/if}
</QRCodes>