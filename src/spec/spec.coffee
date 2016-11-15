# Specs are imported by and run in the test environment
# by Materia's spec/materia.spec.coffee

client = {}

describe 'Testing framework', ->
	it 'should load widget', (done) ->
		require('./widgets.coffee') 'adventure', ->
			client = this
			done()
	, 25000

describe 'Adventure Player', ->

	it 'should show narration', (done) ->
		client.
			getText '.question .text', (err, text) ->
				expect(text).toContain("You're a nurse working in the Emergency Room")
				client.call done

	it 'should have an image asset', (done) ->
		client
			.waitFor 'figure img', 5000
			.pause 1000
			.click '.trans input'
			.call done

	it 'should show a question', (done) ->
		client
			.pause 1000
			.getText '.question .text', (err, text) ->
				expect(text).toContain("After reviewing the patient's chart")
				client.call done

	it 'should give feedback when offering coffee', (done) ->
		client
			.click ".answer[data-link='1']"
			.pause 1000
			.getText ('.feedback'), (err, text) ->
				expect(text).toContain('While a nice thing to do')
				client
					.click '.feedback-button'
					.call done

	it 'should be able to interview the mom', (done) ->
		client
			.click ".answer[data-link='3']"
			.call done

	it 'should receive information from the mother', (done) ->
		client
			.pause 1000
			.click '.trans input'
			.call done

	it 'should display the diagnosis prompt', (done) ->
		client
			.getText '.question .text', (err, text) ->
				expect(text).toContain("After reviewing your findings, you're ready to make a nursing diagnosis.")
				client.call done

	it 'should select influenza', (done) ->
		client
			.click ".answer[data-link='7']"
			.call done

	it 'should be able to input "nurse practitioner"', (done) ->
		client
			.pause 1000
			.setValue 'input.short-answer', 'Nurse Practitioner'
			.click '.sa .trans-button'
			.pause 1000
			.call done

	it 'should give feedback', (done) ->
		client
			.getText '.feedback', (err, text) ->
				expect(text).toContain('Correct')
				client
					.click '.feedback-button'
					.call done

	it 'should be rejected by the HCP', (done) ->
		client
			.pause 1000
			.getText '.question .text', (err, text) ->
				expect(text).toContain("After reviewing the child's symptoms, the Healthcare Provider rejects your diagnosis of Influenza")
				client
					.click '.trans input'
					.call done

	it 'should display a hotspot question prompt', (done) ->
		client
			.pause 1000
			.getText '.question .text', (err, text) ->
				expect(text).toContain('Which part of the chart do you think')
				client.call done

	it 'should be able to select lethargy hotspot', (done) ->
		client
			.click ".hotarea g[data-label='The patient is lethargic'] rect"
			.call done

	it 'should be asked to re-select a diagnosis by HCP', (done) ->
		client
			.pause 1000
			.click '.trans input'
			.call done

	it 'should be able to select dehydration', (done) ->
		client
			.pause 1000
			.click ".answer[data-link='6']"
			.call done

	it 'should be able to input "nurse"', (done) ->
		client
			.pause 1000
			.setValue 'input.short-answer', 'Nurse'
			.click '.sa .trans-button'
			.pause 1000
			.call done

	it 'should get it wrong', (done) ->
		client
			.pause 1000
			.getText '.feedback', (err, text) ->
				expect(text).toContain('Incorrect')
				client
					.click '.feedback-button'
					.call done

	it 'should display a question', (done) ->
		client
			.pause 1000
			.getText '.question .text', (err, text) ->
				expect(text).toContain("You're ready to contact")
				client.call done

	it 'should select influenza symptoms', (done) ->
		client
			.click ".answer[data-link='10']"
			.call done

	it 'should receive correct feedback', (done) ->
		client
			.getText '.feedback', (err, text) ->
				expect(text).toContain('Correct')
				client
					.click '.feedback-button'
					.call done

	it 'should expect an image asset accompanying the narrative', (done) ->
		client
			.pause 1000
			.waitFor 'figure img', 5000
			.call done

	it 'should begin treatment on patient', (done) ->
		client
			.click '.trans input'
			.call done

	it 'should be be able to choose to leave immediately', (done) ->
		client
			.pause 1000
			.click ".answer[data-link='13']"
			.call done

	it 'should receive warning about informing mother', (done) ->
		client
			.pause 1000
			.getText '.feedback', (err, text) ->
				expect(text).toContain('Not quite!')
				client
					.click '.feedback-button'
					.call done

	it 'should reach final screen', (done) ->
		client
			.pause 1000
			.getText '.question .text', (err, text) ->
				expect(text).toContain('Great work!')
				client
					.click '.trans input'
					.call done

describe 'Score page', ->
	it 'should get a 90', (done) ->
		client.pause 10000
		client.getTitle (err, title) ->
			expect(title).toBe('Score Results | Materia')
			client
				.getText '.overall-score, .overall_score', (err, text) ->
					expect(text).toBe('90%')
					client.call done
					client.end()
	, 40000





