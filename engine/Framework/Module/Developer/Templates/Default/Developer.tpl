{if isset($message)}
<p class="notification">{$message}</p>
{/if}
<p>Set current location to:</p>
{if count($locations) > 0}
<ul class = 'developer'>
{foreach from=$locations item=location}
	<li><a target="_self" href='javascript:update_location({$location.latitude},{$location.longitude});'>{$location.name}</a></li>
{/foreach}
</ul>
{else}
	<p>No Locations defined in this game.<p>
{/if}

<p>{link text='Delete All Player Events' module=Developer event="deleteAllEvents"}</p>
<p>{link text='Delete All Player Items' module=Developer event="deleteAllItems"}</p>
