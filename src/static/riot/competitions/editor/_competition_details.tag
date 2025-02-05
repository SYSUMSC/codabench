<competition-details>
    <div class="ui form">

        <!--  标题  -->
        <div class="field required">
            <label>标题</label>
            <input type="text" ref="title" onchange="{form_updated}">
        </div>

        <!--  标志  -->
        <div class="field required">
            <label>标志</label>
            <!-- 这是仅支持单文件上传，没有其他选项的示例 -->
            <!-- 将来，我们会同时支持这种类型以及预填选项的类型 -->
            <label show="{ uploaded_logo }">
                已上传标志: <a href="{ uploaded_logo }" target="_blank">{ uploaded_logo_name }</a>
            </label>
            <div class="ui left action file input">
                <button class="ui icon button" onclick="document.getElementById('form_file_logo').click()">
                    <i class="attach icon"></i>
                </button>
                <input id="form_file_logo" type="file" ref="logo" accept="image/*">

                <!-- 上传后显示文件名 -->
                <input value="{ logo_file_name }" readonly onclick="document.getElementById('form_file_logo').click()">
            </div>
        </div>

        <!--  描述  -->
        <div class="field smaller-mde">
            <label>描述</label>
            <textarea class="markdown-editor" ref="comp_description" name="description" onchange="{form_updated}"></textarea>
        </div>

        <!--  队列  -->
        <div class="field">
            <label>队列</label>
            <select class="ui fluid search selection dropdown" ref="queue"></select>
        </div>

        <!--  竞赛 Docker 镜像  -->
        <div class="field required">
            <label>竞赛 Docker 镜像</label>
            <input type="text" ref="docker_image" placeholder="示例: codalab/codalab-legacy:py37" onchange="{form_updated}">
        </div>

        <!--  竞赛类型  -->
        <div class="field">
            <label>竞赛类型</label>
            <div ref="competition_type" class="ui selection dropdown">
                <input type="hidden" name="competition_type" value="{ data.competition_type || 'competition' }" onchange="{form_updated}">
                <div class="text">Competition</div>
                <i class="dropdown icon"></i>
                <div class="menu">
                    <div class="item" data-value="competition">Competition</div>
                    <div class="item" data-value="benchmark">Benchmark</div>
                </div>
            </div>
        </div>

        <!--  竞赛奖励  -->
        <div class="field">
            <label>竞赛奖励</label>
            <input type="text" ref="reward" placeholder="示例: 顶级参赛者奖金 $1000" onchange="{form_updated}">
        </div>
        <!--  主办方联系邮箱  -->
        <div class="field">
            <label>主办方联系邮箱</label>
            <input type="email" ref="contact_email" placeholder="示例: email@example.com" onchange="{form_updated}">
        </div>
        <!--  竞赛报告  -->
        <div class="field">
            <label>竞赛报告</label>
            <input type="text" ref="report" placeholder="示例: https://example.com/report.pdf" onchange="{form_updated}">
        </div>

        <!--  信息表  -->
        <div class="field smaller-mde">
            <label>信息表</label>
            <div class="row">
                <button class="ui basic blue button" onclick="{ add_question.bind(this, 'boolean') }">布尔型 +</button>
                <button class="ui basic blue button" onclick="{ add_question.bind(this, 'text') }">文本 +</button>
                <button class="ui basic blue button" onclick="{ add_question.bind(this, 'selection') }">选择 +</button>
            </div>
            <br>
            <form ref="comp_fact_sheet">
            <div class="fact-sheet-question" each="{question in fact_sheet_questions}">
                <div class="row" id="q-div-{question.id}">
                    <p  if="{ question.type === 'checkbox' }">类型: 布尔型
                    <input type="hidden" name="type-{question.id}" value="checkbox">
                    </p>
                    <p if="{ question.type === 'text' }">类型: 文本
                    <input type="hidden" name="type-{question.id}" value="text">
                    </p>
                    <p if="{ question.type === 'select' }">类型: 选择
                    <input type="hidden" name="type-{question.id}" value="select">
                    </p>
                    <p>
                        <label style="font-size: 1em; font-weight: 500;" for="key-{question.id}">键名: </label>
                        <a class="float-right" data-tooltip="程序访问数据时需要键。最佳实践是不包含空格。" data-position="right center">
                            <i class="grey question circle icon"></i>
                        </a>
                        <input name="key-{question.id}" id="key-{question.id}" type="text" value="{question.key}">
                    </p>
                    <p if="{ question.type === 'select' }">
                        <label for="selection-{question.id}">选项（逗号分隔）: </label>
                        <input name="selection-{question.id}" id="selection-{question.id}" type="text" value="{question.selection.join()}">
                    </p>
                    <p>
                        <label for="is_on_leaderboard-{question.id}">在排行榜上显示: </label>
                        <input type="hidden" name="is_on_leaderboard-{question.id}" value="false">
                        <input if="{question.is_on_leaderboard === 'true'}" type="checkbox" name="is_on_leaderboard-{question.id}" value="true" onchange="{form_updated}" checked>
                        <input if="{question.is_on_leaderboard !== 'true'}" type="checkbox" name="is_on_leaderboard-{question.id}" value="true" onchange="{form_updated}">
                    </p>
                    <p>
                        <label for="title-{question.id}">显示名称: </label>
                        <a class="float-right" data-tooltip="用户在作答时看到的内容，以及排行榜上的类别名称。" data-position="right center">
                            <i class="grey question circle icon"></i>
                        </a>
                        <input name="title-{question.id}" id="title-{question.id}" type="text" value="{question.title}">
                    </p>
                    <p>
                        <label for="is-required-{question.id}">是否必填: </label>
                        <input type="hidden" name="is_required-{question.id}" value="false">
                        <input if="{question.is_required === 'true'}" type="checkbox" name="is_required-{question.id}" value="true" onchange="{form_updated}" checked>
                        <input if="{question.is_required !== 'true'}" type="checkbox" name="is_required-{question.id}" value="true" onchange="{form_updated}">
                    </p>
                </div>
                <br>
                <button class="ui basic red button" onclick="{remove_question.bind(this, question.id)}">移除</button>
            </div>
            </form>
        </div>

        <!--  可用文件  -->
        <div class="field smaller-mde">
            <label>
                可用文件
                <sup>
                    <a href="https://github.com/codalab/codabench/wiki/Yaml-Structure"
                       target="_blank"
                       data-tooltip="这是什么？">
                        <i class="grey question circle icon"></i>
                    </a>
                </sup>
            </label>
            <div class="ui checkbox">
                <label>提供程序</label>
                <input type="checkbox" ref="make_programs_available" onchange="{form_updated}">
            </div>
            <br>
            <div class="ui checkbox">
                <label>提供输入数据</label>
                <input type="checkbox" ref="make_input_data_available" onchange="{form_updated}">
            </div>
        </div>

        <!--  详细结果  -->
        <div class="field">
            <label>详细结果</label>
            <div class="ui checkbox">
                <label>启用详细结果</label>
                <input type="checkbox" ref="detailed_results" onchange="{form_updated}">
            </div>
            <sup>
                <a href="https://github.com/codalab/competitions-v2/wiki/Detailed-Results-and-Visualizations"
                   target="_blank"
                   data-tooltip="这是什么？">
                    <i class="grey question circle icon"></i>
                </a>
            </sup>
            <br>
            <div class="ui checkbox">
                <label>在提交面板中显示详细结果</label>
                <input type="checkbox" ref="show_detailed_results_in_submission_panel" onchange="{form_updated}">
            </div>
            <sup>
                <span data-tooltip="如果勾选且启用了详细结果，参与者可以在提交面板中看到详细结果"
                          data-inverted=""
                          data-position="bottom center">
                    <i class="help icon circle"></i>
                </span>
            </sup>
            <br>
            <div class="ui checkbox">
                <label>在排行榜中显示详细结果</label>
                <input type="checkbox" ref="show_detailed_results_in_leaderboard" onchange="{form_updated}">
            </div>
            <sup>
                <span data-tooltip="如果勾选且启用了详细结果，参与者可以在排行榜中看到详细结果"
                          data-inverted=""
                          data-position="bottom center">
                    <i class="help icon circle"></i>
                </span>
            </sup>
        </div>

        <!--  提交执行  -->
        <div class="field">
            <label>提交执行</label>
            <div class="ui checkbox">
                <label>自动运行提交</label>
                <input type="checkbox" ref="auto_run_submissions" onchange="{form_updated}">
            </div>
            <sup>
                <span data-tooltip="如果未勾选，主办方将需要手动运行每个提交"
                          data-inverted=""
                          data-position="bottom center">
                    <i class="help icon circle"></i>
                </span>
            </sup>
        </div>

        <!--  公开提交  -->
        <div class="field">
            <label>公开提交</label>
            <div class="ui checkbox">
                <label>参与者可以将提交设为公开</label>
                <input type="checkbox" ref="can_participants_make_submissions_public" onchange="{form_updated}">
            </div>
            <sup>
                <span data-tooltip="如果未勾选，参与者将无法在提交面板中将提交设为公开"
                          data-inverted=""
                          data-position="bottom center">
                    <i class="help icon circle"></i>
                </span>
            </sup>
        </div>


    </div>

    <script>
        var self = this
        self.fact_sheet_questions = []
        /*---------------------------------------------------------------------
         初始化
        ---------------------------------------------------------------------*/
        self.data = {}
        self.is_editing_competition = false
        // 暂时存储该值以便美观地显示给用户，后续可拆分成独立组件
        self.logo_file_name = ''

        self.one("mount", function () {
            // 设置占位符，这样可以多行显示
            $(self.refs.comp_fact_sheet).attr('placeholder', '{\n  "key": ["value1","value2",true,false]\n  "leave_blank_to_accept_any": ""\n}\n')
            self.markdown_editor = create_easyMDE(self.refs.comp_description)
            $('.ui.checkbox', self.root).checkbox({
                onChange: self.form_updated
            })

            // 显示已上传的 logo 文件名，当文件改变时更新
            $(self.refs.logo).change(function () {
                self.logo_file_name = self.refs.logo.value.replace(/\\/g, '/').replace(/.*\//, '')
                self.update()
                getBase64(this.files[0]).then(function (data) {
                    self.data['logo'] = JSON.stringify({file_name: self.logo_file_name, data: data})
                    self.form_updated()
                })
                self.form_updated()
            })

            $(self.refs.competition_type).dropdown({
                onChange: self.form_updated,
            })
            $(self.refs.queue).dropdown({
                // 注意：传递 `public=true`，使默认行为为用户可搜索公共队列
                apiSettings: {
                    url: `${URLS.API}queues/?search={query}&public=true`,
                    cache: false
                },
                clearable: true,
                minCharacters: 2,
                fields: {
                    remoteValues: 'results',
                    value: 'id',
                },
                maxResults: 5,
                onChange: self.form_updated
            })
            self.update()
        })

        /*---------------------------------------------------------------------
         方法
        ---------------------------------------------------------------------*/
        self.form_updated = function () {
            var is_valid = true

            // 注意：logo 不在此处，因为上传后转换为 base64 后才设置
            self.data["title"] = self.refs.title.value
            self.data["description"] = self.markdown_editor.value()
            self.data["queue"] = self.refs.queue.value
            self.data["enable_detailed_results"] = self.refs.detailed_results.checked
            self.data["show_detailed_results_in_submission_panel"] = self.refs.show_detailed_results_in_submission_panel.checked
            self.data["show_detailed_results_in_leaderboard"] = self.refs.show_detailed_results_in_leaderboard.checked
            self.data["auto_run_submissions"] = self.refs.auto_run_submissions.checked
            self.data["can_participants_make_submissions_public"] = self.refs.can_participants_make_submissions_public.checked
            self.data["make_programs_available"] = self.refs.make_programs_available.checked
            self.data["make_input_data_available"] = self.refs.make_input_data_available.checked
            self.data["docker_image"] = $(self.refs.docker_image).val()
            self.data["competition_type"] = $(self.refs.competition_type).dropdown('get value')
            self.data['fact_sheet'] = self.serialize_fact_sheet_questions()
            self.data['reward'] = $(self.refs.reward).val()
            self.data['contact_email'] = $(self.refs.contact_email).val()
            self.data['report'] = $(self.refs.report).val()
            if (self.data.fact_sheet === false){
                is_valid = false
            }

            // 当非编辑状态时，必须填写标题、docker 镜像和 logo（编辑时若未提供新 logo，则保留旧的）
            if (!self.data['title'] || !self.data['docker_image'] || (!self.data['logo'] && !self.is_editing_competition)) {
                is_valid = false
            }
            CODALAB.events.trigger('competition_is_valid_update', 'details', is_valid)

            if (is_valid) {
                // 如果没有 logo 数据且处于编辑状态，则置为 undefined（否则会发送错误数据至后端）
                if (!self.data['logo'] && self.is_editing_competition) {
                    self.data['logo'] = undefined
                }
                CODALAB.events.trigger('competition_data_update', self.data)
            }
        }

        self.add_question = (type) => {
            let current_id = 0
            if(self.fact_sheet_questions[0] !== undefined) {
                current_id = self.fact_sheet_questions[self.fact_sheet_questions.length - 1].id + 1
            }
            if(type === 'boolean'){
                self.fact_sheet_questions.push({
                    "id": current_id,
                    "label": "",
                    "type": "checkbox"
                })
            }
            else if(type === 'text'){
                self.fact_sheet_questions.push({
                    "id": current_id,
                    "label": "",
                    "type": "text"
                })
            }
            else if(type === 'selection'){
                self.fact_sheet_questions.push({
                    "id": current_id,
                    "label": "",
                    "type": "select",
                    "selection": []
                })
            }
            self.update()
            $(':input', self.refs.comp_fact_sheet).not('button').not('[readonly]').each(function (i, field) {
                this.addEventListener('keyup', self.form_updated)
            })
        }

        self.remove_question = function (id) {
            self.fact_sheet_questions = self.fact_sheet_questions.filter(q => q.id !== id)
            self.update()
            self.form_updated()
        }

        self.serialize_fact_sheet_questions = function (){
            let form = $(self.refs.comp_fact_sheet).children()
            let form_json = {}
            for(question of form){
                let q_serialized = $(question).find(":input").serializeArray()
                let question_key = q_serialized[1].value
                form_json[question_key] = {}
                if(q_serialized[0].value === "checkbox"){
                    form_json[question_key]['selection'] = [true, false]
                } else if(q_serialized[0].value === "text") {
                    form_json[question_key]['selection'] = ""
                }
                for(entry of q_serialized){
                    if(entry.name.split('-')[0] === 'selection') {
                        let selection = entry.value.split(',')
                        selection = selection.map(s => s.trim()).filter(s => s !== '')
                        form_json[question_key][entry.name.split('-')[0]] = selection
                    } else if (entry.name.split('-')[0] === 'key'){
                        // 检查键是否为空
                        if(!entry.value){
                            return false
                        }
                        form_json[question_key][entry.name.split('-')[0]] = entry.value
                    } else {
                        form_json[question_key][entry.name.split('-')[0]] = entry.value
                    }
                }
                if(form_json[question_key]['type'] === 'select' && form_json[question_key]['is_required'] === 'false'){
                    form_json[question_key]['selection'].unshift('')
                }
            }
            if(form_json.length === 0){
                return null
            }
            return form_json
        }

        self.filter_queues = function (filters) {
            filters = filters || {}
            _.defaults(filters, {
                search: $(self.refs.queue_search).val(),
                page: 1,
            })
            self.page = filters.page
            self.get_available_queues(filters)
        }


        /*---------------------------------------------------------------------
         事件
        ---------------------------------------------------------------------*/
        CODALAB.events.on('competition_loaded', function (competition) {
            self.is_editing_competition = true
            self.refs.title.value = competition.title
            self.markdown_editor.value(competition.description || '')

            // 文件路径类似 c:/fakepath/file_name.txt —— 只取 file_name.txt
            self.uploaded_logo_name = competition.logo.replace(/\\/g, '/').replace(/.*\//, '')
            self.uploaded_logo = competition.logo
            if (competition.queue) {
                $(self.refs.queue)
                    .dropdown('set text', competition.queue.name)
                    .dropdown('set value', competition.queue.id)
            }
            self.refs.detailed_results.checked = competition.enable_detailed_results
            self.refs.show_detailed_results_in_submission_panel.checked = competition.show_detailed_results_in_submission_panel
            self.refs.show_detailed_results_in_leaderboard.checked = competition.show_detailed_results_in_leaderboard
            self.refs.auto_run_submissions.checked = competition.auto_run_submissions
            self.refs.can_participants_make_submissions_public.checked = competition.can_participants_make_submissions_public
            self.refs.make_programs_available.checked = competition.make_programs_available
            self.refs.make_input_data_available.checked = competition.make_input_data_available
            $(self.refs.docker_image).val(competition.docker_image)
            $(self.refs.reward).val(competition.reward)
            $(self.refs.contact_email).val(competition.contact_email)
            $(self.refs.report).val(competition.report)
            if(competition.fact_sheet !== null){
                for(question in competition.fact_sheet){
                    var q_json = competition.fact_sheet[question]
                    q_json.id = self.fact_sheet_questions.length
                    if(q_json.type === "select"){
                        q_json.selection = q_json.selection.filter(s => s !== "")
                    }
                    self.fact_sheet_questions.push(q_json)
                }
            }
            self.update()
            self.form_updated()
            // 在这里设置下拉框选项，以免在 fact_sheet_questions 设置之前触发 on_change:form_updated()
            $(self.refs.competition_type).dropdown('set selected', competition.competition_type)
            // 表单变更事件
            $(':input', self.root).not('[type="file"]').not('button').not('[readonly]').each(function (i, field) {
                this.addEventListener('keyup', self.form_updated)
            })
        })
        CODALAB.events.on('update_codemirror', () => {
            self.markdown_editor.codemirror.refresh()
        })
    </script>
    <style>
        .fact-sheet-question {
            border: 1px solid #dcdcdcdc;
            background-color: white;
            padding: 1.5em;
        }
    </style>
</competition-details>
