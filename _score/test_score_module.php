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
		  "items": [
		    {
		      "materiaType": "question",
		      "id": 0,
		      "nodeId": 0,
		      "type": "Adventure",
		      "questions": [
		        {
		          "text": "Multiple Choice Question"
		        }
		      ],
		      "options": {
		        "id": 0,
		        "parentId": -1,
		        "type": "mc",
		        "randomize": true
		      },
		      "answers": [
		        {
		          "text": "Correct MC Answer",
		          "value": 0,
		          "options": {
		            "link": 1,
		            "linkMode": "new",
		            "feedback": null
		          }
		        },
		        {
		          "text": "Wrong MC Answer",
		          "value": 0,
		          "options": {
		            "link": 2,
		            "linkMode": "new",
		            "feedback": null
		          }
		        }
		      ]
		    },
		    {
		      "materiaType": "question",
		      "id": 0,
		      "nodeId": 1,
		      "type": "Adventure",
		      "questions": [
		        {
		          "text": "Short Answer Question"
		        }
		      ],
		      "options": {
		        "id": 1,
		        "parentId": 0,
		        "type": "shortanswer"
		      },
		      "answers": [
		        {
		          "text": "[Unmatched Response]",
		          "value": 0,
		          "options": {
		            "link": 3,
		            "linkMode": "new",
		            "feedback": null,
		            "matches": [],
		            "isDefault": true
		          }
		        },
		        {
		          "text": "Correct Answer",
		          "value": 0,
		          "options": {
		            "link": 4,
		            "linkMode": "new",
		            "feedback": null,
		            "matches": [
		              "Correct Answer"
		            ]
		          }
		        }
		      ]
		    },
		    {
		      "materiaType": "question",
		      "id": 0,
		      "nodeId": 3,
		      "type": "Adventure",
		      "questions": [
		        {
		          "text": "You got 75%!"
		        }
		      ],
		      "options": {
		        "id": 3,
		        "parentId": 1,
		        "type": "end",
		        "finalScore": 75
		      },
		      "answers": []
		    },
		    {
		      "materiaType": "question",
		      "id": 0,
		      "nodeId": 4,
		      "type": "Adventure",
		      "questions": [
		        {
		          "text": "You got 100%!"
		        }
		      ],
		      "options": {
		        "id": 4,
		        "parentId": 1,
		        "type": "end",
		        "finalScore": 100
		      },
		      "answers": []
		    },
		    {
		      "materiaType": "question",
		      "id": 0,
		      "nodeId": 2,
		      "type": "Adventure",
		      "questions": [
		        {
		          "text": "MC Question after Wrong Answer"
		        }
		      ],
		      "options": {
		        "id": 2,
		        "parentId": 0,
		        "type": "mc",
		        "randomize": true
		      },
		      "answers": [
		        {
		          "text": "Choose this answer for 0% credit",
		          "value": 0,
		          "options": {
		            "link": 5,
		            "linkMode": "new",
		            "feedback": null
		          }
		        },
		        {
		          "text": "Choose this answer for 25% credit",
		          "value": 0,
		          "options": {
		            "link": 6,
		            "linkMode": "new",
		            "feedback": null
		          }
		        }
		      ]
		    },
		    {
		      "materiaType": "question",
		      "id": 0,
		      "nodeId": 5,
		      "type": "Adventure",
		      "questions": [
		        {
		          "text": "You got 0%!"
		        }
		      ],
		      "options": {
		        "id": 5,
		        "parentId": 2,
		        "type": "end",
		        "finalScore": 0
		      },
		      "answers": []
		    },
		    {
		      "materiaType": "question",
		      "id": 0,
		      "nodeId": 6,
		      "type": "Adventure",
		      "questions": [
		        {
		          "text": "You got 25%!"
		        }
		      ],
		      "options": {
		        "id": 6,
		        "parentId": 2,
		        "type": "end",
		        "finalScore": 25
		      },
		      "answers": []
		    }
		  ],
		  "options": {
		    "nodeCount": 8
		  }
		}');
	}

	protected function _make_widget()
	{
		$this->_asAuthor();

		$title = 'ADVENTURE SCORE MODULE TEST';
		$widget_id = $this->_find_widget_id('Adventure');
		$qset = null;

		$qset = (object) ['version' => 2, 'data' => $this->_get_qset()];

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
			"item_id":"'.$qset->data['items'][0]['id'].'",
			"game_time":11
		}');

		$logs[] = json_decode('{
			"text":"[Unmatched Response]",
			"type":1004,
			"value":0,
			"item_id":"'.$qset->data['items'][1]['id'].'",
			"game_time":12
		}');

		$logs[] = json_decode('{
			"text":"You got 75%!",
			"type":1002,
			"value":0,
			"item_id":"'.$qset->data['items'][2]['id'].'",
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
		$this->assertEquals(75, $this_score[0]['overview']['score']);
	}
}
