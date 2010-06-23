package org.arisgames.editor.view
{
import mx.containers.Canvas;
import mx.effects.Move;
import mx.events.DynamicEvent;
import mx.events.FlexEvent;

import org.arisgames.editor.data.businessobjects.ObjectPaletteItemBO;
import org.arisgames.editor.util.AppConstants;
import org.arisgames.editor.util.AppDynamicEventManager;

public class GameEditorContainerView extends Canvas
{
    [Bindable] public var gameEditorObjectEditor:GameEditorObjectEditorView;
    [Bindable] public var panelOut:Move;
    [Bindable] public var panelIn:Move;
    var isIn:Boolean = true;

    /**
     * Constructor
     */
    public function GameEditorContainerView()
    {
        super();
        this.addEventListener(FlexEvent.CREATION_COMPLETE, handleInit)
    }

    private function handleInit(event:FlexEvent):void
    {
        trace("handling container init")
        AppDynamicEventManager.getInstance().addEventListener(AppConstants.DYNAMICEVENT_EDITOBJECTPALETTEITEM, handleItemEditEventRequest);
        AppDynamicEventManager.getInstance().addEventListener(AppConstants.DYNAMICEVENT_CLOSEOBJECTPALETTEITEMEDITOR, handleCloseItemEditorEventRequest);
    }

    private function handleItemEditEventRequest(event:DynamicEvent):void
    {
        var opi:ObjectPaletteItemBO = event.objectPaletteItem;

        trace("Got handleItemEditEventRequest with object name = '" + opi.name + "'; Icon Media Id = '" + opi.iconMediaId + "'; Media Id = '" + opi.mediaId + "'; Icon Media Object = '" + opi.iconMedia + "'; Media Object = '" + opi.media + "'; Is Folder? = '" + opi.isFolder() + "'");
        if(isIn)
        {
            trace("editor is currently in, so assign the new object and drop it down for the user to use.");
            gameEditorObjectEditor.setObjectPaletteItem(opi);

            panelOut.play();
            isIn = false;
        }
        else
        {
            panelIn.play();
            isIn = true;

            trace("editor is currently down, check to see if this is a new object request");
            if (gameEditorObjectEditor.getObjectPaletteItem() == opi)
            {
                trace("It's the same object, so just retract the editor.");
            }
            else
            {
                trace("This is a new object, so roll out the editor again with the new item.");
                gameEditorObjectEditor.setObjectPaletteItem(opi);

                panelOut.play();
                isIn = false;
            }
        }
    }

    private function handleCloseItemEditorEventRequest(event:DynamicEvent):void
    {
        trace("Got handleCloseItemEditorEventRequest....")
        if (isIn)
        {
            trace("The panel's already in so not doing anything...");
        }
        else
        {
            trace("Closing the panel.");
            panelIn.play();
            isIn = true;
        }
    }
}
}