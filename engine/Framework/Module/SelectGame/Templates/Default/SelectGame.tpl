<p>Games available for {$full_name}</p>

<table class="gameList">
{if count($available_games) > 0}
	{foreach from=$available_games item=game}
		<h2>{link text=$game.name module=SelectGame event="loadGame&prefix=`$game.prefix`"}</h2>
	{/foreach}
{else}
	<tr><td></td><td>No Games Available</td></tr>
{/if}
</table>