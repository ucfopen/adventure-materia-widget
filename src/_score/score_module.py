from core.models import Log
from scoring.module import ScoreModule

class Adventure(ScoreModule):

    def _qset_dict(self):
        q = getattr(self.qset, "data", self.qset)
        if isinstance(q, list):
            q = next((x for x in q if isinstance(x, dict)), {})
        return q if isinstance(q, dict) else {}

    def _iter_nodes(self, items):
        stack = list(items or [])
        while stack:
            it = stack.pop()
            if not isinstance(it, dict):
                continue
            # unwrap wrapper objects: have 'items' but not a real node
            if "items" in it and not any(k in it for k in ("type", "questions", "answers")):
                kids = it.get("items") or []
                if isinstance(kids, list):
                    stack.extend(kids)
                continue
            yield it

    def _items_list(self):
        q = self._qset_dict()
        if q.get("version") == 1:
            lst = q.get("items") or []
            return (lst[0].get("items") or []) if lst and isinstance(lst[0], dict) else []
        return q.get("items") or []

    def _match_end_node(self, log):
        """Return the matching end node dict for this FINAL log, or None."""
        for item in self._iter_nodes(self._items_list()):
            opts = item.get("options") or {}
            if not isinstance(opts, dict):
                continue
            is_end = (opts.get("type") in ("end", "5")) or ("finalScore" in opts)
            if not is_end:
                continue
            if getattr(log, "item_id", None) and log.item_id == opts.get("id"):
                return item
            if not getattr(log, "item_id", None):
                # fallback: text match for older qsets
                qs = item.get("questions") or []
                q0 = qs[0] if qs and isinstance(qs[0], dict) else {}
                if (getattr(log, "text", "") or "").strip() == (q0.get("text", "") or "").strip():
                    return item
        return None

    def _final_text_for_log(self, log):
        """Prefer the matched end node's text when log.text is blank/mismatched."""
        node = self._match_end_node(log)
        if node:
            qs = node.get("questions") or []
            q0 = qs[0] if qs and isinstance(qs[0], dict) else {}
            return (q0.get("text", "") or "").strip()
        return (getattr(log, "text", "") or "").strip()


    def __init__(self, play):
        super().__init__(play)
        print(f"self.qset: {self.qset}")
        raw_qset = getattr(self.qset, "data", self.qset)

        if isinstance(raw_qset, list):
            #sometimes it is not a dict in the demo
            raw = raw[0] if raw and isinstance(raw[0], dict) else {}

        # self.scoreMode = self.qset.get("options", {}).get("scoreMode", "Normal")
        self.scoreMode = (self.qset.get("options") or {}).get("scoreMode", "Normal")
        print(f"scoreMode: {self.scoreMode}")

        self._ss_table_title = "Responses:"
        self._ss_table_headers = ["Question Score", "The Question", "Your Response"]

    def check_answer(self, log):
        print("[CHECK ANSWER START] inside check answer")
        if self.scoreMode == "Normal":
            print("we are in normal scoring mode")
            if getattr(log, "log_type", None) != Log.LogType.SCORE_FINAL_FROM_CLIENT:
                print("not a final score log so we return -1 and early")
                return -1
            # try:
            #     print(f"we are inside the try, and our log type is {log.log_type}")

            qset_data = getattr(self.qset, "data", self.qset)
            if isinstance(qset_data, list):
                qset_data = next((x for x in qset_data if isinstance(x, dict)), {})
            if not isinstance(qset_data, dict):
                qset_data = {}

            # v1 vs v2 (your existing branches)
            if qset_data.get("version") == 1:
                items_list = qset_data.get('items', [])
                items = (items_list[0].get('items', []) if items_list and isinstance(items_list[0], dict) else [])
            else:
                items = qset_data.get('items', [])

            # --- NEW: unwrap single wrapper object like {'items': [...], 'options': []}
            if (isinstance(items, list) and items and isinstance(items[0], dict)
                    and "items" in items[0] and not any(k in items[0] for k in ("type", "questions", "answers"))):
                items = items[0].get("items", [])

            for item in items:
                # skip non-dicts defensively
                if not isinstance(item, dict):
                    continue
                # --- NEW: coerce/guard options so list/[] doesn't blow up
                opts = item.get("options") or {}
                if not isinstance(opts, dict):
                    # not a real node (typical in wrappers); skip
                    continue
                # your existing logic from here down
                if opts.get('type') not in ('end', '5'):
                    continue

                if log.item_id:
                    if log.item_id == opts.get('id'):
                        return 100 if self.scoreMode == 'Non-Scoring' else int(opts.get('finalScore', 0))
                else:
                    qs = item.get('questions') or []
                    q0 = qs[0] if qs and isinstance(qs[0], dict) else {}
                    if (log.text or "").strip() == (q0.get('text', "") or "").strip():
                        return 100 if self.scoreMode == 'Non-Scoring' else int(opts.get('finalScore', 0))

            # fallback (keep your current behavior)
            return int(getattr(log, "value", 0))

                # qset_data = getattr(self.qset, "data", self.qset)
                # # v1: nested under items[0]['items']
                # if qset_data.get("version") == 1:
                #     print("we are v1 qset")
                #     items_list = qset_data.get('items', [])
                #     items = (items_list[0].get('items', []) if items_list else [])
                # else:
                #     print("we are v2 qset")
                #     items = qset_data.get('items', [])

                # for item in items:
                #     # print(f"[FOR LOOP]we going in our loop of items and item is: {item}")
                #     # we ignore all items that are not end nodes
                #     print(f"[FOR LOOP ITEM] our list is {item} and the type is { type(item) }")

                #     if item['options']['type'] not in ('end', '5'):
                #         print("we are not in an end or 5 question so we continue")
                #         continue

                #     if log.item_id:
                #         if log.item_id == item['options']['id']:
                #             print(f"we are returining this score: { int(item['options']['finalScore']) }")
                #             return 100 if self.scoreMode == 'Non-Scoring' else int(item['options']['finalScore'])
                #     else:
                #         if log.text.strip() == item['questions'][0]['text'].strip():
                #             print(f"we are instead returning this score: { int(  item['options']['finalScore'] ) }")
                #             return 100 if self.scoreMode == 'Non-Scoring' else int(item['options']['finalScore'])

                # print(f"we are an \"end\" node type: we are returning score: {int(log.value)}")
                # return int(log.value)
            # except Exception as e:
                # print(f"error: {e}")
                # return 0
        # else:
            # return 100

    def handle_log_question_answered(self, log):
        # need to ignore this method
        pass

    def handle_log_client_final_score(self, log) -> None:
        self.verified_score = 0
        self.total_questions = 0
        print(f"we are checking answer for log: {log} and log type is {log.log_type}")
        final_val = self.check_answer(log)
        self.global_modifiers.append(final_val)

    def calculate_score(self):
        # php does (verified + sum(modifiers)) then round and clamp
        points = self.verified_score + sum(self.global_modifiers)
        self.calculated_percent = round(points)
        if self.calculated_percent < 0:
            self.calculated_percent = 0
        if self.calculated_percent > 100:
            self.calculated_percent = 100


    def get_score_overview(self):
        return {
            "complete": getattr(self.play, "is_complete", False),
            "score": self.calculated_percent,
            "table": self.get_overview_items(),
            "referrer_url": "",  # match php
            "created_at": "",    # match php
            "auth": "",          # match php
        }



    def details_for_question_answered(self, log):
        question = self.get_question_by_item_id(log.item_id)
        if not isinstance(question, dict):
            return None  # skip quietly

        # safe answers list
        answers = question.get("answers") or []
        if not isinstance(answers, list):
            answers = []

        score = self.check_answer(log)  # will return -1 for non-final logs per your logic

        return {
            "id": log.item_id,
            "data": [
                self.get_ss_question(log, question),
                self.get_ss_answer(log, question),
                log.value,
            ],
            "data_style": ["question", "response"],
            "score": score,
            "feedback": self.get_feedback(log, answers),
            "type": log.log_type,
            "style": self.get_detail_style(score),
            "symbol": "%",
            "graphic": "score",
            "display_score": False,
        }

    # def details_for_question_answered(self, log):
    #     question = self.get_question_by_item_id(log.item_id)
    #     score = self.check_answer(log)

    #     return {
    #         'id': log.item_id,
    #         'data': [
    #             self.get_ss_question(log, question),
    #             self.get_ss_answer(log, question),
    #             log.value
    #         ],
    #         'data_style'    : ['question', 'response'],
    #         'score'         : score,
    #         'feedback'      : self.get_feedback(log, question["answers"]),
    #         'type'          : log.log_type,
    #         'style'         : self.get_detail_style(score),
    #         'symbol'        : '%',
    #         'graphic'       : 'score',
    #         'display_score' : False
    #     }

    def get_score_details(self):
        """
        Build the legacy 'final score' row so the UI has something to render.
        Also expose BOTH keys: 'headers' (React expects) and 'header' (legacy).
        """
        details_rows = []
        # table = []

        for log in self.logs:
            print(f"our log is {log} and the log type is {log.log_type}")

            if log.log_type == Log.LogType.SCORE_QUESTION_ANSWERED:
                question = self.get_question_by_item_id(log.item_id)
                print(f"question is {question}")

                if question is not None:
                    print("our question is not none")
                    row = self.details_for_question_answered(log)
                    details_rows.append(row)
                else:
                    print("our question is none")

            if log.log_type == Log.LogType.SCORE_FINAL_FROM_CLIENT:
                score = self.check_answer(log)
                # log_text = getattr(log, "text", "") or ""
                log_text = self._final_text_for_log(log)
                item_id = getattr(log, "item_id", 0)

                older_qset = (item_id == 0 and log_text != "Blank Destination! Be sure to edit or remove this node before publishing.")
                blank_node = (item_id == 0 and log_text == "Blank Destination! Be sure to edit or remove this node before publishing.")

                details_rows.append({
                    # shape the row the way the score screen expects
                    "node_id": item_id,
                    "data": [log_text, score],           # [text, score]
                    "data_style": ["text", "score"],     # matches PHP order
                    "score": score,
                    "type": log.log_type,
                    "style": "final_score",
                    "symbol": "%",
                    "graphic": "score",
                    "display_score": False,
                    "older_qset": older_qset,
                    "blank_node": blank_node,
                })

                print(f"[DETAILS] built {len(details_rows)} rows")
                print(f"[OVERVIEW] table rows = {len(self.get_overview_items())} (should be 2)")

        headers = self._ss_table_headers

        return [
            {
                "title": self._ss_table_title,
                "headers": headers,      # usually we go by headers in base score module
                "header": headers,       # adventure goes by headers for some reason?? legacy compatibility, harmless
                "table": details_rows,   # the rows we just built
            }
        ]











    # def get_score_report(self) -> object:
    #     return {
    #         "overview": {
    #             "complete": True,
    #             "score": 21,
    #             "table": [
    #                 {"message": "Points Lost", "value": -79},
    #                 {"message": "Final Score", "value": 21},
    #             ],
    #             "referrer_url": "",
    #             "created_at": "",
    #             "auth": "",
    #         },
    #         "details": [
    #             {
    #                 "title": "Responses:",
    #                 "header": ["Question Score", "The Question", "Your Response"],
    #                 "table": [
    #                     {
    #                         "id": "3ac0d649-ffff-4ee9-bfae-f3e3dea4689f",
    #                         "data": ["what is 9+10", "21", ""],
    #                         "data_style": ["question", "response"],
    #                         "score": -1,
    #                         "feedback": None,
    #                         "type": "SCORE_QUESTION_ANSWERED",
    #                         "style": "ignored-value",
    #                         "symbol": "%",
    #                         "graphic": "score",
    #                         "display_score": False,
    #                     },
    #                     {
    #                         "id": "b0320af9-c23b-4ea3-9d1b-dce87e9323e1",
    #                         "data": ["funny", "", ""],
    #                         "data_style": ["question", "response"],
    #                         "score": -1,
    #                         "feedback": None,
    #                         "type": "SCORE_QUESTION_ANSWERED",
    #                         "style": "ignored-value",
    #                         "symbol": "%",
    #                         "graphic": "score",
    #                         "display_score": False,
    #                     },
    #                     {
    #                         "node_id": 4,
    #                         "data": ["\nyou get what you deserve\n", 21],
    #                         "data_style": ["text", "score"],
    #                         "score": 21,
    #                         "type": "SCORE_FINAL_FROM_CLIENT",
    #                         "style": "final_score",
    #                         "symbol": "%",
    #                         "graphic": "score",
    #                         "display_score": False,
    #                         "older_qset": False,
    #                         "blank_node": False,
    #                     },
    #                 ],
    #             }
    #         ],
    #         "qset": {
    #             "version": "2",
    #             "data": {
    #                 "items": [
    #                     {
    #                         "materiaType": "question",
    #                         "id": "3ac0d649-ffff-4ee9-bfae-f3e3dea4689f",
    #                         "type": "Adventure",
    #                         "created_at": 1756995950,
    #                         "questions": [{"text": "what is 9+10"}],
    #                         "answers": [
    #                             {
    #                                 "text": "19",
    #                                 "value": 0,
    #                                 "options": {
    #                                     "link": 2,
    #                                     "linkMode": "new",
    #                                     "feedback": None,
    #                                     "requiredItems": [],
    #                                     "hideAnswer": False,
    #                                     "hideRequiredItems": False,
    #                                 },
    #                                 "id": "abfd405f-cdbc-45bb-9b68-c20e0ff510d5",
    #                             },
    #                             {
    #                                 "text": "21",
    #                                 "value": 0,
    #                                 "options": {
    #                                     "link": 3,
    #                                     "linkMode": "new",
    #                                     "feedback": None,
    #                                     "requiredItems": [],
    #                                     "hideAnswer": False,
    #                                     "hideRequiredItems": False,
    #                                 },
    #                                 "id": "2a3ef1bf-a851-483f-8856-c71de33f918e",
    #                             },
    #                         ],
    #                         "options": {
    #                             "id": 0,
    #                             "parentId": -1,
    #                             "type": "mc",
    #                             "items": [],
    #                             "additionalQuestions": [],
    #                             "randomize": False,
    #                         },
    #                         "assets": [],
    #                     },
    #                     {
    #                         "materiaType": "question",
    #                         "id": "1f5988f4-283d-4164-a3d0-99198fa5e6d1",
    #                         "type": "Adventure",
    #                         "created_at": 1756995950,
    #                         "questions": [{"text": "wow you are boring"}],
    #                         "answers": [
    #                             {
    #                                 "text": None,
    #                                 "value": 0,
    #                                 "options": {
    #                                     "link": 5,
    #                                     "linkMode": "new",
    #                                     "feedback": None,
    #                                     "requiredItems": [],
    #                                     "hideAnswer": False,
    #                                     "hideRequiredItems": False,
    #                                 },
    #                                 "id": "c624fb2d-0b38-4c12-942d-d81953f5b46e",
    #                             }
    #                         ],
    #                         "options": {
    #                             "id": 2,
    #                             "parentId": 0,
    #                             "type": "narrative",
    #                             "items": [],
    #                             "additionalQuestions": [],
    #                         },
    #                         "assets": [],
    #                     },
    #                     {
    #                         "materiaType": "question",
    #                         "id": None,
    #                         "nodeId": 5,
    #                         "type": "Adventure",
    #                         "questions": [{"text": "does he know", "$$hashKey": "object:94"}],
    #                         "options": {
    #                             "id": 5,
    #                             "parentId": 2,
    #                             "type": "end",
    #                             "items": [],
    #                             "additionalQuestions": [],
    #                             "finalScore": 100,
    #                         },
    #                         "answers": [],
    #                     },
    #                     {
    #                         "materiaType": "question",
    #                         "id": "b0320af9-c23b-4ea3-9d1b-dce87e9323e1",
    #                         "type": "Adventure",
    #                         "created_at": 1756995950,
    #                         "questions": [{"text": "funny"}],
    #                         "answers": [
    #                             {
    #                                 "text": None,
    #                                 "value": 0,
    #                                 "options": {
    #                                     "link": 4,
    #                                     "linkMode": "new",
    #                                     "feedback": None,
    #                                     "requiredItems": [],
    #                                     "hideAnswer": False,
    #                                     "hideRequiredItems": False,
    #                                 },
    #                                 "id": "0ebdc30a-c9e9-4cfe-b8e6-c204d9363dbb",
    #                             }
    #                         ],
    #                         "options": {
    #                             "id": 3,
    #                             "parentId": 0,
    #                             "type": "narrative",
    #                             "items": [],
    #                             "additionalQuestions": [],
    #                         },
    #                         "assets": [],
    #                     },
    #                     {
    #                         "materiaType": "question",
    #                         "id": None,
    #                         "nodeId": 4,
    #                         "type": "Adventure",
    #                         "questions": [{"text": "you get what you deserve", "$$hashKey": "object:163"}],
    #                         "options": {
    #                             "id": 4,
    #                             "parentId": 3,
    #                             "type": "end",
    #                             "items": [],
    #                             "additionalQuestions": [],
    #                             "finalScore": 21,
    #                         },
    #                         "answers": [],
    #                     },
    #                 ],
    #                 "options": {
    #                     "nodeCount": 6,
    #                     "inventoryItems": [],
    #                     "customIcons": [],
    #                     "hidePlayerTitle": False,
    #                     "startID": 0,
    #                     "scoreMode": "Normal",
    #                     "internalScoreMessage": "",
    #                 },
    #                 "id": "38474",
    #             },
    #             "id": 38474,
    #         },
    #     }
    #
    #

