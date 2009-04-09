{if count($available_games) > 0}
<games>
{foreach from=$available_games item=game}
	<game id="{$game.id}" name="{$game.name}" />
{/foreach}
</games>
{else}
<games />
{/if}
