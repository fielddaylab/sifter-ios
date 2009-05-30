{if count($locations) > 0}
<locations>
{foreach from=$locations item=location}
	<location id="{$location.location_id}" name="{$location.name}" latitude="{$location.latitude}" longitude="{$location.longitude}" hidden="{$location.hidden}" />
{/foreach}
{foreach from=$players item=player}
	<player name="{$player.user_name}" latitude="{$player.latitude}" longitude="{$player.longitude}"/>
{/foreach}
</locations>
{else}
<locations />
{/if}
