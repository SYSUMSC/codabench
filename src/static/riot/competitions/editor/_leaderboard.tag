<competition-leaderboards>
    <div class="ui center aligned grid">
        <div class="row">
            <div class="fourteen wide column">
                <table class="ui padded table">
                    <thead>
                    <tr>
                        <th colspan="2">排行榜</th>
                    </tr>
                    </thead>
                    <tbody>
                    <tr each="{ board, index in leaderboards }">
                        <td>{ board.title }</td>
                        <td class="right aligned">
                            <a class="chevron">
                                <sorting-chevrons data="{ leaderboards }" index="{ index }"
                                                  onupdate="{ form_updated }"></sorting-chevrons>
                            </a>
                            <a class="icon-button"
                               onclick="{ edit.bind(this, index) }">
                                <i class="blue edit icon"></i>
                            </a>
                            <a class="icon-button"
                               onclick="{ delete_leaderboard.bind(this, index) }">
                                <i selenium="delete-column" class="red trash alternate outline icon"></i>
                            </a>
                        </td>
                    </tr>
                    <tr show="{leaderboards.length === 0}">
                        <td colspan="2" class="center aligned">
                            <em>尚未添加排行榜，至少需要一个排行榜！</em>
                        </td>
                    </tr>
                    </tbody>
                    <tfoot>
                    <tr>
                        <th colspan="2" class="right aligned">
                            <button if="{leaderboards.length === 0}" class="ui tiny inverted green icon button" onclick="{ add }">
                                <i selenium='add-leaderboard' class="add icon"></i> 添加排行榜
                            </button>
                            <button if="{leaderboards.length > 0}" disabled="disabled" class="ui tiny inverted green icon button disabled">
                                <i selenium='add-leaderboard' class="add icon"></i> 添加排行榜
                            </button>
                        </th>
                    </tr>
                    </tfoot>
                </table>
            </div>
        </div>
    </div>

    <div class="ui large modal" ref="modal">
        <i class="close icon"></i>
        <div class="header">
            排行榜表单
        </div>
        <div class="scrolling content">
            <div class="ui warning message" show="{!_.isEmpty(error_messages)}">
                <div class="header">
                    排行榜错误
                </div>
                <ul class="list">
                    <li each="{message in error_messages}">
                        { message }
                    </li>
                </ul>
            </div>
            <div ref="leaderboard_form" class="ui form">
                <input type="hidden" name="id" value="{_.get(selected_leaderboard, 'id', null)}">
                <div class="field">
                    <label>排行榜设置</label>
                    <div class="two fields">
                        <div class="field required">
                            <label>标题</label>
                            <input selenium="title1" name="title" value="{_.get(selected_leaderboard, 'title')}"
                                   onchange="{ modal_updated }">
                        </div>
                        <div class="field required">
                            <label>
                                键
                                <span data-tooltip="这是你将在评分程序中用于分配排行榜分数的键" data-inverted=""
                                      data-position="right center">
                                    <i class="help icon circle"></i>
                                </span>
                            </label>
                            <input selenium="key" name="key" value="{_.get(selected_leaderboard, 'key')}" onchange="{ modal_updated }">
                        </div>
                    </div>
                    <div class="field">
                        <div class="ui checkbox">
                            <input type="checkbox" ref="hidden_leaderboard">
                            <label>排行榜隐藏</label>
                        </div>
                    </div>
                </div>
                <div class="field" style="width: 50%; padding: 0 7px">
                    <label>提交规则</label>
                    <div class="ui fluid submission-rule selection dropdown">
                        <input type="hidden" name="submission_rule" ref="submission_rule" value="{_.get(selected_leaderboard, 'submission_rule', 'Add')}">
                        <div class="default text"></div>
                        <i class="dropdown icon"></i>
                        <div class="menu">
                            <div each="{rule in submission_rules}" class="item" data-value="{rule}">{rule.replaceAll("_", " ")}</div>
                        </div>
                    </div>
                </div>

                <table class="ui celled definition table">
                    <thead>
                    <tr>
                        <th width="125px"></th>
                        <th if="{_.isEmpty(columns)}"></th>
                        <th each="{ column, index in columns || [] }" style="min-width: 200px;">
                            <input type="text" class="ui field" name="title_{index}" value="{_.get(column, 'title')}" onchange="{ update_leaderboard }">
                            <input type="hidden" name="id_{index}" value="{_.get(column, 'id')}">
                        </th>
                    </tr>
                    </thead>

                    <tbody>
                    <tr>
                        <td>主要列</td>
                        <td if="{_.isEmpty(columns)}" rowspan="5"><em>尚未添加列！</em></td>
                        <td each="{ column, index in columns || [] }" class="center aligned">
                            <input type="radio" name="primary_index" data-index="{index}" checked="{ index === _.get(selected_leaderboard, 'primary_index') }">
                        </td>
                    </tr>
                    <tr>
                        <td>计算</td>
                        <td each="{ column, index in columns || [] }">
                            <div class="ui fluid computation selection dropdown">
                                <input type="hidden" name="computation_{index}" value="{column.computation || 'none'}" onchange="{ modal_updated }">
                                <div class="default text"></div>
                                <i class="dropdown icon"></i>
                                <div class="menu">
                                    <div class="item" data-index="{index}" data-value="none">无</div>
                                    <div class="item" data-index="{index}" data-value="avg">平均值</div>
                                    <div class="item" data-index="{index}" data-value="sum">求和</div>
                                    <div class="item" data-index="{index}" data-value="min">最小值</div>
                                    <div class="item" data-index="{index}" data-value="max">最大值</div>
                                </div>
                            </div>
                            <label if="{column.computation}" style="display: block; padding-top: 10px;">应用于:</label>
                            <select class="ui fluid multiselect index_{index} dropdown"
                                    if="{column.computation}"
                                    multiple=""
                                    id="computation_indexes_{index}"
                                    name="computation_indexes_{index}"
                                    onchange="{ modal_updated }">
                                <option each="{ inner_column, inner_index in columns }"
                                        if="{ inner_index !== index }"
                                        selected="{_.includes(column.computation_indexes, inner_index.toString())}"
                                        value="{ inner_index }"> { inner_column.title }
                                </option>
                            </select>
                        </td>
                    </tr>
                    <tr>
                        <td>
                            排序
                            <span data-tooltip="升序: 越小越好 -- 降序: 越大越好" data-position="right center"><i class="circle question icon"></i></span>
                        </td>
                        <td each="{ column, index in columns || [] }">
                            <div class="ui fluid sorting selection dropdown">
                                <input type="hidden" name="sorting_{index}" value="{column.sorting || 'desc'}">
                                <div class="default text">排序</div>
                                <i class="dropdown icon"></i>
                                <div class="menu">
                                    <div class="item" data-value="desc">降序</div>
                                    <div class="item" data-value="asc">升序</div>
                                </div>
                            </div>
                        </td>
                    </tr>
                    <tr>
                        <td>列键 <span style="color: red;">*</span></td>
                        <td each="{ column, index in columns || [] }">
                            <input selenium="column-key" type="text" class="ui field" name="column_key_{index}" value="{_.get(column, 'key')}" onchange="{ modal_updated }">
                        </td>
                    </tr>
                    <tr>
                        <td>列精度 <span style="color: red;">*</span></td>
                        <td each="{ column, index in columns || [] }">
                            <input selenium="column-precision" type="number" class="ui field" name="column_precision_{index}" value="{_.get(column, 'precision') || 2}" min="1" max="10" onchange="{ modal_updated }">
                        </td>
                    </tr>
                    <tr>
                        <td>隐藏</td>
                        <td each="{ column, index in columns || [] }" style="text-align: center;">
                            <input selenium="hidden" type="checkbox" ref="hidden_{index}" checked="{column.hidden}" onchange="{ modal_updated }">
                        </td>
                    </tr>
                    <tr>
                        <td></td>
                        <td each="{ column, index in columns || [] }" class="center aligned">
                            <a onclick="{move_column.bind(this, index, -1)}" class="icon-button"><i class="chevron left icon {disabled: index === 0 }"></i></a>
                            <a class="icon-button" onclick="{ delete_column.bind(this, index) }"><i class="red trash alternate outline icon"></i></a>
                            <a onclick="{move_column.bind(this, index, 1)}" class="icon-button" ><i class="chevron right icon {disabled: index + 1 === _.get(selected_leaderboard, 'columns.length', 0) }"></i></a>
                        </td>
                    </tr>
                    </tbody>
                </table>
            </div>
        </div>
        <div class="actions">
            <div selenium="add-column" class="ui inverted green icon button" onclick="{ add_column }"><i class="ui plus icon"></i> 添加列</div>
            <div class="ui button" onclick="{ close_modal }">取消</div>
            <div selenium="save3" class="ui button primary {disabled: !modal_is_valid}" onclick="{ save }">保存</div>
        </div>
    </div>

    <script>
        var self = this

        /*---------------------------------------------------------------------
         初始化
        ---------------------------------------------------------------------*/
        self.leaderboards = []
        self.selected_leaderboard_index = undefined
        self.selected_leaderboard = undefined
        self.selected_submission_rule = undefined
        self.columns = []
        self.modal_is_valid = false
        self.error_messages = []
        self.submission_rules = [
            "Add",
            "Add_And_Delete",
            "Add_And_Delete_Multiple",
            "Force_Last",
            "Force_Latest_Multiple",
            "Force_Best",
        ]
        self.on('mount', () => {
            $(self.refs.modal).modal({
                closable: false,
                onHidden: self.clear_form,
                onShow: self.initialize_dropdowns
            })
        })

        /*---------------------------------------------------------------------
         方法
        ---------------------------------------------------------------------*/
        self.initialize_dropdowns = function () {
            $('.ui.sorting.dropdown').dropdown()
            $('.ui.multiselect.dropdown').dropdown()
            $('.ui.submission-rule.dropdown').dropdown({
                onChange: (value, text, element) => {
                    self.change_submission_rule(value)
                    self.update()
                }
            })
            $('.ui.computation.dropdown').dropdown({
                onChange: (value, text, element) => {
                    let index = element.data().index
                    if (value === 'none') {
                        self.columns[index].computation = null
                        self.update()
                        $(`.ui.multiselect.index_${index}.dropdown`)
                            .dropdown('clear')
                            // dropdown('hide') 和 ('remove visible') 无效，需通过 css 强制隐藏
                            .css('display', 'none')
                    } else {
                        self.columns[index].computation = value
                        self.update()
                        $('.ui.multiselect.dropdown').dropdown({
                            onChange: () => {
                                self.update_leaderboard()
                            }
                        })
                    }
                }
            })
        }


        self.add = function () {
            self.selected_leaderboard = {
                primary_index: 0,
            }
            self.columns = []
            self.add_column()
            self.show_modal()
        }

        self.edit = function (index) {
            self.selected_leaderboard_index = index
            // 克隆排行榜，避免直接引用原对象
            self.selected_leaderboard = _.cloneDeep(self.leaderboards[index])
            self.refs.hidden_leaderboard.checked = self.selected_leaderboard.hidden
            self.columns = self.selected_leaderboard.columns || []
            self.update()
            self.show_modal()
        }

        self.change_submission_rule = function (rule) {
            self.selected_submission_rule = rule
        }

        self.show_modal = function () {
            $(self.refs.modal).modal('show')
            self.modal_updated()
        }

        self.close_modal = function () {
            $(self.refs.modal).modal('hide')
        }

        self.delete_leaderboard = function (index) {
            if (confirm("你确定要删除吗？")) {
                self.leaderboards.splice(index, 1)
                self.update()
                self.form_updated()
            }
        }

        self.save = function () {
            if (self.selected_leaderboard_index >= 0) {
                self.leaderboards[self.selected_leaderboard_index] = self.get_leaderboard_data()
            } else {
                self.leaderboards.push(self.get_leaderboard_data())
            }
            self.form_updated()
            self.close_modal()
            self.update()
            self.selected_submission_rule = undefined
        }

        self.clear_form = function () {
            self.selected_leaderboard_index = undefined
            self.selected_leaderboard = undefined
            self.columns = []
            self.update()
        }

        self.modal_updated = function () {
            self.modal_is_valid = self.validate_leaderboard(self.get_leaderboard_data())
            self.update()
        }

        self.form_updated = function () {
            let is_valid = true

            if (_.isEmpty(self.leaderboards)) {
                is_valid = false
            } else if (_.some(self.leaderboards, leaderboard => _.isEmpty(leaderboard.columns))) {
                is_valid = false
            } else {
                _.forEach(self.leaderboards, leaderboard => {
                    if (is_valid) {
                        if (!self.validate_leaderboard(leaderboard)) {
                            is_valid = false
                        }
                    }
                })
            }

            CODALAB.events.trigger('competition_is_valid_update', 'leaderboards', is_valid)

            if (is_valid) {
                CODALAB.events.trigger('competition_data_update', {leaderboards: self.leaderboards})
            }
            return is_valid
        }

        self.validate_leaderboard = function (leaderboard) {
            self.error_messages = []
            let is_valid = true
            if (!leaderboard.key || !leaderboard.title) {
                is_valid = false
            }
            _.forEach(leaderboard.columns, column => {
                if (!column.key || !column.title) {
                    is_valid = false
                } else if (column.computation) {
                    if (_.isEmpty(column.computation_indexes)) {
                        is_valid = false
                    } else {
                        let indexes = _.map(column.computation_indexes, index => parseInt(index))
                        _.forEach(indexes, index => {
                            let reference_column = leaderboard.columns[index]
                            if (_.includes(_.get(reference_column, 'computation_indexes', []), column.index.toString())) {
                                is_valid = false
                                self.error_messages.push(`计算引用循环发生在列索引: ${_.join(_.sortBy([reference_column.index, column.index]), ', ')}.`)
                            }
                        })
                    }
                }
            })
            self.error_messages = _.uniq(self.error_messages)
            return is_valid
        }

        self.get_leaderboard_data = function () {
            let data = get_form_data(self.refs.leaderboard_form)
            let leaderboard = {
                id: data.id,
                title: data.title,
                key: data.key,
                precision : (data.precision === undefined) ? 2 : data.precision ,
                submission_rule: self.selected_submission_rule,
                hidden: self.refs.hidden_leaderboard.checked,
                primary_index: _.get($('input[name=primary_index]:checked').data(), 'index', 0),
                columns: _.map(_.range(_.get(self.selected_leaderboard, 'columns.length', 0)), i => {
                    let column = {
                        index: i,
                        title: _.get(data, `title_${i}`),
                        key: _.get(data, `column_key_${i}`),
                        precision: _.get(data, `column_precision_${i}`),
                        sorting: _.get(data, `sorting_${i}`),
                        hidden: self.refs[`hidden_${i}`].checked,
                    }
                    let id = _.get(data, `id_${i}`)
                    if (id) {
                        column.id = id
                    }
                    let computation = _.get(data, `computation_${i}`)
                    if (computation !== 'none') {
                        column.computation = computation
                        column.computation_indexes = _.get(data, `computation_indexes_${i}`)
                    } else {
                        column.computation = null
                        column.computation_indexes = null
                    }
                    return column
                })
            }
            return leaderboard
        }

        self.update_leaderboard = function () {
            self.selected_leaderboard = self.get_leaderboard_data()
            self.columns = self.selected_leaderboard.columns
            self.update()
            self.initialize_dropdowns()
            self.modal_updated()
        }

        self.add_column = function () {
            self.columns.push({title: '新列'})
            self.update()
            _.delay(() => self.update_leaderboard(), 10)
        }

        self.delete_column = function (index) {
            _.pullAt(self.columns, index)
            self.update()
            self.update_leaderboard()
        }

        self.move_column = function (index, offset) {
            let from_index = index
            let to_index = index + offset
            let data_to_move = self.columns[from_index]
            self.columns.splice(from_index, 1)
            self.columns.splice(to_index, 0, data_to_move)
            self.columns = _.map(self.columns, (column, i) => {
                column.index = i
                return column
            })
            // computation indexes 是以字符串形式保存的索引列表
            from_index = from_index.toString()
            to_index = to_index.toString()
            self.columns = _.map(self.columns, column => {
                let comp_indexes = _.get(column, 'computation_indexes')
                if (comp_indexes) {
                    let push_to = false
                    let push_from = false
                    if (_.includes(comp_indexes, from_index)) {
                        _.pull(column.computation_indexes, from_index)
                        push_to = true
                    }
                    if (_.includes(comp_indexes, to_index)) {
                        _.pull(column.computation_indexes, to_index)
                        push_from = true
                    }
                    if (push_from) {
                        column.computation_indexes.push(from_index)
                    }
                    if (push_to) {
                        column.computation_indexes.push(to_index)
                    }
                }
                return column
            })
            self.update()
            self.update_leaderboard()
        }

        /*---------------------------------------------------------------------
         事件
        ---------------------------------------------------------------------*/
        CODALAB.events.on('competition_loaded', function(competition){
            self.leaderboards = competition.leaderboards
            self.form_updated()
        })
    </script>
    <style scoped type="text/stylus">
        a.icon-button:hover
            cursor pointer
    </style>
</competition-leaderboards>
