package org.arisgames.editor.models
{
import org.arisgames.editor.data.Game;
import org.arisgames.editor.data.PlaceMark;
import org.arisgames.editor.data.businessobjects.QuestBubbleBO;
import mx.collections.ArrayCollection;


public class GameModel
{
    // Singleton Pattern
    public static var instance:GameModel;

    // Data
    [Bindable] public var game:Game;
    [Bindable] public var currentPlaceMark:PlaceMark;
	public var questBubbles:ArrayCollection;

    /**
     * Singleton constructor... will throw error if accessed directly
     */
    public function GameModel()
    {
        if (instance != null)
        {
            throw new Error("GameModel is a singleton, can only be accessed by calling getInstance() function.");
        }
        instance = this;
        game = new Game();
		questBubbles = new ArrayCollection(); 	
    }

    public static function getInstance():GameModel
    {
        if (instance == null)
        {
            instance = new GameModel();
        }
        return instance;
    }

    public function addPlaceMark(pm:PlaceMark):void
    {
        if (!game.placeMarks.contains(pm))
        {
            game.placeMarks.addItem(pm);
        }
    }

    public function removePlaceMark(pm:PlaceMark):void
    {
        var index:int = game.placeMarks.getItemIndex(pm);
        if (index != -1)
        {
            game.placeMarks.removeItemAt(index);    
        }
    }
	
	public function getQuestBubbleByQuestId(id:Number):QuestBubbleBO
	{
		for each(var qB:QuestBubbleBO in questBubbles)
		{
			if (qB.quest.questId == id) return qB
		}
		return null;
	}
}
}