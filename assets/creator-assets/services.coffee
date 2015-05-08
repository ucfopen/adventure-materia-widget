Adventure = angular.module "AdventureCreator"
Adventure.service "treeSrv", ($rootScope, $filter) ->

	# TreeData is being initialized in -two- places right now.
	# This one may or may not be required.
	# TODO: Find out if it's required.
	treeData =
		name: "Start"
		type: "blank"
		id: 0
		parentId: -1
		contents: []

	# Iterator that generates node IDs
	count = 1

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
	findAndAdd = (tree, parentId, node) ->

		if tree.id == parentId
			tree.contents.push node
			return tree

		if !tree.contents then return

		i = 0

		while i < tree.contents.length

			child = tree.contents[i]

			if child.id == parentId
				child.contents.push node
				return tree
			else
				findAndAdd tree.contents[i], parentId, node
				i++

		tree

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

			# First, find reference to childId in list of parent's children
			n = 0
			while n < tree.contents.length

				child = tree.contents[n]

				# Update the parent node's associated answer target with the new node ID
				if tree.answers[n].target is childId then tree.answers[n].target = node.id

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
	findAndRemove = (parent, id) ->

		if !parent.contents then return

		# iterator required instead of using angular.forEach
		i = 0

		while i < parent.contents.length

			child = parent.contents[i]

			if child.id == id

				# also remove parent's answer row corresponding to this node
				j = 0
				while j < parent.answers.length
					if parent.answers[j].target == id
						parent.answers.splice j, 1
						break
					else
						j++

				parent.contents.splice i, 1
			else
				findAndRemove parent.contents[i], id
				i++

		parent

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



	formatTreeDataForQset = (tree, items) ->

		if !tree.children or (($filter('filter')(items, {nodeId : tree.id}, true)).length is 0)

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
				answers: []

			question =
				text: if tree.question then tree.question else ""

			itemData.questions.push question

			if tree.media
				itemData.options.asset =
					materiaType: "asset"
					align: tree.media.align # replacement of "layout" parameter
					id: tree.media.id # URL likely needs conversion?
					type: tree.media.type # right now just "image", will be expanded upon in the future

			switch tree.type
				when "hotspot"
					itemData.options.visibility = tree.hotspotVisibility
				when "end"
					itemData.options.finalScore = tree.finalScore

			if tree.hasLinkToOther then itemData.options.hasLinkToOther = true
			if tree.hasLinkToSelf then itemData.options.hasLinkToSelf = true
			if tree.pendingTarget then itemData.options.pendingTarget = tree.pendingTarget
			# TODO should deletedCache be included in QSet?

			angular.forEach tree.answers, (answer, index) ->

				itemAnswerData =
					text: answer.text
					value: 0
					options:
						link: answer.target
						linkMode: answer.linkMode
						feedback: answer.feedback

				switch tree.type
					when "shortanswer"
						itemAnswerData.options.matches = answer.matches
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

		tree = {}

		if qset.options.nodeCount then setNodeCount qset.options.nodeCount

		angular.forEach qset.items, (item, index) ->

			node =
				id: item.options.id
				name: integerToLetters item.options.id
				parentId: item.options.parentId
				type: item.options.type
				contents: []

			if item.questions[0].text then node.question = item.questions[0].text

			if item.options.asset
				node.media =
					id: item.options.asset.id
					url: Materia.CreatorCore.getMediaUrl item.options.asset.id
					align: item.options.asset.align
					type: item.options.asset.type

			switch item.options.type
				when "hotspot"
					node.hotspotVisibility = item.options.visibility
				when "end"
					node.finalScore = item.options.finalScore

			if item.options.hasLinkToOther then node.hasLinkToOther = true
			if item.options.hasLinkToSelf then node.hasLinkToSelf = true
			if item.options.pendingTarget then node.pendingTarget = item.options.pendingTarget

			angular.forEach item.answers, (answer, index) ->

				unless node.answers then node.answers = []

				nodeAnswer =
					text: answer.text
					value: answer.value
					target: answer.options.link
					linkMode: answer.options.linkMode
					feedback: answer.options.feedback

				switch item.options.type
					when "shortanswer"
						nodeAnswer.matches = answer.options.matches
						if answer.options.isDefault then nodeAnswer.isDefault = true

					when "hotspot"
						nodeAnswer.svg = answer.options.svg

				node.answers.push nodeAnswer

			# Logic to append node to its intended position on the tree
			if node.parentId is -1 then tree = node
			else
				tree = findAndAdd tree, node.parentId, node

		tree

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

	get : get
	set : set
	getNodeCount : getNodeCount
	setNodeCount : setNodeCount
	incrementNodeCount : incrementNodeCount
	getMaxDepth : getMaxDepth
	findNode : findNode
	findAndAdd : findAndAdd
	findAndReplace : findAndReplace
	findAndAddInBetween : findAndAddInBetween
	findAndRemove : findAndRemove
	createQSetFromTree : createQSetFromTree
	createTreeDataFromQset : createTreeDataFromQset
	integerToLetters : integerToLetters