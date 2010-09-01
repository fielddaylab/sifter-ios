package org.arisgames.editor.data
{
import mx.collections.ArrayCollection;

[Bindable]
public class Game
{
    public var gameId:int;
    public var name:String;
    public var description:String;
    public var placeMarks:ArrayCollection;
    public var gameObjects:ArrayCollection;
	public var quests:ArrayCollection;
	public var requirements:ArrayCollection; // WB NOTE: This object is being loaded up for QuestBubbles, the RequirementsEditor code loads and uses its own requirements. 
											// We will need to refactor out the ReqsEditor copy of this data to keep a consistent usage.
    
    public function Game()
    {
        super();
        placeMarks = new ArrayCollection();
        gameObjects = new ArrayCollection();
		quests = new ArrayCollection();
		requirements = new ArrayCollection();
    }
}
}