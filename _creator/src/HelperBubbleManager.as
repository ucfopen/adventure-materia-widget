package {
	import flash.geom.*;
	import Creator;
	import components.bubbles.HelperBubble;
	public class HelperBubbleManager
	{
		// helper bubbles
		public var introBubble:HelperBubble;
		public var endSuggestionBubble:HelperBubble;
		public var destinationsBubble:HelperBubble;
		public var mcBubble:HelperBubble;
		public var saBubble:HelperBubble;
		public var hotspotBubble:HelperBubble;
		public var narrativeBubble:HelperBubble;
		public var endingBubble:HelperBubble;

		public var creator:Creator;


		public function initializeHelpers(creatorRef:Creator):void
		{
			creator = creatorRef;

			introBubble = new HelperBubble();
			introBubble.type = HelperBubble.INTRO;
			introBubble.title = "Welcome to the Adventure Creator!";
			introBubble.description = "These helper bubbles will highlight the important steps to creating an adventure widget. \n\nIn Adventure, you create a decision tree, with individual decision points called nodes. Nodes provide questions, images, and narrative text to the student. Depending on their response, students advance down the decision tree to a final end node.\n\nTo close any helper bubble, simply click on it.";

			endSuggestionBubble = new HelperBubble();
			endSuggestionBubble.type = HelperBubble.END_SUGGESTION;
			endSuggestionBubble.title = "Where you end up determines your score";
			endSuggestionBubble.description = "The student's score is determined by the end node they visit. Each branch of the decision tree must terminate with an end node.\n\nEndings can be unique to that branch, or multiple branches can point to the same end node.";

			destinationsBubble = new HelperBubble();
			destinationsBubble.type = HelperBubble.DESTINATIONS;
			destinationsBubble.title = "Creating Destinations";
			destinationsBubble.description = "Each possible answer is associated with a destination. This destination is the node the student will travel to if they select the associated answer.\n\nThere are three options:\n\n-This Node: Will cause the anwer to loop back to this question, providing a 'do-over'.";
			destinationsBubble.description += "\n\n-New Node: The default. This answer will lead to a new, blank node that you can then create.";
			destinationsBubble.description += "\n\n-Existing Node: This answer will lead to a node that's already been created. You may select from any other previously created node on the tree.";

			mcBubble = new HelperBubble();
			mcBubble.type = HelperBubble.MULTIPLE_CHOICE;
			mcBubble.title = "Creating a Multiple Choice Node";
			mcBubble.description = "To create a multiple choice question, simply fill out the question box and provide at least one possible answer.";

			saBubble = new HelperBubble();
			saBubble.type = HelperBubble.SHORT_ANSWER;
			saBubble.title = "Creating a Short Answer Node";
			saBubble.description = "Short answer nodes are similar to Multiple Choice nodes, with the exception of how students enter their answers.\n\nPossible answers are grouped into answer sets; if a student's response matches an answer, they advance to that answer set's destination."

			hotspotBubble = new HelperBubble();
			hotspotBubble.type = HelperBubble.HOTSPOT;
			hotspotBubble.title = "Creating a Hotspot Node";
			hotspotBubble.description = "Hotspot nodes allow students to select parts of an image to answer a question. To begin, click the camera graphic to upload an image. Use the media uploader tool to use an image from your current media library, or upload a new image from your computer.";
			hotspotBubble.description += "\n\nOnce an image is added, use any of the shape tools to draw shapes over the parts of the image you'd like the student to be able to select.";
			hotspotBubble.description += "\n\nClick a newly created hotspot to set its destination and add optional information.";

			narrativeBubble = new HelperBubble();
			narrativeBubble.type = HelperBubble.NARRATIVE;
			narrativeBubble.title = "Creating a Narrative Node";
			narrativeBubble.description = "A narrative node does not have a question or answers; rather, it provides transitional text or images to move students from one node to the next.";

			endingBubble = new HelperBubble();
			endingBubble.type = HelperBubble.ENDING;
			endingBubble.title = "Ending Your Widget";
			endingBubble.description = "An end node is the final node the student will visit in the Adventure widget. It provides a conclusion to their journey and determines their final score.\n\nUsing multiple end nodes, students may receive different scores depending on where they end up.";

		}

		public function addHelper(helper:HelperBubble):void
		{
			// Temporarily disabling helpers
			return;

			if (helper.visible) return;
			PopUpManager.addPopUp(helper, creator);
			helper.visible = true;
			helper.validateNow();

			var helperPos:Point;
			var destHelperPos:Point;

			switch (helper.type)
			{
				case HelperBubble.INTRO:
					helperPos = new Point(10,60);
					helper.updatePosition(helperPos);
					break;

				case HelperBubble.END_SUGGESTION:
					helperPos = new Point(10, 60 + introBubble.height + 10);
					helper.updatePosition(helperPos);
					break;

				case HelperBubble.DESTINATIONS:
					// helperPos = new Point(creator.width - helper.width - 10, 350);
					break;

				case HelperBubble.MULTIPLE_CHOICE:
				case HelperBubble.SHORT_ANSWER:
				case HelperBubble.HOTSPOT:
				case HelperBubble.NARRATIVE:
					helperPos = new Point(creator.width - helper.width - 10, 100);
					helper.updatePosition(helperPos);

					if (!destinationsBubble.alreadyActivated)
					{
						destHelperPos = new Point(creator.width - helper.width - 10, 100 + helper.measuredHeight + 10);
						destinationsBubble.updatePosition(destHelperPos);
					}

					break;

				case HelperBubble.ENDING:
					helperPos = new Point(creator.width - helper.width - 10, 100);
					helper.updatePosition(helperPos);

					break;
			}


		}
	}
}