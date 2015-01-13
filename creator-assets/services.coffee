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

	get = ->
		treeData

	set = (data) ->
		treeData = data
		$rootScope.$broadcast "tree.nodes.changed"

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
				parent.children.splice i, 1
			else
				findAndRemove parent.children[i], id
				i++

		parent

	get : get
	set : set
	findNode : findNode
	findAndAdd : findAndAdd
	findAndRemove : findAndRemove