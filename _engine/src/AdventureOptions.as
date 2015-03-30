package {
/**
 * A collection of constants used in the QSet to help distinguish different
 * options chosen in the adventure creator.
 */
public class AdventureOptions
{
	/* Node Type Constants */
	public static const TYPE_NONE:int = 0;             // Empty, dead or end node
	public static const TYPE_NARRATIVE:int = 1;        // Read the story, maybe see a picture
	public static const TYPE_MULTIPLE_CHOICE:int = 2;  // Select the right answer for the question
	public static const TYPE_HOTSPOT:int = 3;          // Click a hotspot on an image
	public static const TYPE_SHORT_ANSWER:int = 4;     // Fill in the blank
	public static const TYPE_END:int = 5;              // The end to the adventure
	/* Grading Mode Constants */
	public static const MODE_STANDARD:int = 0;         // Deals with scores the way any MC engine would
	public static const MODE_MODIFICATIONS:int = 1;    // Deals only with score modifications
	public static const MODE_ABSOLUTE:int = 2;         // Deals only with absolute score setting
	/* Layout Constants */
	public static const LAYOUT_IMAGE_ONLY:int = 0;     // Layout that contains only an image
	public static const LAYOUT_TEXT_ONLY:int = 1;      // Layout that contains only text
	public static const LAYOUT_HORIZ_TEXT:int = 2;     // Horizontal layout that contains text and then an image
	public static const LAYOUT_HORIZ_IMAGE:int = 3;    // Horizontal layout that contains an image and then text
	public static const LAYOUT_VERT_TEXT:int = 4;      // Vertical layout that contains text and then an image
	public static const LAYOUT_VERT_IMAGE:int = 5;     // Vertical layout that contains an image and then text
	/* Hotspot Constants */
	public static const HOTSPOT_ELLIPSE:int = 0;       // Used for circle hotspots; seaches for point & radius
	public static const HOTSPOT_POLYGON:int = 1;       // Used for polygonal hotspots, searches for pairs of points
	public static const HOTSPOT_RECT:int = 2;          // Used for rectangles
	/* Hotspot Visibility */
	public static const VISIBILITY_ALWAYS:int = 0;     // Keep hotpots visible for user always
	public static const VISIBILITY_HOVER:int = 1;      // Only show hotspots to user on mouse over
	public static const VISIBILITY_NEVER:int = 2;      // Always hide hotspots from user
	/* Score Styles */
	/* DEPRECATED FOR INITIAL ADVENTURE RELEASE - DESTINATION MODE ONLY */

	public static const SCORESTYLE_QUIZ:int = 0;
	public static const SCORESTYLE_QUIZ_TEXT:String = "Quiz";
	public static const SCORESTYLE_QUEST:int = 1;
	public static const SCORESTYLE_QUEST_TEXT:String = "Quest";

	// public static const SCORESTYLE_FREE:int = 2; deprecated in favor of a universal "practice mode" across widgets

	public static const SCORESTYLE_DESTINATION:int = 2;
	public static const SCORESTYLE_DESTINATION_TEXT:String = "Destination";

}
}