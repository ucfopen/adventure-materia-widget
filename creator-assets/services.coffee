Adventure = angular.module "AdventureCreator"
Adventure.service "treeSrv", ($rootScope) ->

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


	get : get
	set : set
	getMaxDepth : getMaxDepth
	findNode : findNode
	findAndAdd : findAndAdd
	findAndAddInBetween : findAndAddInBetween
	findAndRemove : findAndRemove