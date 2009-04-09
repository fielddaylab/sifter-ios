<nearbyLocations>
{foreach from=$links item=link}
	<nearbyLocation type="{$link.type}" id="{$link.id}" label="{$link.label}" iconURL="{$link.icon}" URL = "{$link.url}"/>
{/foreach}
</nearbyLocations>