angular.module("Adventure")
.service "inventoryService", [() ->

	# Check if player has required items in their inventory
	checkInventory = (inventory, requiredItems) ->
		missingItems = []
		if (! requiredItems)
			return []
		angular.forEach requiredItems, (item) ->
			hasItemInInventory = false
			hasRequiredItem = inventory.some (playerItem) ->
				if playerItem.id is item.id
					hasItemInInventory = true
					# Check if player has more than the min
					if playerItem.count >= item.minCount
						# Check if player has less than the max
						if playerItem.count <= item.maxCount or item.uncappedMax
							return true
					return false
			# Check if player doesn't have item but there is no minimum
			if ! hasItemInInventory and item.minCount is 0
				hasRequiredItem = true
			if ! hasRequiredItem
				missingItems.push item
		return missingItems

	# Get the most recently acquired item in the player's inventory
	getMostRecentItem = (inventory, requiredItems) ->
		mostRecentItem = 0
		for i in inventory
			for r in requiredItems
				if i.id is r.id
					if i.time > mostRecentItem
						mostRecentItem = i.time
		mostRecentItem

	# Select the next question to display based on the player's inventory and visited nodes
	selectQuestion = (q_data, inventory, visitedNodes, shownQuestions, lastSelectedQuestion, defaultQuestion) ->
		mostItems = 0
		mostRecentItem = 0
		mostVisited = 0
		# Track which questions have the most required items and visits, respectively
		questionWithMostItems = null
		questionWithMostVisits = null
		questionWithMostRecent = null

		for q in q_data.options.additionalQuestions
			keepMostVisited = false
			keepMostItems = false
			keepMostRecent = false
			if q.requiredVisits != undefined
				# If the player hasn't visited this node enough times, skip this question
				if visitedNodes[q_data.id] < q.requiredVisits || (q.requiredVisits > 0 && visitedNodes[q_data.id] == undefined)
					continue
				# Keep the question with the most required visits
				# We don't set questionWithMostVisits here because it also needs to have the required items
				if mostVisited <= q.requiredVisits
					mostVisited = q.requiredVisits
					keepMostVisited = true
			# Check if player has required items
			if q.requiredItems && q.requiredItems[0]
				# If the player doesn't have the required items, skip this question
				missingItems = checkInventory(inventory, q.requiredItems)
				if (missingItems.length > 0)
					# This erases the most visited question as well
					continue
				else
					recentItem = getMostRecentItem(inventory, q.requiredItems)
					# Keep the question with the most recent item
					if (recentItem >= mostRecentItem)
						mostRecentItem = recentItem
						keepMostRecent = true
					# Keep the question with the most required items
					else if (mostItems < q.requiredItems.length)
						mostItems = q.requiredItems.length
						keepMostItems = true
			# If the question meets the visits and items requirements and has the most required items and visits, save it
			if keepMostVisited
				questionWithMostVisits = q
			if keepMostItems
				questionWithMostItems = q
			if keepMostRecent
				questionWithMostRecent = q

		# Make the decision on which question to display
		# Question with most recent item takes precedence, then most items, then most visited
		if questionWithMostRecent and shownQuestions.indexOf(questionWithMostRecent) < 0
			selectedQuestion = questionWithMostRecent
		else if questionWithMostItems and shownQuestions.indexOf(questionWithMostItems) < 0
			selectedQuestion = questionWithMostItems
		else if questionWithMostVisits and shownQuestions.indexOf(questionWithMostVisits) < 0
			selectedQuestion = questionWithMostVisits
		# If none of the above conditions are met, just go with the last selected question
		else if lastSelectedQuestion
			# Technically, the last selected question should not be null at this point if the above conditions are false
			selectedQuestion = lastSelectedQuestion
		else
			selectedQuestion = defaultQuestion

		return selectedQuestion

	selectQuestion : selectQuestion
	checkInventory : checkInventory
	getMostRecentItem : getMostRecentItem
]