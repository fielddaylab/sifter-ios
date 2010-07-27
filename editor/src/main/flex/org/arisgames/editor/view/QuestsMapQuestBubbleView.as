package org.arisgames.editor.view
{
	import mx.containers.VBox;
	import mx.containers.Canvas
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.events.DynamicEvent;
	import mx.events.FlexEvent;
	import flash.events.MouseEvent;
	import flash.display.Sprite;
	import org.arisgames.editor.util.AppConstants;
	import org.arisgames.editor.util.AppDynamicEventManager;
	
	/**
	 * 
	 * @author Will Buck
	 */
	public class QuestsMapQuestBubbleView extends Sprite
	{
		public function QuestsMapQuestBubbleView()
		{
			super();
		}
		
		public function draw():void
		{
			graphics.beginFill(0xFFFFFF);
			graphics.drawCircle(0, 0, 10);
			graphics.drawCircle(6, -3, 1);
			graphics.drawCircle(6, 3, 1);
			graphics.endFill();
		}
	}
}