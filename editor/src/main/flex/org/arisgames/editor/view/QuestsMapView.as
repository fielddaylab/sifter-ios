package org.arisgames.editor.view
{
	import mx.containers.Box;
	import mx.containers.Canvas
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.effects.Move;
	import mx.events.DynamicEvent;
	import mx.events.FlexEvent;
	import flash.events.MouseEvent;
	import org.arisgames.editor.util.AppConstants;
	import org.arisgames.editor.util.AppDynamicEventManager;
	import org.arisgames.editor.data.arisserver.Quest;
	import org.arisgames.editor.data.arisserver.Requirement;
	import org.arisgames.editor.data.businessobjects.QuestBubbleBO;
	import org.arisgames.editor.models.GameModel;
	
	/**
	 * Visualized map of Quests, allows users to add delete and edit quests in a treemap style sequence.
	 * 
	 * @author Will Buck
	 */
	public class QuestsMapView extends Canvas
	{
		[Bindable] public var mapArea:Box;
		[Bindable] public var closeQuestsMapButton:Button;
		[Bindable] public var saveQuestsMapButton:Button;
		[Bindable] public var addQuestButton:Button;
		//[Bindable] public var questEditor:QuestsMapQuestEditorView;
		[Bindable] public var questEditShow:Move;
		[Bindable] public var questEditHide:Move;
		// TODO: WB Need a "currently editing quest" for the QuestEditorView
		private var isEditorVis:Boolean = false;
		private var masterRootQuestBubble:QuestBubbleBO;
		private var masterEndQuestBubble:QuestBubbleBO;
		
		public function QuestsMapView()
		{
				super();
				this.addEventListener(FlexEvent.CREATION_COMPLETE, onComplete);
				masterRootQuestBubble = new QuestBubbleBO();
				masterRootQuestBubble.quest = new Quest();
				masterRootQuestBubble.quest.questId = 0;
				masterEndQuestBubble = new QuestBubbleBO();
				masterEndQuestBubble.quest = new Quest();
				masterEndQuestBubble.quest.questId = 0;
		}
		
		private function onComplete(event:FlexEvent):void
		{
			closeQuestsMapButton.addEventListener(MouseEvent.CLICK, onCloseButtonClick);
			saveQuestsMapButton.addEventListener(MouseEvent.CLICK, onSaveButtonClick);
			addQuestButton.addEventListener(MouseEvent.CLICK, onAddQuestButtonClick);
			loadQuestBubblesRelationalData();
			drawQuestBubble(mapArea.width/2, mapArea.height/2, 10, 5, 0);
		}
		
			
		private function loadQuestBubblesRelationalData():void 
		{
			trace("Loading quest bubbles for the QuestsMap to use")
			
			for each(var qB:QuestBubbleBO in GameModel.getInstance().questBubbles)
			{
				qB.parentQuestId = 0; // By default
				for each(var r:Requirement in GameModel.getInstance().game.requirements)
				{
					if (r.requirement == AppConstants.REQUIREMENT_PLAYER_HAS_COMPLETED_QUEST_DATABASE && Number(r.requirementDetail1) == qB.quest.questId && r.contentType == AppConstants.REQUIREMENTTYPE_QUEST_DISPLAY)
					{
						qB.childQuestIds.addItem(r.contentId as Number);
					}
					else if (r.contentType == AppConstants.REQUIREMENTTYPE_QUEST_DISPLAY && r.contentId == qB.quest.questId && r.requirement == AppConstants.REQUIREMENT_PLAYER_HAS_COMPLETED_QUEST_DATABASE)
					{
						qB.parentQuestId = Number(r.requirementDetail1);
					}
				}
				if (qB.parentQuestId == 0) qB.parentQuestId = masterRootQuestBubble.quest.questId;
				if (qB.childQuestIds.length == 0) qB.childQuestIds.addItem(masterEndQuestBubble.quest.questId);
			}
			
			
			
		}
		
		private function onCloseButtonClick(event:MouseEvent):void
		{
			var de:DynamicEvent = new DynamicEvent(AppConstants.DYNAMICEVENT_CLOSEQUESTSMAP);
			AppDynamicEventManager.getInstance().dispatchEvent(de);
		}
		
		private function onSaveButtonClick(event:MouseEvent):void
		{
			Alert.show("Functionality still in progress, not yet working!");
		}
		
		private function onAddQuestButtonClick(event:MouseEvent):void
		{
			if (!isEditorVis)
			{
				trace("No quest editor currently open, so lets open it up and create a new quest!");
				questEditShow.play();
			}
			else
			{
				trace("Closing currently open quest editor so we can add a new one!");
			}
		}
		
		private function drawQuestBubble(x:Number, y:Number, rad:Number, smallRad:Number, qId:Number):void
		{
			var bubble:QuestsMapQuestBubbleView = new QuestsMapQuestBubbleView(x, y, rad, smallRad, qId);
			this.addChild(bubble);
		}
	}
}