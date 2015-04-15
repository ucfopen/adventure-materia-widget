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

	# Self explanatory getter function
	get = ->
		treeData

	# Updating the tree prompts a redraw of the D3 visualization
	set = (data) ->
		treeData = data
		$rootScope.$broadcast "tree.nodes.changed"

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

		if !tree.children then return null

		# iterator required instead of using angular.forEach
		i = 0

		while i < tree.children.length

			child = tree.children[i]

			if child.id == id
				return child
			else
				node =  findNode tree.children[i], id
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
			tree

		if !tree.children then return

		i = 0

		while i < tree.children.length

			child = tree.children[i]

			if child.id == parentId
				child.contents.push node
				return
			else
				findAndAdd tree.children[i], parentId, node
				i++

		tree

	# Recursive function for adding a node in between a given parent and child, essentially splitting an existing link
	# tree: the tree structure to be iterated. Should initially reference the root node (treeData object)
	# parentId: the ID of the parent node that serves as the source of the existing link
	# childId: the ID of the child node that serves as the target of the existing link
	# node: the node to be added between the parent and child
	findAndAddInBetween = (tree, parentId, childId, node) ->

		if tree.id == parentId

			# First, find reference to childId in list of parent's children
			n = 0
			while n < tree.children.length

				child = tree.children[n]

				# Update the parent node's associated answer target with the new node ID
				if tree.answers[n].target is childId then tree.answers[n].target = node.id

				if child.id == childId # reference to childId found

					# Set new node's child to the child node
					node.children = [child]
					node.contents = [child]

					# Replace tree's existing child with new node
					tree.children[n] = node

					tree # return the revised tree
				else
					n++ # No recursion, since the childId node has to be a direct child of the parentId node

		if ! tree.children then return

		i = 0

		while i < tree.children.length
			findAndAddInBetween tree.children[i], parentId, childId, node
			i++

		tree

	# Recursive function for finding a node and removing it
	# parent: the tree structure to be iterated. Should initially reference the root node (treeData object)
	# id: the id the node to be removed
	findAndRemove = (parent, id) ->

		if !parent.children then return

		# iterator required instead of using angular.forEach
		i = 0

		while i < parent.children.length

			child = parent.children[i]

			if child.id == id

				# also remove parent's answer row corresponding to this node
				j = 0
				while j < parent.answers.length
					if parent.answers[j].target == id
						parent.answers.splice j, 1
						break
					else
						j++

				parent.children.splice i, 1
			else
				findAndRemove parent.children[i], id
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

	generateQSetFromTree = (tree) ->

		qset =
			version: "2.0.1"
			data:
				items: formatTreeDataForQset tree, []
				options: {}


	formatTreeDataForQset = (tree, items) ->

		if !tree.children or (($filter('filter')(items, {nodeId : tree.id}, true)).length is 0)

			itemData =
				materiaType: "question"
				id: null
				nodeId: tree.id # duplicate of options.id, needed for $filter query
				question: if tree.question then tree.question else ""
				options:
					id: tree.id
					type: tree.type
				answers: []

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

			#if tree.type is "hotspot" then itemData.options.visibility = answer.hotspotVisibility

			itemAnswerData = {}

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



	get : get
	set : set
	getMaxDepth : getMaxDepth
	findNode : findNode
	findAndAdd : findAndAdd
	findAndAddInBetween : findAndAddInBetween
	findAndRemove : findAndRemove
	generateQSetFromTree : generateQSetFromTree