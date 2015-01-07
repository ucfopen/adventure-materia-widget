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

	set = (data) ->
		treeData = data
		$rootScope.$broadcast "tree.nodes.changed"

	# Probably unnecessary
	get = ->
		treeData

	set : set
	get : get