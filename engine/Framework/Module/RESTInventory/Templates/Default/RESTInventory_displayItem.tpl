<p class="notification">{$message}</p>
<p align="center"><img width = "250px" id="itemImg" src="{$media}"/></p>
<p align="center">{$item.description}</p>
<hr/>
<p>{link text="Drop Item Here" module=RESTInventory event="dropItemHere&item_id=`$item.item_id`"}</p>
<p>{link text="Destroy this Item" module=RESTInventory event="destroyPlayerItem&item_id=`$item.item_id`"}</p>
