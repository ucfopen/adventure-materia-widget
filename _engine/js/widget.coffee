Namespace('Adventure').Engine = do ->
	_qset = null
	_base_url = null
	LAYOUT_IMAGE_ONLY = 0	# Layout that contains only an image
	LAYOUT_TEXT_ONLY = 1 	# Layout that contains only text
	LAYOUT_HORIZ_TEXT = 2 	# Horizontal layout that contains text and then an image
	LAYOUT_HORIZ_IMAGE = 3 	# Horizontal layout that contains an image and then text
	LAYOUT_VERT_TEXT = 4 	# Vertical layout that contains text and then an image
	LAYOUT_VERT_IMAGE = 5 	# Vertical layout that contains an image and then text

	# Called by Materia.Engine when your widget Engine should start the user experience.
	start = (instance, qset, version = '1') ->
		_qset = qset
		_base_url = instance.base_url
		_init(instance.name)

	_init = (title) ->
		# document.oncontextmenu = -> false                  # Disables right click.
		# document.addEventListener 'mousedown', (e) ->
		# 	if e.button is 2 then false else true          # Disables right click.

		screen = $('#overview-screen-template').html()

		data =
			title : title

		$('#overview-screen').html(_.template(screen, data))

		_manageQuestionScreen(_qset.items[0].items[0])

	_manageQuestionScreen = (q_data) ->

		switch q_data.options.type
			when -1 then _end()
			when 1, 5 then _handleTransitional(q_data)
			when 2 then _handleMultipleChoice(q_data)
			when 3 then _handleHotspot(q_data)
			when 4 then _handleShortAnswer(q_data)
			else
				_handleEmptyNode

	_handleAnswerSelection = (e) ->
		target = $(e.target)

		if parseInt(target.attr('data-link')) is -1
			_end()
			return

		for i in [0.._qset.items[0].items.length-1]
			if parseInt(target.attr('data-link')) is _qset.items[0].items[i].options.id
				_manageQuestionScreen _qset.items[0].items[i]
				break

		_logProgress(target.attr('data-id'), target.attr('data-index'))

	_handleMultipleChoice = (q_data) ->

		node_screen = $('#node-screen-template').html()

		question =
			text : q_data.questions[0].text,
			layout : q_data.options.layout,
			type : q_data.options.type,
			id : q_data.options.id

		if question.layout isnt LAYOUT_TEXT_ONLY
			image_url = Materia.Engine.getImageAssetUrl _base_url, q_data.options.asset.id
			question.image = image_url

		answers = []

		for i in [0..q_data.answers.length-1]
			answer =
				text : q_data.answers[i].text,
				link : q_data.answers[i].options.link,
				index : i
			answers.push answer

		data =
			question : question,
			answers : answers,
			type : "mc"

		$('#node-screen').html(_.template(node_screen, data))

		$('.answer').on 'click', _handleAnswerSelection

	_handleHotspot = (q_data) ->

		########## TEMP CODE ############

		node_screen = $('#node-screen-template').html()

		question =
			text : "Hi! I should be a hotspot, but instead I'm a multiple choice question! Wait, WHAT'S GOING ON?!",
			layout : q_data.options.layout,
			type : q_data.options.type,
			id : q_data.options.id

		if question.layout isnt LAYOUT_TEXT_ONLY
			image_url = Materia.Engine.getImageAssetUrl _base_url, q_data.options.asset.id
			question.image = image_url

		answers = []

		for i in [0..q_data.answers.length-1]
			answer =
				text : q_data.answers[i].text,
				link : q_data.answers[i].options.link,
				index : i
			answers.push answer

		data =
			question : question,
			answers : answers,
			type : "mc"

		$('#node-screen').html(_.template(node_screen, data))

		$('.answer').on 'click', _handleAnswerSelection

		########### END TEMP CODE ####################

	_handleShortAnswer = (q_data) ->

		node_screen = $('#node-screen-template').html()

		question =
			text : q_data.questions[0].text,
			layout : q_data.options.layout,
			type : q_data.options.type,
			id : q_data.options.id

		data =
			question : question,
			type : "sa"

		if question.layout isnt LAYOUT_TEXT_ONLY
			image_url = Materia.Engine.getImageAssetUrl _base_url, q_data.options.asset.id
			question.image = image_url

		$('#node-screen').html(_.template(node_screen, data))

		$('#sa-answer').keypress (e) ->
			if e.which == 10 or e.which == 13
				_handleShortAnswerInput(e)

		_handleShortAnswerInput = (e) ->
			target = $(e.target)

			for i in [0..q_data.answers.length-1]
				raw_response_str = q_data.answers[i].text
				possible_responses = raw_response_str.trim().split(",") # NOTE THAT THIS REGEX IS NOT FINAL

				for j in [0..possible_responses.length-1]
					answer = target[0].value.toLowerCase()

					if (possible_responses[j].toLowerCase().trim() is answer) # ALSO NOT FINAL REGEX
						for k in [0.._qset.items[0].items.length-1]
							if parseInt(q_data.answers[i].options.link) is _qset.items[0].items[k].options.id
								_manageQuestionScreen _qset.items[0].items[k]
								_logProgress(question.id, i)
								return

			for n in [0.._qset.items[0].items.length-1]
				if parseInt(q_data.answers[0].options.link) is _qset.items[0].items[n].id
					_manageQuestionScreen _qset.items[0].items[n]
					_logProgress(question.id, 0)

			# _manageQuestionScreen _qset.items[0].items[] # should be [All Other Answers]

	_handleTransitional = (q_data) ->

		node_screen = $('#node-screen-template').html()

		question =
			text : q_data.questions[0].text,
			layout : q_data.options.layout,
			type : q_data.options.type,
			id : q_data.options.id

		if question.layout isnt LAYOUT_TEXT_ONLY
			image_url = Materia.Engine.getImageAssetUrl _base_url, q_data.options.asset.id
			question.image = image_url

		link = null
		if question.type is 5
			link = -1
			Materia.Score.submitFinalScoreFromClient q_data.id, question.text, q_data.options.finalScore
		else
			link = q_data.answers[0].options.link

		data =
			question : question,
			type : "trans",
			link : link

		$('#node-screen').html(_.template(node_screen, data))

		$('#trans-continue').on 'click', _handleAnswerSelection

	_handleEmptyNode = ->

	_logProgress = (question_id, answer_index) ->

		question_id = parseInt(question_id)
		answer_index = parseInt(answer_index)

		for i in [0.._qset.items[0].items.length-1]
			if question_id is _qset.items[0].items[i].options.id then break

		answer_text = null
		if answer_index is -1 then answer_text = "N/A" else answer_text = _qset.items[0].items[i].answers[answer_index].text

		Materia.Score.submitQuestionForScoring _qset.items[0].items[i].id, answer_text


	_end = ->
		Materia.Engine.end yes

	#public
	manualResize: true
	start: start