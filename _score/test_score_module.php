<?php
/**
 * @group App
 * @group Materia
 * @group Score
 * @group Adventure
 */
class Test_Score_Modules_Adventure extends \Basetest
{
	protected function _get_qset()
	{
		return json_decode('{
			"items":[
				{
					"items":[
						{
							"name":"",
							"type":"MC",
							"assets":null,
							"answers":[
								{
									"value":100,
									"text":"Correct MC Answer",
									"options":{
										"feedback":null,
										"link":1
									},
									"id":0
								},
								{
									"value":0,
									"text":"Wrong MC Answer",
									"options":{
											"feedback":null,
											"link":1
									},
									"id":0
								}
							],
							"questions":[
								{
									"text":"Multiple Choice Question"
								}
							],
							"options":{
								"randomize":1,
								"type":2,
								"layout":1,
								"id":0
							},
							"id":0
						},
						{
							"name":"",
							"type":"MC",
							"assets":null,
							"answers":[
								{
									"value":0,
									"text":"[All Other Answers]",
									"options":{
											"feedback":null,
											"link":2,
											"isDefault":1
									},
									"id":0
								},
								{
									"value":100,
									"text":"Correct Answer",
									"options":{
										"feedback":null,
										"link":3,
										"isShortcut":1
									},
									"id":0
								}
							],
							"questions":[
								{
									"text":"Short Answer Question"
								}
							],
							"options":{
								"randomize":1,
								"type":4,
								"layout":1,
								"id":0
							},
							"id":0
						},
						{
							"name":"",
							"type":"MC",
							"assets":null,
							"answers":[],
							"questions":[
								{
									"text":"Full Credit"
								}
							],
							"options":{
								"finalScore":100,
								"id":0,
								"type":5,
								"proceedText":"Continue",
								"layout":1
							},
							"id":0
						},
						{
							"name":"",
							"type":"MC",
							"assets":null,
							"answers":[],
							"questions":[
								{
									"text":"Half Credit"
								}
							],
							"options":{
								"finalScore":50,
								"id":0,
								"type":5,
								"proceedText":"Continue",
								"layout":1
							},
							"id":0
						}

					],
					"name":"",
					"options":{
			     			"scoreStyle":2
					},
					"assets":[],
					"rand":null
				}
			],
			"name":"",
			"options":{},
			"assets":[],
			"rand":null,
			"id":0
		}');
	}

	protected function _make_widget()
	{
		$this->_asAuthor();

		$title = 'ADVENTURE SCORE MODULE TEST';
		$widget_id = $this->_find_widget_id('Adventure');
		$qset = null;

		$qset = (object) ['version' => 1, 'data' => $this->_get_qset()];

		return \Materia\Api::widget_instance_save($widget_id, $title, $qset, false);
	}

	public function test_check_answer()
	{
		$inst = $this->_make_widget();

		$play_session = \Materia\Api::session_play_create($inst->id);
		$qset = \Materia\Api::question_set_get($inst->id, $play_session);

		$logs = array();

		$logs[] = json_decode('{
			"text":"Correct MC Answer",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][0]['id'].'",
			"game_time":11
		}');

		$logs[] = json_decode('{
			"text":"[All Other Answers]",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][1]['id'].'",
			"game_time":12
		}');

		$logs[] = json_decode('{
			"text":"Half Credit",
			"type":1002,
			"value":0,
			"item_id":"'.$qset->data['items'][0]['items'][2]['id'].'",
			"game_time":13
		}');

		$logs[] = json_decode('{
			"text":"",
			"type":2,
			"value":"",
			"item_id":0,
			"game_time":14
		}');

		$output = \Materia\Api::play_logs_save($play_session, $logs);

		$scores = \Materia\Api::widget_instance_scores_get($inst->id);

		$this_score = \Materia\Api::widget_instance_play_scores_get($play_session);

		$this->assertInternalType('array', $this_score);
		$this->assertEquals(50, $this_score[0]['overview']['score']);
	}

}