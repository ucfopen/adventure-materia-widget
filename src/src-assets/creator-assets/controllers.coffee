angular.module "Adventure"
.controller "AdventureCtrl", ['$scope', '$filter', '$compile', '$rootScope', '$timeout', '$sce', '$sanitize', 'treeSrv', 'treeHistorySrv', 'legacyQsetSrv',($scope, $filter, $compile, $rootScope, $timeout, $sce, $sanitize, treeSrv, treeHistorySrv, legacyQsetSrv) ->
	materiaCallbacks = {}

	# Define constants for node screen types
	$scope.BLANK = "blank"
	$scope.MC = "mc"
	$scope.SHORTANS = "shortanswer"
	$scope.HOTSPOT = "hotspot"
	$scope.NARR = "narrative"
	$scope.END = "end"
	$scope.LINK = "link" # Probably not required

	# Define constants for the link mode types
	$scope.NEW = "new"
	$scope.EXISTING = "existing"
	$scope.SELF = "self"

	$scope.NORMAL = "Normal"
	$scope.NONSCORING = "Non-Scoring"

	$scope.scoreMode = $scope.NORMAL
	$scope.internalScoreMessage = ""
	$scope.showImportTypeSelection = false
	$scope.showImage = true
	$scope.urlError = '　'

	# Characters that need to be pre-sanitize before being run through angular's $sanitize directive
	PRESANITIZE_CHARACTERS =
		'>' : '&gt;',
		'<' : '&lt;'

	$scope.title = ""

	$scope.hidePlayerTitle = false

	$scope.startID = 0

	# NodeTools is an object that holds the parameters for the nodeTools modal, works in tandem with the nodeToolsDialog directive
	$scope.nodeTools =
		show: false
		target: null
		type: null
		x: 0
		y: 0
		showResetWarning: false
		showDeleteWarning: false
		showConvertDialog: false

	# newNodeManager works like nodeTools, holds parameters of the newNodeManager modal and works w/ the directive
	$scope.newNodeManager =
		show: false
		target: null
		answerId: null # alphanumeric hash to identify the exact answer (target can be non-unique)
		x: 0
		y: 0
		linkMode: "new" # options should be "new" | "existing" | "self"

	# Parameters for the answer deletion confirmation dialog
	$scope.deleteDialog =
		show: false
		target: null
		targetIndex: null
		x: 0
		y: 0

	$scope.existingNodeSelectionMode = false
	$scope.existingNodeSelected = null

	$scope.copyNodeMode = false
	$scope.copyNodeTarget = null

	$scope.previewNodeSelectionMode = false
	$scope.previewNodeSelected = null

	# This instantiation of treeData is required. It populates the "Start" node.
	$scope.treeData =
		name: "Start"
		type: "blank"
		id: 0
		parentId: -1
		contents: []

	# Since the entire tree SVG can be dragged around, we need to track the X & Y offsets representing where the SVG is positioned relative to "normal"
	# These offsets are applied to modals that depend on item locations within the SVG, e.g., the nodeTools dialog and answer-tooltips
	# This object is passed thru to the draggableTree directive when it's added to the tree-svg container that D3 generates
	$scope.treeOffset =
		x: 0
		y: 0
		moving: false
		scale: 1
		scaleXOffset: 0
		scaleYOffset: 0

	# The displayNodeCreation flag controls the visiblity of node creation screens
	$scope.displayNodeCreation = "none"
	# Scope reference for the node currently being edited in a creation screen, updates when displayNodeCreation changes
	$scope.editedNode = null

	$scope.showCustomNodeLabelEditor = false

	$scope.hoveredNode =
		showTooltips: false
		target: null
		tooltips: [] # initially an empty array that's populated on-hover with the target's answerLinks array
		x: 0
		y: 0
		pendingHide: false

	$scope.hoveredLock =
		showItems: false
		target: null
		requiredItems: [] # initially an empty array that's populated on-hover with the answer's required items array
		x: 0
		y: 0
		pendingHide: false
		answerText: ''
		hideAnswer: false

	$scope.validation =
		show: false
		errors: []

	historyActions = treeHistorySrv.getActions()

	# Gets index of item in inventory
	$scope.getItemIndex = (item) ->
		if (item)
			return treeSrv.getItemIndex(item.id)

	$scope.$watch "showBackgroundCover", (newVal, oldVal) ->
		if newVal == true
			hideElements = document.getElementsByClassName("inert-on-dialog")
			for element in hideElements
				element.setAttribute("inert", "true")
		else
			hideElements = document.getElementsByClassName("inert-on-dialog")
			for element in hideElements
				element.removeAttribute("inert")

	$scope.$watch "displayNodeCreation", (newVal, oldVal) ->

		# Returning from a suspended node creation screen, don't do anything
		if oldVal is "suspended" then return

		if newVal isnt oldVal and newVal isnt "none" and newVal isnt "suspended"
			$scope.editedNode = treeSrv.findNode $scope.treeData, $scope.nodeTools.target

			if newVal is $scope.END and $scope.editedNode.pendingTarget
				$scope.toast "Can't make an End Point! Move or remove child destinations first."
				$scope.displayNodeCreation = "none"
				return

			$scope.showCreationDialog = false
			if $scope.editedNode.type is $scope.BLANK then $scope.editedNode.type = $scope.displayNodeCreation

			# Inform the edit screens that the edited node has changed
			$rootScope.$broadcast "editedNode.target.changed"
		else if newVal is "suspended"
			$scope.newNodeManager.show = false
		else if newVal is "none"
			$scope.newNodeManager.show = false
			$scope.newNodeManager.target = null

			# start a timer that makes toasts obsolete after 5 seconds
			if $scope.showToast
				if $scope.toastRegister isnt null then $timeout.cancel $scope.toastRegister
				$scope.toastRegister = $timeout (() ->
					$scope.hideToast()
				), 5000

			# If node had a problem, assume user has addressed it and remove the hasProblems flag
			if $scope.editedNode and $scope.editedNode.hasProblem then delete $scope.editedNode.hasProblem

			# Refresh all answerLinks references as some have changed
			treeSrv.updateAllAnswerLinks $scope.treeData

			# Warn the user if a final score hasn't been set upon closing the creation screen
			# TODO there may be more post-creation-exit events required: condense these?
			if $scope.editedNode and $scope.editedNode.type is $scope.END
				if $scope.editedNode.finalScore is null
					$scope.toast "End Point " + $scope.editedNode.name + " is missing a valid final score!"
					$scope.editedNode.hasProblem = true

			# Run the question text through $sanitize to see if it contains invalid HTML
			# If so, warn the user
			if $scope.editedNode and $scope.editedNode.question
				try
					# Run question text thru pre-sanitize routine because $sanitize is fickle about certain characters like >, <
					presanitized = $scope.editedNode.question
					for k, v of PRESANITIZE_CHARACTERS
						presanitized = presanitized.replace k, v

					$sanitize presanitized
				catch e
					$scope.toast "WARNING! " + $scope.editedNode.name + "'s question contains malformed or dangerous HTML!"
					$scope.editedNode.hasProblem = true

			# Handy debugging statement here; keep it commented out unless necessary for testing
			# console.log $scope.editedNode

			# Redraw tree (again) to address any post-edit changes
			treeSrv.set $scope.treeData

			# prevents polluting the action history by comparing the current tree to to the latest snapshot
			# only add the current tree as a snapshot if the tree was actually edited
			if $scope.editedNode
				lastIndex = treeHistorySrv.getHistorySize() - 1
				if lastIndex is -1 then treeHistorySrv.addToHistory $scope.treeData, historyActions.NODE_EDITED, "Destination " + $scope.integerToLetters($scope.editedNode.id) + " edited"
				else
					peek = treeHistorySrv.retrieveSnapshot(lastIndex)
					unless treeHistorySrv.compareTrees(peek.tree, $scope.treeData) then treeHistorySrv.addToHistory $scope.treeData, historyActions.NODE_EDITED, "Destination " + $scope.integerToLetters($scope.editedNode.id) + " edited"


	$scope.hideCoverAndModals = ->
		$scope.showIntroDialog = false
		$scope.showBackgroundCover = false
		$scope.showInventoryBackgroundCover = false
		$scope.nodeTools.show = false
		$scope.showCreationDialog = false
		$scope.showDeleteWarning = false
		$scope.showTitleEditor = false
		$scope.validation.show = false
		$scope.showScoreModeDialog = false
		$scope.showImportTypeSelection = false
		$scope.showItemSelection = false
		$scope.toggleRequiredItemsModal(null)
		$scope.showItemManager = false
		$scope.showItemIconSelector = false
		$scope.editingIcons = false
		$scope.showQuestionRequiredItems = false
		$scope.showQuestions = false
		$scope.showCustomNodeLabelEditor = false

		$scope.resetNewNodeManager()

		$scope.displayNodeCreation = "none"

	$scope.initIcons = (customIcons = null) ->
		$scope.icons = icons = [{name:"9VBattery64.png",url:"assets/icons/9VBattery64.png"},{name:"AABattery64.png",url:"assets/icons/AABattery64.png"},{name:"Acorn64.png",url:"assets/icons/Acorn64.png"},{name:"Ant64.png",url:"assets/icons/Ant64.png"},{name:"Apple64.png",url:"assets/icons/Apple64.png"},{name:"BackPack64.png",url:"assets/icons/BackPack64.png"},{name:"Bamboo64.png",url:"assets/icons/Bamboo64.png"},{name:"Basketball64.png",url:"assets/icons/Basketball64.png"},{name:"Bass64.png",url:"assets/icons/Bass64.png"},{name:"Beaker64.png",url:"assets/icons/Beaker64.png"},{name:"BeakerTall64.png",url:"assets/icons/BeakerTall64.png"},{name:"Bee64.png",url:"assets/icons/Bee64.png"},{name:"Beetle64.png",url:"assets/icons/Beetle64.png"},{name:"Bird64.png",url:"assets/icons/Bird64.png"},{name:"Blueberries64.png",url:"assets/icons/Blueberries64.png"},{name:"Bone64.png",url:"assets/icons/Bone64.png"},{name:"Bottle64.png",url:"assets/icons/Bottle64.png"},{name:"BoxOfCards64.png",url:"assets/icons/BoxOfCards64.png"},{name:"BundleOfPlants64.png",url:"assets/icons/BundleOfPlants64.png"},{name:"CD64.png",url:"assets/icons/CD64.png"},{name:"CDCase64.png",url:"assets/icons/CDCase64.png"},{name:"Calculator64.png",url:"assets/icons/Calculator64.png"},{name:"Camera64.png",url:"assets/icons/Camera64.png"},{name:"Candy64.png",url:"assets/icons/Candy64.png"},{name:"CandyCane64.png",url:"assets/icons/CandyCane64.png"},{name:"Card64.png",url:"assets/icons/Card64.png"},{name:"CardboardBox64.png",url:"assets/icons/CardboardBox64.png"},{name:"Carrot64.png",url:"assets/icons/Carrot64.png"},{name:"Cat64.png",url:"assets/icons/Cat64.png"},{name:"Cheese64.png",url:"assets/icons/Cheese64.png"},{name:"Chick64.png",url:"assets/icons/Chick64.png"},{name:"Chicken64.png",url:"assets/icons/Chicken64.png"},{name:"Circle64.png",url:"assets/icons/Circle64.png"},{name:"Coffee64.png",url:"assets/icons/Coffee64.png"},{name:"Coin64.png",url:"assets/icons/Coin64.png"},{name:"Compass64.png",url:"assets/icons/Compass64.png"},{name:"Console64.png",url:"assets/icons/Console64.png"},{name:"Crystals64.png",url:"assets/icons/Crystals64.png"},{name:"DVDCase64.png",url:"assets/icons/DVDCase64.png"},{name:"DeckOfCards64.png",url:"assets/icons/DeckOfCards64.png"},{name:"Dog64.png",url:"assets/icons/Dog64.png"},{name:"Dropper64.png",url:"assets/icons/Dropper64.png"},{name:"Duck64.png",url:"assets/icons/Duck64.png"},{name:"Egg64.png",url:"assets/icons/Egg64.png"},{name:"Envelope64.png",url:"assets/icons/Envelope64.png"},{name:"Feather64.png",url:"assets/icons/Feather64.png"},{name:"Fern64.png",url:"assets/icons/Fern64.png"},{name:"Fire64.png",url:"assets/icons/Fire64.png"},{name:"Fish64.png",url:"assets/icons/Fish64.png"},{name:"Flask64.png",url:"assets/icons/Flask64.png"},{name:"Flower64.png",url:"assets/icons/Flower64.png"},{name:"Frog64.png",url:"assets/icons/Frog64.png"},{name:"FullCrate64.png",url:"assets/icons/FullCrate64.png"},{name:"Funnel64.png",url:"assets/icons/Funnel64.png"},{name:"Globe64.png",url:"assets/icons/Globe64.png"},{name:"Gloves64.png",url:"assets/icons/Gloves64.png"},{name:"Goggles64.png",url:"assets/icons/Goggles64.png"},{name:"Guitar64.png",url:"assets/icons/Guitar64.png"},{name:"Hammer64.png",url:"assets/icons/Hammer64.png"},{name:"HandOfCards64.png",url:"assets/icons/HandOfCards64.png"},{name:"Hat64.png",url:"assets/icons/Hat64.png"},{name:"Heart64.png",url:"assets/icons/Heart64.png"},{name:"Hoodie64.png",url:"assets/icons/Hoodie64.png"},{name:"Hotdog64.png",url:"assets/icons/Hotdog64.png"},{name:"IceCream64.png",url:"assets/icons/IceCream64.png"},{name:"Jar64.png",url:"assets/icons/Jar64.png"},{name:"Keys64.png",url:"assets/icons/Keys64.png"},{name:"Leaf64.png",url:"assets/icons/Leaf64.png"},{name:"Lighter64.png",url:"assets/icons/Lighter64.png"},{name:"Lightning64.png",url:"assets/icons/Lightning64.png"},{name:"Lipstick64.png",url:"assets/icons/Lipstick64.png"},{name:"Magnet64.png",url:"assets/icons/Magnet64.png"},{name:"MagnifyingGlass64.png",url:"assets/icons/MagnifyingGlass64.png"},{name:"ManilaFolder64.png",url:"assets/icons/ManilaFolder64.png"},{name:"Map64.png",url:"assets/icons/Map64.png"},{name:"MapleLeaf64.png",url:"assets/icons/MapleLeaf64.png"},{name:"Match64.png",url:"assets/icons/Match64.png"},{name:"Matchbook64.png",url:"assets/icons/Matchbook64.png"},{name:"Money64.png",url:"assets/icons/Money64.png"},{name:"MortarAndPestle64.png",url:"assets/icons/MortarAndPestle64.png"},{name:"Moth64.png",url:"assets/icons/Moth64.png"},{name:"MushroomBrown64.png",url:"assets/icons/MushroomBrown64.png"},{name:"MushroomRed64.png",url:"assets/icons/MushroomRed64.png"},{name:"OldKey64.png",url:"assets/icons/OldKey64.png"},{name:"Orange64.png",url:"assets/icons/Orange64.png"},{name:"Oval64.png",url:"assets/icons/Oval64.png"},{name:"PaintingLandscape64.png",url:"assets/icons/PaintingLandscape64.png"},{name:"PaintingPortrait64.png",url:"assets/icons/PaintingPortrait64.png"},{name:"Pamphlet64.png",url:"assets/icons/Pamphlet64.png"},{name:"Pants64.png",url:"assets/icons/Pants64.png"},{name:"PaperBag64.png",url:"assets/icons/PaperBag64.png"},{name:"Papers64.png",url:"assets/icons/Papers64.png"},{name:"Pencil64.png",url:"assets/icons/Pencil64.png"},{name:"Pentagon64.png",url:"assets/icons/Pentagon64.png"},{name:"Pepper64.png",url:"assets/icons/Pepper64.png"},{name:"PetriDish64.png",url:"assets/icons/PetriDish64.png"},{name:"Phone64.png",url:"assets/icons/Phone64.png"},{name:"Photo64.png",url:"assets/icons/Photo64.png"},{name:"PickleJar64.png",url:"assets/icons/PickleJar64.png"},{name:"Pie64.png",url:"assets/icons/Pie64.png"},{name:"Pills64.png",url:"assets/icons/Pills64.png"},{name:"Pipet64.png",url:"assets/icons/Pipet64.png"},{name:"Pizza64.png",url:"assets/icons/Pizza64.png"},{name:"Poster64.png",url:"assets/icons/Poster64.png"},{name:"Potion64.png",url:"assets/icons/Potion64.png"},{name:"Powder64.png",url:"assets/icons/Powder64.png"},{name:"PrecisionKnife64.png",url:"assets/icons/PrecisionKnife64.png"},{name:"Pumpkin64.png",url:"assets/icons/Pumpkin64.png"},{name:"Purse64.png",url:"assets/icons/Purse64.png"},{name:"Rabbit64.png",url:"assets/icons/Rabbit64.png"},{name:"Rat64.png",url:"assets/icons/Rat64.png"},{name:"Rectangle64.png",url:"assets/icons/Rectangle64.png"},{name:"RedBerries64.png",url:"assets/icons/RedBerries64.png"},{name:"Rhombus64.png",url:"assets/icons/Rhombus64.png"},{name:"Rope64.png",url:"assets/icons/Rope64.png"},{name:"Rose64.png",url:"assets/icons/Rose64.png"},{name:"RulerIcon64.png",url:"assets/icons/RulerIcon64.png"},{name:"Sandwich64.png",url:"assets/icons/Sandwich64.png"},{name:"SciFiDevice64.png",url:"assets/icons/SciFiDevice64.png"},{name:"Scissors64.png",url:"assets/icons/Scissors64.png"},{name:"Screwdriver64.png",url:"assets/icons/Screwdriver64.png"},{name:"Scroll1-64.png",url:"assets/icons/Scroll1-64.png"},{name:"Scroll2-64.png",url:"assets/icons/Scroll2-64.png"},{name:"Scroll3-64.png",url:"assets/icons/Scroll3-64.png"},{name:"Seedling64.png",url:"assets/icons/Seedling64.png"},{name:"Seeds64.png",url:"assets/icons/Seeds64.png"},{name:"Shirt64.png",url:"assets/icons/Shirt64.png"},{name:"Skirt64.png",url:"assets/icons/Skirt64.png"},{name:"SmallWoodBox64.png",url:"assets/icons/SmallWoodBox64.png"},{name:"Snowflake64.png",url:"assets/icons/Snowflake64.png"},{name:"Socks64.png",url:"assets/icons/Socks64.png"},{name:"Sparkles64.png",url:"assets/icons/Sparkles64.png"},{name:"Square64.png",url:"assets/icons/Square64.png"},{name:"Star64.png",url:"assets/icons/Star64.png"},{name:"Stick64.png",url:"assets/icons/Stick64.png"},{name:"Stopwatch64.png",url:"assets/icons/Stopwatch64.png"},{name:"Sunflower64.png",url:"assets/icons/Sunflower64.png"},{name:"Swirl64.png",url:"assets/icons/Swirl64.png"},{name:"Sword64.png",url:"assets/icons/Sword64.png"},{name:"Tablet64.png",url:"assets/icons/Tablet64.png"},{name:"Tape64.png",url:"assets/icons/Tape64.png"},{name:"TestTube64.png",url:"assets/icons/TestTube64.png"},{name:"Textbook64.png",url:"assets/icons/Textbook64.png"},{name:"Thermometer64.png",url:"assets/icons/Thermometer64.png"},{name:"Tome64.png",url:"assets/icons/Tome64.png"},{name:"TradingCards64.png",url:"assets/icons/TradingCards64.png"},{name:"Trapezoid64.png",url:"assets/icons/Trapezoid64.png"},{name:"TreasureMap64.png",url:"assets/icons/TreasureMap64.png"},{name:"Triangle64.png",url:"assets/icons/Triangle64.png"},{name:"Tweezers64.png",url:"assets/icons/Tweezers64.png"},{name:"Vest64.png",url:"assets/icons/Vest64.png"},{name:"WoodBox64.png",url:"assets/icons/WoodBox64.png"},{name:"WorldAtlas64.png",url:"assets/icons/WorldAtlas64.png"},{name:"Wrench64.png",url:"assets/icons/Wrench64.png"}]
		# Initialize the user's uploaded icons
		if customIcons
			for custom_icon in customIcons
				$scope.icons.push(custom_icon)

	materiaCallbacks.initNewWidget = (widget, baseUrl) ->
		$scope.$apply ->
			$scope.title = "My Adventure Widget"

			$scope.showIntroDialog = true
			$scope.showBackgroundCover = true

			$scope.initIcons()

			# Add default items?
			$scope.inventoryItems = []

			treeHistorySrv.addToHistory $scope.treeData, historyActions.WIDGET_INIT, "Widget Initialized"

	materiaCallbacks.initExistingWidget = (title,widget,qset,version,baseUrl) ->
		showIntroDialog = false

		if qset
			# Convert the old qset prior to using it
			if parseInt(version) is 1 then qset = JSON.parse legacyQsetSrv.convertOldQset qset

			$scope.$apply () ->
				$scope.title = title
				$scope.treeData = treeSrv.createTreeDataFromQset qset

				if qset.options.hidePlayerTitle then $scope.hidePlayerTitle = qset.options.hidePlayerTitle

				treeSrv.setInventoryItems qset.options.inventoryItems || []

				$scope.inventoryItems = qset.options.inventoryItems || []

				treeSrv.setCustomIcons qset.options.customIcons || []

				$scope.initIcons(qset.options.customIcons)

				# Optional qset parameters based on score mode
				if qset.options.scoreMode then $scope.scoreMode = qset.options.scoreMode
				if qset.options.internalScoreMessage then $scope.internalScoreMessage = qset.options.internalScoreMessage

				# Check to make sure the tree doesn't have errors
				validation = treeSrv.validateTreeOnStart $scope.treeData
				if validation.length
					$scope.validation.errors = validation
					$rootScope.$broadcast "validation.error"

				treeSrv.set $scope.treeData
				treeSrv.updateAllAnswerLinks $scope.treeData

				treeHistorySrv.addToHistory $scope.treeData, historyActions.EXISTING_WIDGET_INIT, "Existing Widget Initialized"

	materiaCallbacks.onSaveClicked = (mode = 'save') ->
		if mode is "publish"
			# Check for errors
			validation = treeSrv.validateTreeOnSave $scope.treeData

			# Check if there are any unreachable destinations if the inventory system is enabled
			if ($scope.inventoryItems.length > 0)
				visitedNodes = new Map()
				unvisitedNodes = new Map()
				inventory = new Map()
				unreachableDestinations = treeSrv.findUnreachableDestinations $scope.treeData, $scope.treeData, visitedNodes, unvisitedNodes, inventory
				if (unreachableDestinations.size > 0)
					# Get all nodes that are not in reachableDestinations
					# create error at each node that is not in reachableDestinations
					$scope.validation.errors = []
					unreachableDestinations = Array.from(unreachableDestinations.values())

					for node in unreachableDestinations
						nodeId = if node.options then node.options.id or node.id else node.id
						if (node.parentId == -1)
							# start node id is 0
							nodeId = 0
						$scope.validation.errors.push({
							type: "unreachable_destination",
							node: nodeId,
							message: "Destination " + treeSrv.integerToLetters(nodeId) + " is unreachable!"
						})
						$rootScope.$broadcast "validation.error"
					return Materia.CreatorCore.cancelSave ''

		else validation = []

		# Run the tree validation when save is clicked
		# If errors are found, halt the save and bring up the validation dialog
		if validation.length
			$scope.validation.errors = validation
			$rootScope.$broadcast "validation.error"

			return Materia.CreatorCore.cancelSave ''
		else
			qset = treeSrv.createQSetFromTree $scope.treeData

			qset.options.hidePlayerTitle = $scope.hidePlayerTitle
			qset.options.startID = $scope.startID
			qset.options.scoreMode = $scope.scoreMode
			qset.options.internalScoreMessage = $scope.internalScoreMessage
			qset.options.inventoryItems = treeSrv.getInventoryItems()
			qset.options.customIcons = treeSrv.getCustomIcons()
			Materia.CreatorCore.save $scope.title, qset, 2

	materiaCallbacks.onSaveComplete = (title, widget, qset, version) -> true

	# onMediaImportComplete is required by the creator core
	# if editing a node, tie the media to that node
	# if editing icons, add the media to icons
	materiaCallbacks.onMediaImportComplete = (media) ->
		if $scope.editingIcons and $scope.currentItem
			newIcon =
				is_custom: true
				type: "image"
				url: Materia.CreatorCore.getMediaUrl media[0].id
				id: media[0].id
				alt: ""
			$scope.inventoryItems[$scope.inventoryItems.indexOf($scope.currentItem)].icon = newIcon
			$scope.icons.push(newIcon)
			treeSrv.setCustomIcons [
				...treeSrv.getCustomIcons(),
				newIcon
			]

			# Scroll to uploaded icon
			icons_list = document.querySelector('.icons-list')
			icons_list.scrollTop = icons_list.scrollHeight

			$scope.$apply()

		else if $scope.editedNode
			$scope.editedNode.media =
				type: "image"
				url: Materia.CreatorCore.getMediaUrl media[0].id
				id: media[0].id
				align: "right"
				alt: ""

			$scope.mediaReady = true
			$scope.showImage = true;

			$rootScope.$broadcast "editedNode.media.updated"


	# handles hover behavior of associated tooltips
	# (associated answer & validation warnings)
	$scope.onNodeHover = (data) ->
		# Required item tooltip
		if data.type is "lock"
			$scope.hoveredLock.pendingHide = false
			if $scope.hoveredLock.target isnt data.id
				$scope.$apply () ->
					$scope.hoveredLock.x = data.x
					$scope.hoveredLock.y = data.y
					$scope.hoveredLock.target = data.id
					$scope.hoveredLock.requiredItems = data.requiredItems
					# set required item range text
					for item in $scope.hoveredLock.requiredItems
						if item.uncappedMax
							item.range = item.minCount
						else
							item.range = item.minCount + " to " + item.maxCount
					$scope.hoveredLock.answerText = data.answerText
					$scope.hoveredLock.hideAnswer = data.hideAnswer
			return
		if data.type is "bridge" then return
		if $scope.existingNodeSelectionMode is true then return
		$scope.hoveredNode.pendingHide = false

		# Node tooltip
		if $scope.hoveredNode.target isnt data.id
			$scope.$apply () ->
				$scope.hoveredNode.x = data.x
				$scope.hoveredNode.y = data.y
				$scope.hoveredNode.target = data.id

	# Handles hover-out behavior of associated tooltips
	# Because hoverout can trigger quite often while mousing over node's dom elements, each time a hoverout happens, a pending flag is set
	# if the flag is reset by another hover event happening, don't hide the tooltip (cursor is still traveling over the node)
	# If it's not reset, go ahead and hide the tooltip
	$scope.onNodeHoverOut = (data) ->
		# Required item tooltip
		if data.type is "lock"
			if $scope.hoveredLock.target is data.id
				if $scope.hoveredLock.showItems is true
					$scope.hoveredLock.pendingHide = true
					$timeout (() ->
						if $scope.hoveredLock.pendingHide is true
							$scope.$apply () ->
								$scope.hoveredLock.showItems = false
								$scope.hoveredLock.target = null
					), 500
			else if $scope.hoveredLock.target isnt data.id
				$scope.hoveredLock.showItems = false
			return

		if data.type is "bridge" then return
		if $scope.existingNodeSelectionMode is true then return

		# Node tooltip
		if $scope.hoveredNode.target is data.id
			if $scope.hoveredNode.showTooltips is true
				$scope.hoveredNode.pendingHide = true
				$timeout (() ->
					if $scope.hoveredNode.pendingHide is true
						$scope.$apply () ->
							$scope.hoveredNode.showTooltips = false
							$scope.hoveredNode.target = null
				), 500
		else if $scope.hoveredNode.target isnt data.id
			$scope.hoveredNode.showTooltips = false

	# Controller recipient of the treeViz directive's onClick method
	# data contains the node object
	$scope.nodeSelected = (data) ->

		# If a bridge is clicked, automagically add a node to replace the bridge
		# Creates a node between the bridge link's parent and child
		if data.type is "bridge"
			$scope.addNodeInBetween data
			return

		# If we're in existingNodeSelectionMode, we need to listen for an existing node to be
		# selected to update an answer's target.
		if $scope.existingNodeSelectionMode
			$scope.$apply () ->
				$scope.existingNodeSelected = data
				$scope.existingNodeSelectionMode = false

		# Otherwise, if we're in copyNodeMode, the selected target is considered the copyNodeTarget
		# Kicks off the listener to complete the node copy mode
		else if $scope.copyNodeMode
			$scope.$apply () ->
				$scope.copyNodeTarget = data
				$scope.copyNodeMode = false

		else if $scope.previewNodeSelectionMode
			$scope.$apply () ->
				$scope.previewNodeSelected = data
				$scope.previewNodeSelectionMode = false

		else # Default selection behavior
			$scope.$apply () ->
				$scope.nodeTools.show = !$scope.nodeTools.show
				$scope.nodeTools.x = data.x
				$scope.nodeTools.y = data.y
				$scope.nodeTools.type = data.type
				# nodeTools refresh triggered by change in target property (see nodeToolsDialog directive)
				if $scope.nodeTools.show is false then $scope.nodeTools.target = null else $scope.nodeTools.target = data.id

				$scope.nodeTools.showResetWarning = false
				$scope.nodeTools.showDeleteWarning = false

	# Handles clicks in the negative space of the treeViz svg
	# Used to close the nodeTools popup, or whatever else is needed
	$scope.bgClicked = ->
		$scope.$apply () ->
			$scope.nodeTools.show = false

	# Function that pre-assembles a new node's data, adds it, then kicks off processes that have to happen afterwards
	# TODO this ought to be moved to treeSrv
	$scope.addNode = (parent, type) ->

		newId = treeSrv.getNodeCount()
		treeSrv.incrementNodeCount()
		newName = treeSrv.integerToLetters newId

		newNode =
			name: "#{newName}" # name: "Node #{count} (#{type})"
			id: newId
			parentId: parent
			type: type
			contents: []
			items: []

		treeSrv.findAndAdd $scope.treeData, parent, newNode

		treeSrv.set $scope.treeData

		$scope.nodeTools.show = false
		$scope.nodeTools.target = null # forces nodeTools to refresh target data to account for change in parent Y

		# Sometimes getting the id of the newly created node is required, so return it
		newId

	# Function that explicitly adds a node between an existing parent and child
	$scope.addNodeInBetween = (data) ->

		newId = treeSrv.getNodeCount()
		newName = treeSrv.integerToLetters newId

		newNode =
			name: "#{newName}" # name: "Node #{count} (#{type})"
			id: newId
			parentId: data.source
			type: $scope.BLANK
			contents: []
			pendingTarget: data.target
			items: []

		if data.specialCase
			if data.specialCase is "otherNode"
				newNode.hasLinkToOther = true

		treeSrv.findAndAddInBetween $scope.treeData, data.source, data.target, newNode

		treeSrv.incrementNodeCount()
		treeSrv.set $scope.treeData

		treeSrv.updateAllAnswerLinks $scope.treeData

		treeHistorySrv.addToHistory $scope.treeData, historyActions.NODE_ADDED_IN_BETWEEN, "Destination created between " + treeSrv.integerToLetters(data.source) + " and " + treeSrv.integerToLetters(data.target)


	# Reference function so the integerToLetters function from treeSrv can be called using two-way data binding
	$scope.integerToLetters = (val) ->
		return treeSrv.integerToLetters(val)

	$scope.generateDebugQset = ->
		qset = treeSrv.createQSetFromTree $scope.treeData
		qset.options.hidePlayerTitle = $scope.hidePlayerTitle
		qset.options.startID = $scope.startID
		qset.options.scoreMode = $scope.scoreMode
		qset.options.internalScoreMessage = $scope.internalScoreMessage
		qset.options.inventoryItems = treeSrv.getInventoryItems()
		qset.options.customIcons = treeSrv.getCustomIcons()

		$scope.showQsetGenerator = true
		$scope.generatedQset = JSON.stringify qset, null, 2


	# Start 'er up!
	Materia.CreatorCore.start materiaCallbacks

]