from core.models import Log, Question
from scoring.module import ScoreModule

class Adventure(ScoreModule):

    def __init__(self, play):
        super().__init__(play)
        options = self.qset.get("options", {})
        if isinstance(options, dict):
            self.scoreMode = options.get("scoreMode", "Normal")
        else:
            self.scoreMode = "Normal"

    def check_answer(self, log):
        if log.log_type == Log.LogType.SCORE_FINAL_FROM_CLIENT:

            if self.scoreMode == "Non-Scoring":
                return 100

            for question in self.questions:

                if (
                    question.data.get("options").get("type") != "end" and
                    str(question.data.get("options").get("type")) != "5"
                ):
                    continue

                if log.item_id:

                    if int(log.item_id) == int(
                        question.data.get("options")
                        .get("id")
                    ):
                        if "finalScore" in question.data.get("options"):
                            return int(
                                question.data.get("options")
                                .get("finalScore", 0)
                            )
                        # a matching node was found but it does not have the property we expect
                        # use the log's score value as a fallback
                        else:
                            return int(log.value)

                else:
                    if (
                        log.text == question.data
                        .get("questions")[0]
                        .get("text", "")
                    ):
                        return int(
                            question.data.get("options")
                            .get("finalScore")
                        )
            # if we got this far we didn't find a corresponding Question model instance
            # check the qset for a matching node
            if log.item_id is not None:
                question = self.find_item_with_id(log.item_id, True)
                if question is not None:
                    if "finalScore" in question.get("options"):
                        return int(
                            question.get("options")
                            .get("finalScore", 0)
                        )
                    # a matching node was found but it does not have the property we expect
                    # use the log's score value as a fallback
                    else:
                        return int(log.value)

            return 0
        else:
            return -1

    def handle_log_question_answered(self, log):
        pass

    def handle_log_client_final_score(self, log):
        self.verified_score = 0
        self.total_questions = 0
        val = self.check_answer(log)
        self.global_modifiers.append(val)

    def calculate_score(self):
        points = self.verified_score + sum(self.global_modifiers)
        self.calculated_percent = round(points)
        if self.calculated_percent < 0:
            self.calculated_percent = 0
        if self.calculated_percent > 100:
            self.calculated_percent = 100

    def details_for_question_answered(self, log):
        question = self.get_question_by_item_id(log.item_id)
        score = self.check_answer(log)

        return {
            "id": log.item_id,
            "data": [
                self.get_ss_question(log, question),
                self.get_ss_answer(log, question),
                log.value,
            ],
            "data_style": ["question", "response"],
            "score": score,
            "feedback": None,
            "type": log.log_type,
            "style": self.get_detail_style(score),
            "symbol": "%",
            "graphic": "score",
            "display_score": False,
        }

    def get_score_details(self):

        details = []

        blank_node_str = ("Blank Destination! Be sure to edit "
                          "or remove this node before publishing.")

        for log in self.logs:

            if log.log_type == Log.LogType.SCORE_QUESTION_ANSWERED:
                question = self.get_question_by_item_id(log.item_id)
                if question is None:
                    break

                details.append(self.details_for_question_answered(log))

            elif log.log_type == Log.LogType.SCORE_FINAL_FROM_CLIENT:
                details.append({
                    "node_id": log.item_id,
                    "data": [log.text, self.check_answer(log)],
                    "data_style": ["text", "score"],
                    "score": self.check_answer(log),
                    "type": log.log_type,
                    "style": "final_score",
                    "symbol": "%",
                    "graphic": "score",
                    "display_score": False,
                    "older_qset": (
                        log.item_id == "0" and log.text != blank_node_str
                    ),
                    "blank_node": (
                        log.item_id == "0" and log.text == blank_node_str
                    ),
                })

        return [
            {
                "title": self._ss_table_title,
                "header": ['Question Score', 'The Question', 'Your Response'],
                "table": details,
            }
        ]

    def get_question_by_item_id(self, item_id):
        question = next((q for q in self.questions if q.item_id == item_id), None)
        # see if we can find this question in the qset itself
        if question is None:
            return self.find_item_with_id(item_id)
        return question.data

    def find_item_with_id(self, item_id, isNodeId=False):
        import copy

        def _process_item(item):
            if isinstance(item, list):
                for element in item:
                    result = _process_item(element)
                    if result is not None:
                        return result

            elif isinstance(item, dict):
                copied_item = copy.deepcopy(item)

                if Question.is_question(copied_item):
                    if isNodeId:
                        if "options" in copied_item and int(copied_item.get("options").get("id")) == int(item_id):
                            return copied_item
                    elif copied_item.get("id") == item_id:
                        return copied_item

                for value in copied_item.values():
                    if isinstance(value, (dict, list)):
                        result = _process_item(value)
                        if result is not None:
                            return result
            return None
        return _process_item(self.qset)
