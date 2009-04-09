<form name="locations" id="locations">
	<input type="hidden" name="location_id" id="location_id" value="" />
	<fieldset>
		<legend>Descriptions</legend>
		<label for="name">Name:</label>
		<input name="name" id="name" />
		<label for="description">Description:</label>
		<input name="description" id="description" maxLength="255"/>
		<label for="media">Media:</label>
		<select name="media" id="media">
			<option value="">N/A</option>
{foreach from=$mediaFiles item=file}
			<option value="{$file}">{$file}</option>
{/foreach}
		</select>
	</fieldset>
	<fieldset>
		<legend>Events</legend>
		<label for="require_event_id">Required Event:</label>
		<select name="require_event_id" id="require_event_id">
			<option value="">N/A</option>
{foreach from=$requireEvents item=event}
			<option value="{$event.event_id}">{$event.description}</option>
{/foreach}		
		</select>
		<label for="remove_if_event_id">Hide With Event:</label>
		<select name="remove_if_event_id" id="remove_if_event_id">
			<option value="">N/A</option>
{foreach from=$removeEvents item=event}
			<option value="{$event.event_id}">{$event.description}</option>
{/foreach}
		</select>
	</fieldset>
	<fieldset>
		<legend>GPS</legend>
		<label for="latitude">Latitude:</label>
		<input name="latitude" id="latitude" />
		<label for="longitude">Longitude:</label>
		<input name="longitude" id="longitude" />
	</fieldset>
</form>