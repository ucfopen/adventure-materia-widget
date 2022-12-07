Adventure = angular.module "Adventure"
Adventure.service "treeSrv", ['$rootScope','$filter','$sanitize','legacyQsetSrv', ($rootScope, $filter, $sanitize, legacyQsetSrv) ->

	# TreeData is being initialized in -two- places right now.
	# This one may or may not be required.
	treeData =
		name: "Start"
		type: "blank"
		id: 0
		parentId: -1
		contents: []

	# Characters that need to be pre-sanitize before being run through angular's $sanitize directive
	PRESANITIZE_CHARACTERS =
		'>' : '&gt;',
		'<' : '&lt;'

	# Iterator that generates node IDs
	count = 1

	inventoryItems = []

	customIcons = []

	# Self explanatory getter function
	get = ->
		treeData

	# Updating the tree prompts a redraw of the D3 visualization
	set = (data) ->
		treeData = data
		$rootScope.$broadcast "tree.nodes.changed"

	getNodeCount = ->
		count

	setNodeCount = (val) ->
		count = val

	incrementNodeCount = ->
		count++

	getInventoryItems = ->
		inventoryItems

	setInventoryItems = (val) ->
		inventoryItems = val

	generateItemID = ->
		if (inventoryItems[0])
			return Math.floor(inventoryItems[inventoryItems.length - 1].id + Math.random() * 2 + 1)
		else
			return Math.floor(Math.random() * 2 + 1)
	
	getItemIndex = (itemID) ->
		for i, index in inventoryItems
			if i.id is itemID
				return index

	# Methods for custom icons
	getCustomIcons = ->
		customIcons

	setCustomIcons = (val) ->
		customIcons = val

	# Max depth is the maximum tree depth, used for determining height of the D3 canvas
	getMaxDepth = ->
		findMaxDepth treeData

	##
	## NOTE: SHOULD THE FOLLOWING 3 FUNCTIONS BE CONDENSED INTO ONE?
	##

	# Recursive function for fetching a node's data based on its ID.
	# tree: the tree structure to be iterated. Should initially reference the root node (treeData object)
	# id: id of the node of which to grab data
	findNode = (tree, id) ->

		if tree.id == id then return tree

		if !tree.contents then return null

		# iterator required instead of using angular.forEach
		i = 0

		while i < tree.contents.length

			child = tree.contents[i]

			if child.id == id
				return child
			else
				node =  findNode tree.contents[i], id
				if node isnt null then return node
				i++
		null

	# Recursive function for adding a node to a specified parent node
	# tree: the tree structure to be iterated. Should initially reference the root node (treeData object)
	# parentId: the ID of the node to append the new node to
	# node: the data of the new node
	findAndAdd = (tree, parentId, node, success=false) ->

		if tree.id == parentId
			tree.contents.push node
			return success = true

		if !tree.contents then return success

		i = 0

		while i < tree.contents.length

			child = tree.contents[i]

			if child.id == parentId
				child.contents.push node
				return success = true
			else
				success = findAndAdd tree.contents[i], parentId, node, success
				i++

		success

	# Recursive function for replacing a given node on a tree with another node
	# tree: the tree structure to be iterated. Should initially reference the root node
	# parentId: the ID of the node to be replaced
	# node: the node to replace the node of the given ID with
	findAndReplace = (tree, id, node) ->

		if tree.id == id
			tree = node
			return tree

		if !tree.contents then return false

		i = 0

		while i < tree.contents.length

			child = tree.contents[i]
			if child.id == id
				tree.contents[i] = node
				return tree
			else
				next = findAndReplace tree.contents[i], id, node
				if next isnt false then return tree
				i++

		false

	# Recursive function for adding a node in between a given parent and child, essentially splitting an existing link
	# tree: the tree structure to be iterated. Should initially reference the root node (treeData object)
	# parentId: the ID of the parent node that serves as the source of the existing link
	# childId: the ID of the child node that serves as the target of the existing link
	# node: the node to be added between the parent and child
	findAndAddInBetween = (tree, parentId, childId, node) ->

		if tree.id == parentId

			# Determine if the addInBetween method is being targeted at a non-hierarchical link
			# If so, we have to add a new blank node as a child of the source (parentId)
			# Then point an existing node link from the new node to the intended target
			if node.hasLinkToOther and tree.hasLinkToOther

				# annoying flag for determining whether to clean the hasLinkToOther flag
				# If there's only one existing link, then when the answer is updated to point to a NEW node, remove the flag
				# Otherwise, if there's more than one, keep it
				numExistingNodeLinks = 0

				# Another annoying flag to confirm that only one node is actually added in this process
				# If there are multiple existing links connecting the same parent & target nodes
				nodeAlreadyAdded = false

				# If we're adding a node in front of a node pointing to another node using an existing link...
				# This is making my head hurt
				unless tree.answers
					if tree.pendingTarget is childId
						tree.pendingTarget = node.id
						tree.contents.push node

						numExistingNodeLinks++

				# The -normal- scenario, the node has answers, find the right answer and update it to point to the new node
				angular.forEach tree.answers, (answer, index) ->
					if answer.target is childId and answer.linkMode is "existing" and nodeAlreadyAdded is false

						tree.contents.push node
						answer.target = node.id
						answer.linkMode = "new"

						numExistingNodeLinks++
						nodeAlreadyAdded = true

					else if answer.linkMode is "existing" then numExistingNodeLinks++

				if numExistingNodeLinks is 1 then delete tree.hasLinkToOther
				if numExistingNodeLinks > 0 then return tree

			# The link is a traditional one. Search parent's answers and update the right one
			else

				# If the tree doesn't have answers, it's assumed to be a blank node
				# If we're adding a new child node underneath the blank, it should have a pending target
				unless tree.answers
					if tree.pendingTarget is childId then tree.pendingTarget = node.id

				else
					i = 0
					while i < tree.answers.length
						# Update the parent node's associated answer target with the new node ID
						if tree.answers[i].target is childId and tree.answers[i].linkMode is "new" then tree.answers[i].target = node.id
						i++

			# First, find reference to childId in list of parent's children
			n = 0
			while n < tree.contents.length

				child = tree.contents[n]

				if child.id == childId # reference to childId found

					# make sure the child knows who its new momma is
					child.parentId = node.id

					# Set new node's child to the child node
					node.children = [child]
					node.contents = [child]

					# Replace tree's existing child with new node
					tree.contents[n] = node

					return tree # return the revised tree
				else
					n++ # No recursion, since the childId node has to be a direct child of the parentId node

		if ! tree.contents then return

		i = 0

		while i < tree.contents.length
			findAndAddInBetween tree.contents[i], parentId, childId, node
			i++

		tree

	# Recursive function for finding a node and removing it
	# parent: the tree structure to be iterated. Should initially reference the root node (treeData object)
	# id: the id the node to be removed
	# Returns an array of IDs for all nodes deleted (the target node and all of its children)
	findAndRemove = (parent, id, removed = null) ->

		if !parent.contents then return removed

		# iterator required instead of using angular.forEach
		i = 0

		while i < parent.contents.length

			child = parent.contents[i]

			if child.id == id

				# also remove parent's answer row corresponding to this node
				# provided the parent isn't blank, of course
				if parent.answers
					j = 0
					while j < parent.answers.length
						if parent.answers[j].target == id
							parent.answers.splice j, 1
							break
						else
							j++

				# If the parent of the deleted node is blank but still links to this node via pendingTarget, remove the flag
				if parent.pendingTarget and parent.pendingTarget is id then delete parent.pendingTarget

				parent.contents.splice i, 1
				# Grab the array of IDs representing all deleted nodes (child + children of child)
				removed = getIdsFromSubtree child
			else
				removed = findAndRemove parent.contents[i], id, removed
				i++

		return removed

	# Returns an array of IDs representing all nodes in a given tree
	getIdsFromSubtree = (tree, ids = []) ->

		ids.push tree.id

		if !tree.contents then return ids

		i = 0

		while i < tree.contents.length

			ids = getIdsFromSubtree tree.contents[i], ids
			i++

		ids

	# This is a really circumstantial one that searches through answers in a tree that point to a given target
	# If it finds an answer with that target, it resets the answer to a newly created node
	# This is for instances where a node is deleted with "existing"/non-hierarchical links pointing to it
	# Those non-hierarchical links are replaced with links to new nodes instead
	findAndFixAnswerTargets = (tree, targetId) ->

		# Flag to determine if the hasLinkToOther flag needs to be removed from a node after fixing a broken link
		numExistingNodeLinks = 0

		# iterate through answers of current node
		if tree.answers
			angular.forEach tree.answers, (answer, index) ->
				# if answer target matches id, update it with a new, blank target node
				if answer.target is targetId

					# Since we're making a new target node, generate a new ID and name
					newId = getNodeCount()
					incrementNodeCount()
					newName = integerToLetters newId

					# Create the data for the new node
					newNode =
						name: "#{newName}"
						id: newId
						parentId: tree.id
						type: "blank"
						contents: []

					# Update the answer too
					answer.target = newId
					answer.linkMode = "new"

					# Update the tree
					findAndAdd treeData, tree.id, newNode

				else if answer.linkMode is "existing" then numExistingNodeLinks++

		# the answer array and pendingTarget properties -should- never coexist.
		else if tree.pendingTarget and tree.pendingTarget is targetId

			newId = getNodeCount()
			incrementNodeCount()
			newName = integerToLetters newId

			newNode =
				name: "#{newName}"
				id: newId
				parentId: tree.id
				type: "blank"
				contents: []

			tree.pendingTarget = newId

			findAndAdd treeData, tree.id, newNode

		if tree.hasLinkToOther and numExistingNodeLinks is 0 then delete tree.hasLinkToOther

		if !tree.contents then return

		i = 0

		while i < tree.contents.length

			child = tree.contents[i]

			findAndFixAnswerTargets child, targetId

			i++

	# Recurses through the given tree and finds all answers that point to the given target ID
	# For each answer, creates an object with the answer's node ID & text and appends it to an array that's then returned
	findAnswersWithTarget = (tree, target, answers = null) ->

		if answers is null then answers = []

		# Check all answers for the given node (tree) and create a matching answer object if the answer is targeting the target node
		angular.forEach tree.answers, (answer, index) ->
			if answer.target is target

				newAnswer = {}
				newAnswer.parent = tree.id

				parentNode = findNode(tree, tree.id)

				if answer.text isnt null and answer.text.length > 0 then newAnswer.text = answer.text
				else if parentNode.type is "mc" or parentNode.type is "shortanswer" 
					newAnswer.text = "[No Answer Text]"
				else
					newAnswer.text = "N/A"

				answers.push newAnswer

		# If there's a pending target, and it matches, create an object with special text and add it
		if tree.pendingTarget and tree.pendingTarget is target

			pendingAnswer = {}
			pendingAnswer.parent = tree.id
			pendingAnswer.text = "[No Answer Yet; Edit #{integerToLetters(tree.id)} First!]"

			answers.push pendingAnswer

		if !tree.contents then return answers

		i = 0

		while i < tree.contents.length

			child = tree.contents[i]

			answers = findAnswersWithTarget tree.children[i], target, answers

			i++

		return answers

	# Recursive function to update the answerLinks property for all nodes in the tree
	# This is called any time an answer is added or removed or modified
	# tree should be a reference to the root node initially, e.g., treeData
	updateAllAnswerLinks = (tree) ->

		tree.answerLinks = findAnswersWithTarget treeData, tree.id

		if !tree.contents then return

		i = 0

		while i < tree.contents.length

			child = tree.contents[i]

			updateAllAnswerLinks child

			i++

		return

	deleteItemReferencesFromAllNodes = (tree, deletedItem) ->
		if tree.items
			for item, index in tree.items
				if item.id is deletedItem.id
					tree.items.splice index, 1
					break

		if tree.answers
			for answer in tree.answers
				if answer.requiredItems
					for item, index in answer.requiredItems
						if item.id is deletedItem.id
							answer.requiredItems.splice index, 1
							break

		if !tree.contents then return

		i = 0

		while i < tree.contents.length

			child = tree.contents[i]

			deleteItemReferencesFromAllNodes child, deletedItem

			i++

		
		return

	# Probably deprecated??
	findMaxDepth = (tree, depth=0) ->

		if !tree.children
			if tree.depth > depth
				depth = tree.depth

			return depth

		i = 0

		while i < tree.children.length

			child = tree.children[i]

			depth = findMaxDepth child, depth

			i++

		return depth

	createQSetFromTree = (tree) ->

		qset =
			items: formatTreeDataForQset tree, []
			options:
				nodeCount: count
				inventoryItems: inventoryItems
				customIcons: customIcons
		console.log(qset)
		return qset


	formatTreeDataForQset = (tree, items) ->

		if !tree.children or (($filter('filter')(items, {nodeId : tree.id}, true)).length is 0)

			questionItemData = []
			if tree.items
				for item in tree.items
					formattedItem =
						id: item.id
						count: item.count || 1
						firstVisitOnly: item.firstVisitOnly || false
						takeAll: item.takeAll || false
					questionItemData.push(formattedItem)

			itemData =
				materiaType: "question"
				id: null
				nodeId: tree.id # duplicate of options.id, needed for $filter query (removed by Materia when saved to DB)
				type: "Adventure" # This is NOT the node type, but rather the type of qset question Materia should expect.
				questions: []
				options:
					id: tree.id
					parentId: tree.parentId
					type: tree.type
					redirectId: tree.redirectId
					items: questionItemData
				answers: []

			question =
				text: if tree.question then tree.question else ""

			itemData.questions.push question

			if tree.media
				itemData.options.asset =
					materiaType: "asset"
					align: tree.media.align # replacement of "layout" parameter
					id: if tree.media.id then tree.media.id else undefined # video assets will NOT have an ID!
					url: tree.media.url
					type: tree.media.type # right now just "image", will be expanded upon in the future

				if tree.media.type is 'image'
					itemData.options.asset.alt = if tree.media.alt then tree.media.alt else ''

			switch tree.type
				when "mc"
					itemData.options.randomize = tree.randomizeAnswers
				when "hotspot"
					itemData.options.visibility = tree.hotspotVisibility
					if tree.legacyScaleMode then itemData.options.legacyScaleMode = true
				when "end"
					itemData.options.finalScore = tree.finalScore

			if tree.hasLinkToOther then itemData.options.hasLinkToOther = true
			if tree.hasLinkToSelf then itemData.options.hasLinkToSelf = true
			if tree.pendingTarget then itemData.options.pendingTarget = tree.pendingTarget

			angular.forEach tree.answers, (answer, index) ->
				requiredItemsData = []

				if answer.requiredItems
					for i in answer.requiredItems
						do (i) ->
							formattedItem =
								id: item.id
								minCount: i.minCount || i.tempMinCount || 1
								maxCount: i.maxCount || i.tempMaxCount || 1
								uncappedMax: i.uncappedMax || (i.maxCount || i.tempMaxCount ? false : true)
							requiredItemsData.push formattedItem

				itemAnswerData =
					text: answer.text
					value: 0
					options:
						link: answer.target
						linkMode: answer.linkMode
						feedback: answer.feedback
						requiredItems: requiredItemsData
						hideAnswer: answer.hideAnswer

				switch tree.type
					when "shortanswer"
						itemAnswerData.options.matches = answer.matches
						itemAnswerData.options.caseSensitive = answer.caseSensitive
						itemAnswerData.options.characterSensitive = answer.characterSensitive
						if answer.isDefault then itemAnswerData.options.isDefault = true

					when "hotspot"
						itemAnswerData.options.svg = answer.svg

				itemData.answers.push itemAnswerData

			items.push itemData

			if !tree.children then return items

		i = 0

		while i < tree.children.length

			child = tree.children[i]
			items = formatTreeDataForQset child, items
			i++

		return items

	createTreeDataFromQset = (qset) ->

		orphans = []
		tree = {}

		if qset.options.nodeCount then setNodeCount qset.options.nodeCount

		if qset.options.inventoryItems then setInventoryItems qset.options.inventoryItems

		if qset.options.icons then setIcons qset.options.icons

		angular.forEach qset.items, (item, index) ->

			# this is to exclusively handle how the mwdk treats the start node's id: 0 property in its qset options
			if index == 0 and typeof(item.options.id) is "string" and item.options.id.match(/^(mwdk-mock-id-[A-Za-z0-9\-]+)$/)[0] then item.options.id = 0

			node =
				id: item.options.id
				name: integerToLetters item.options.id
				parentId: item.options.parentId
				type: item.options.type
				contents: []

			if item.questions[0].text then node.question = item.questions[0].text

			if item.options.asset
				if item.options.asset.type is 'image'
					node.media =
						id: item.options.asset.id
						url: Materia.CreatorCore.getMediaUrl item.options.asset.id
						align: item.options.asset.align
						type: item.options.asset.type
						alt: if item.options.asset.alt then item.options.asset.alt else ''
				else
					node.media =
						id: item.options.asset.id
						url: item.options.asset.url
						align: item.options.asset.align
						type: item.options.asset.type

			switch item.options.type
				when "mc"
					if item.options.randomize then node.randomizeAnswers = item.options.randomize else node.randomizeAnswers = false
				when "hotspot"
					node.hotspotVisibility = item.options.visibility
					if item.options.legacyScaleMode then node.legacyScaleMode = true
				when "end"
					node.finalScore = item.options.finalScore

			if item.options.hasLinkToOther then node.hasLinkToOther = true
			if item.options.hasLinkToSelf then node.hasLinkToSelf = true
			if item.options.pendingTarget then node.pendingTarget = item.options.pendingTarget

			angular.forEach item.answers, (answer, index) ->

				unless node.answers then node.answers = []

				requiredItemsData = []

				if answer.options.requiredItems
					for i in answer.options.requiredItems
						do (i) ->
							formattedItem =
								id: i.id
								minCount: i.minCount || i.tempMinCount || 1
								maxCount: i.maxCount || i.tempMaxCount || 1
								uncappedMax: i.uncappedMax || (i.maxCount || i.tempMaxCount ? false : true)
							requiredItemsData.push formattedItem

				nodeAnswer =
					text: answer.text
					value: answer.value
					target: answer.options.link
					linkMode: answer.options.linkMode
					feedback: answer.options.feedback
					id: generateAnswerHash()
					requiredItems: requiredItemsData
					hideAnswer: answer.options.hideAnswer

				switch item.options.type
					when "shortanswer"
						nodeAnswer.matches = answer.options.matches
						nodeAnswer.caseSensitive = answer.options.caseSensitive
						nodeAnswer.characterSensitive = answer.options.characterSensitive

						if answer.options.isDefault then nodeAnswer.isDefault = true

					when "hotspot"
						nodeAnswer.svg = answer.options.svg

				node.answers.push nodeAnswer

			if item.options.items
				angular.forEach item.options.items, (inventoryItem, index) ->
					unless node.items then node.items = []
					nodeItem =
						id: inventoryItem.id
						count: inventoryItem.count || 1
						firstVisitOnly: inventoryItem.firstVisitOnly || false
						takeAll: inventoryItem.takeAll || false

					node.items.push nodeItem

			# Logic to append node to its intended position on the tree
			if node.parentId is -1 then tree = node
			else
				# if a node isn't successfully added to the tree due to improper ordering, add it to the orphanage
				unless findAndAdd(tree, node.parentId, node) then orphans.push node


		# Now that all nodes that are in the "normal" arrangement are appended, work out appending all orphaned nodes
		i = 0
		previousCount = 0 # used to check whether the node count has changed every time i is reset to the max value (prevents infinite loops)

		while i < orphans.length
			if findAndAdd(tree, orphans[i].parentId, orphans[i]) then orphans.splice i, 1
			i++

			# If there are still nodes left, and i is -1, and the node array length has changed since the last reset, update i
			# (Should never happen) but if previousCount matches, no new nodes are being pulled off the array & it'll recurse infinitely
			if orphans.length and i >= orphans.length and orphans.length isnt previousCount
				i = 0
				previousCount = orphans.length

		tree

	validateTreeOnStart = (tree) ->

		nodes = queueNodesForValidation tree
		ids = []
		errors = []
		ids = createIdArray nodes

		angular.forEach nodes, (node, index) ->

			angular.forEach node.answers, (answer, answerIndex) ->

				if ids.indexOf(answer.target) is -1
					error =
						node: node.id
						target: answer.target
						type: "missing_answer_node"

					errors.push error
				#

			if node.hasLinkToOther or node.hasLinkToSelf

				existingCount = 0
				selfCount = 0

				angular.forEach node.answers, (answer, answerIndex) ->

					if answer.linkMode is "existing" then existingCount++
					else if answer.linkMode is "self" then selfCount++

				if existingCount is 0 and node.hasLinkToOther
					delete node.hasLinkToOther
					console.warn "Warning: Node " + node.name + " retained the hasLinkToOther flag but no existing links existed. The flag was removed."
				if selfCount is 0 and node.hasLinkToSelf
					delete node.hasLinkToSelf
					console.warn "Warning: Node " + node.name + " retained the hasLinkToSelf flag but no self links existed. The flag was removed."

		return errors

	validateTreeOnSave = (tree) ->

		nodes = queueNodesForValidation tree
		errors = []

		angular.forEach nodes, (node, index) ->

			if node.type is "blank"
				error =
					node: node.id
					type: "blank_node"

				errors.push error

			else if node.type isnt "end" and (!node.answers or !node.answers.length)
				error =
					node: node.id
					type: "has_no_answers"

				errors.push error

			else if node.type is "end" and node.finalScore is null
				error =
					node: node.id
					type: "has_no_final_score"

				errors.push error

			else
				if node.question and node.question.length > 0
					try
						# Run question text thru pre-sanitize routine because $sanitize is fickle about certain characters like >, <
						presanitized = node.question
						for k, v of PRESANITIZE_CHARACTERS
							presanitized = presanitized.replace k, v
					catch e
						error =
							node: node.id
							type: "has_bad_html"

						errors.push error

			if node.type is "hotspot"
				angular.forEach node.answers, (answer, index) ->
					if answer.text is null or answer.text.length is 0
						error =
							node: node.id
							type: "no_hotspot_label"
							target: answer.target

						errors.push error

			#f node.answers and


		return errors


	queueNodesForValidation = (tree, arr = null) ->

		if arr is null then arr = []

		arr.push tree

		if !tree.contents then return arr

		i = 0

		while i < tree.contents.length

			arr = queueNodesForValidation tree.contents[i], arr
			i++

		return arr

	createIdArray = (nodeArray) ->

		ids = []

		angular.forEach nodeArray, (node, index) ->
			ids.push node.id

		return ids


	# Helper function that converts node IDs to their respective alphabetical counterparts
	# e.g., 1 is "A", 2 is "B", 26 is "Z", 27 is "AA", 28 is "AB"
	integerToLetters = (val) ->

		if val is 0 then return "Start"

		iteration = 0
		prefix = ""

		while val > 26
			iteration++
			val -= 26

		if iteration > 0 then prefix = String.fromCharCode 64 + iteration

		chars = prefix + String.fromCharCode 64 + val

		chars

	# Since answers for the same node can share the same targets, they also need a unique id to reference
	# The id doesn't have to persist across qset saves, it's generated on-the-fly when a new answer is added
	# Or when the tree is first generated from a stored QSet
	generateAnswerHash = ->

		s = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

		Array.apply(null, Array(6)).map( ->
			return s.charAt Math.floor(Math.random() * s.length)
		).join ''

	get : get
	set : set
	getNodeCount : getNodeCount
	setNodeCount : setNodeCount
	incrementNodeCount : incrementNodeCount
	getInventoryItems: getInventoryItems
	setInventoryItems: setInventoryItems
	generateItemID : generateItemID
	getItemIndex : getItemIndex
	getCustomIcons: getCustomIcons
	setCustomIcons: setCustomIcons
	getMaxDepth : getMaxDepth
	findAnswersWithTarget : findAnswersWithTarget
	updateAllAnswerLinks : updateAllAnswerLinks
	deleteItemReferencesFromAllNodes: deleteItemReferencesFromAllNodes
	findNode : findNode
	findAndAdd : findAndAdd
	findAndReplace : findAndReplace
	findAndAddInBetween : findAndAddInBetween
	findAndRemove : findAndRemove
	findAndFixAnswerTargets : findAndFixAnswerTargets
	getIdsFromSubtree : getIdsFromSubtree
	createQSetFromTree : createQSetFromTree
	createTreeDataFromQset : createTreeDataFromQset
	validateTreeOnStart : validateTreeOnStart
	validateTreeOnSave : validateTreeOnSave
	integerToLetters : integerToLetters
	generateAnswerHash : generateAnswerHash
]

# The service in charge of managing Action History, replacing the clunky "deleteAndRestoreSrv" service
# The history array contains entire snapshots of the tree, up to the limit determined by HISTORY_LIMIT
# action constants have no direct application currently, but are implemented for potential future features
# various user actions result in addToHistory being called to store the tree AFTER the action has been performed, with some contextual information
# note that the action history is not stored to the qset and is lost if the creator is reloaded or upon exit
Adventure.service "treeHistorySrv", ['treeSrv', '$rootScope', (treeSrv, $rootScope) ->

	HISTORY_LIMIT = 20

	history = []
	actions =
		WIDGET_INIT: "WIDGET_INIT"
		EXISTING_WIDGET_INIT: "EXISTING_WIDGET_INIT"
		NODE_RESET: "NODE_RESET"
		NODE_DELETED: "NODE_DELETED"
		NODE_ANSWER_REMOVED: "NODE_ANSWER_REMOVED"
		NODE_PARENT_REMOVED: "NODE_PARENT_REMOVED"
		NODE_REPLACED_WITH_EXISTING: "NODE_REPLACED_WITH_EXISTING"
		NODE_ADDED_IN_BETWEEN: "NODE_ADDED_IN_BETWEEN"
		NODE_EDITED: "NODE_EDITED"
		NODE_COPIED: "NODE_COPIED"
		NODE_CONVERTED : "NODE_CONVERTED"
		INVENTORY_EDITED: "INVENTORY_EDITED"

	getActions = () ->
		return actions

	getHistory = () ->
		return history

	getHistorySize = () ->
		return history.length

	createSnapshot = (tree, action, context) ->
		snapshot =
			action : action
			context: context ? context : ""
			timestamp : Date.now()
			tree: JSON.stringify treeSrv.createQSetFromTree tree # snapshots are converted into the equivalent Qset structure to remove unnecessary D3 info. Also reduces complexity for compareTrees below
			nodeCount : treeSrv.getNodeCount()

	addToHistory = (tree, action, context) ->
		snapshot = createSnapshot tree, action, context
		history.push snapshot

		if history.length > HISTORY_LIMIT
			history.splice 0, 1 # not using spliceHistory here to avoid broadcasting tree.history.removed
		$rootScope.$broadcast "tree.history.added"

	spliceHistory = (index, distance = 1) ->
		history.splice(index, distance)
		$rootScope.$broadcast "tree.history.removed"

	retrieveSnapshot = (index) ->
		return history[index]

	compareTrees = (source, diff) ->
		# SOURCE is a tree from a snapshot (string)
		# DIFF is the raw tree to be compared (must be converted to a Qset object and stringified before comparison)
		diff = JSON.stringify treeSrv.createQSetFromTree diff
		return source == diff

	

	getActions : getActions
	getHistory : getHistory
	getHistorySize : getHistorySize
	createSnapshot : createSnapshot
	addToHistory : addToHistory
	spliceHistory : spliceHistory
	retrieveSnapshot : retrieveSnapshot
	compareTrees : compareTrees
]
