<task-management>
    <div class="ui icon input">
        <input type="text" placeholder="按名称搜索..." ref="search" onkeyup="{filter.bind(this, undefined)}">
        <i class="search icon"></i>
    </div>
    <div class="ui checkbox" onclick="{ filter.bind(this, undefined) }">
        <label>显示公共任务</label>
        <input type="checkbox" ref="public">
    </div>
    <div class="ui blue right floated labeled icon button" onclick="{ show_upload_task_modal }"><i class="upload icon"></i>
        上传任务
    </div>
    <div selenium="create-task" class="ui green right floated labeled icon button" onclick="{ show_modal }"><i class="add circle icon"></i>
        创建任务
    </div>
    <button class="ui red right floated labeled icon button {disabled: marked_tasks.length === 0}" onclick="{delete_tasks}">
        <i class="icon delete"></i>
        删除选中任务
    </button>

    <table id="tasksTable" class="ui {selectable: tasks.length > 0} celled compact sortable table">
        <thead>
        <tr>
            <th>名称</th>
            <th>描述</th>
            <th>创建者</th>
            <th width="50px" class="no-sort">使用中</th>
            <th width="50px" class="no-sort">公开</th>
            <th width="100px" class="no-sort">操作</th>
            <th width="25px" class="no-sort"></th>
        </tr>
        </thead>
        <tbody>
        <tr each="{ task in tasks }" class="task-row">
            <td onclick="{show_detail_modal.bind(this, task)}">{ task.name }</td>
            <td onclick="{show_detail_modal.bind(this, task)}">{ task.description }</td>
            <td><a href="/profiles/user/{task.created_by}/" target=_blank>{task.owner_display_name}</a></td>
            <td>
                <i class="checkmark box icon green" show="{task.is_used_in_competitions}"></i>
            </td>
            <td class="center aligned">
                <i class="checkmark box icon green" show="{ task.is_public }"></i>
            </td>
            <td>
                <div if="{ task.created_by == CODALAB.state.user.username }">
                    <button class="mini ui button blue icon" onclick="{show_edit_modal.bind(this, task)}">
                        <i class="icon pencil"></i>
                    </button>
                    <button class="mini ui button red icon" onclick="{ delete_task.bind(this, task) }">
                        <i class="icon trash"></i>
                    </button>
                </div>
            </td>
            <td class="center aligned">
                <div class="ui fitted checkbox" if="{ task.created_by == CODALAB.state.user.username }">
                    <input type="checkbox" name="delete_checkbox" onclick="{ mark_task_for_deletion.bind(this, task) }">
                    <label></label>
                </div>
            </td>
        </tr>

        <tr if="{tasks.length === 0}">
            <td class="center aligned" colspan="7">
                <em>暂无任务！</em>
            </td>
        </tr>
        </tbody>
        <tfoot>

        <!-- 分页 -->
        <tr if="{tasks.length > 0}">
            <th colspan="7">
                <div class="ui right floated pagination menu" if="{tasks.length > 0}">
                    <a show="{!!_.get(pagination, 'previous')}" class="icon item" onclick="{previous_page}">
                        <i class="left chevron icon"></i>
                    </a>
                    <div class="item">
                        <label>{page}</label>
                    </div>
                    <a show="{!!_.get(pagination, 'next')}" class="icon item" onclick="{next_page}">
                        <i class="right chevron icon"></i>
                    </a>
                </div>
            </th>
        </tr>
        </tfoot>
    </table>

    <!-- 任务详情模态框 -->
    <div class="ui modal" ref="detail_modal">
        <div class="header">
            {selected_task.name}
            <button class="ui right floated primary button" onclick="{ open_share_modal.bind(this) }">
                分享任务
                <i class="share square icon right"></i>
            </button>
        </div>
        <div class="content">
            <h4>{selected_task.description}</h4>
            <div class="ui divider" show="{selected_task.description}"></div>
            <div><strong>创建者：</strong> <a href="/profiles/user/{selected_task.created_by}/" target=_blank>{selected_task.owner_display_name}</a></div>
            <div><strong>上传时间：</strong>  {timeSince(Date.parse(selected_task.created_when)) } ago</div>
            <div if="{selected_task.created_by === CODALAB.state.user.username}">
                <strong>共享对象：</strong> { selected_task.shared_with.join(', ') }
            </div>
            <div if="{selected_task.created_by === CODALAB.state.user.username}">
                <strong>用于竞赛：</strong>
                <ul show="{selected_task.competitions.length > 0}">
                    <li each="{comp in selected_task.competitions}">
                        <a href="{URLS.COMPETITION_DETAIL(comp.id)}" target="_blank">{comp.title}</a>
                    </li>
                </ul>
            </div>
            <div><strong>标识：</strong> {selected_task.key}</div>
            <div><strong>是否已验证
                <span data-tooltip="任务在其解决方案之一成功运行后即被视为已验证">
                    <i class="question circle icon"></i>
                </span>：</strong> {selected_task.validated ? "是" : "否"}</div>
            <div><strong>是否公开：</strong> {selected_task.is_public ? "是" : "否"}</div>
            <div
                if="{selected_task.created_by === CODALAB.state.user.username}"
                 class="ui right floated small green icon button"
                 onclick="{toggle_task_is_public}">
                <i class="share icon"></i> {selected_task.is_public ? '设为私有' : '设为公开'}
            </div>
            <div class="ui secondary pointing green two item tabular menu">
                <div class="active item" data-tab="files">文件</div>
                <div class="item" data-tab="solutions">解决方案</div>
            </div>
            <div class="ui active tab" data-tab="files">
                <table class="ui table">
                    <thead>
                    <tr>
                        <th>类型</th>
                        <th>名称</th>
                        <th></th>
                    </tr>
                    </thead>
                    <tbody>
                    <tr each="{file in file_types}" if="{selected_task[file]}">
                        <td>{selected_task[file].type}</td>
                        <td>{selected_task[file].name}</td>
                        <td class="collapsing">
                            <span data-tooltip="下载此数据集">
                                <a href="{URLS.DATASET_DOWNLOAD(selected_task[file].key)}">
                                    <i class="download green icon"></i>
                                </a>
                            </span>
                        </td>
                    </tr>
                    </tbody>
                </table>
            </div>
            <div class="ui tab" data-tab="solutions">
                <table class="ui table">
                    <thead>
                    <tr>
                        <th>解决方案</th>
                    </tr>
                    </thead>
                    <tbody>
                    <tr each="{solution in selected_task.solutions}">
                        <td><a href="{URLS.DATASET_DOWNLOAD(solution.data)}">{solution.name}</a></td>
                    </tr>
                    </tbody>
                </table>
            </div>
        </div>
        <div class="actions">
            <button class="ui cancel button">关闭</button>
        </div>
    </div>

    <!-- 上传任务模态框 -->
    <div ref="upload_task_modal" class="ui modal">
        <div class="header">上传任务</div>

        <div class="content">

            <form class="ui form coda-animated {error: errors}" ref="upload_form">
                <p>
                在此上传任务的 zip 文件以创建新任务。有关帮助，请参阅文档 <a href="https://github.com/codalab/codabench/wiki/Resource-Management#upload-a-task" target="_blank">这里</a>。
                </p>

                <input-file name="data_file" ref="data_file"
                            accept=".zip"></input-file>
            </form>

            <div class="ui indicating progress" ref="progress">
                <div class="bar">
                    <div class="progress">{ upload_progress }%</div>
                </div>
            </div>

        </div>
        <div class="actions">
            <button class="ui blue icon button" onclick="{check_upload_task_form}">
                <i class="upload icon"></i>
                上传
            </button>
            <button class="ui basic red button" onclick="{close_upload_task_modal}">取消</button>
        </div>
    </div>

    <!-- 创建任务模态框 -->
    <div class="ui modal" ref="modal">
        <div class="header">
            创建任务
        </div>
        <div class="content">
            <div class="ui pointing menu">
                <div class="active item modal-item" data-tab="details">详细信息</div>
                <div class="item modal-item" data-tab="data">数据集和程序</div>
            </div>
            <form class="ui form" ref="form">
                <div class="ui active tab" data-tab="details">
                    <div class="required field">
                        <label>名称</label>
                        <input selenium="name2" name="name" placeholder="名称" ref="name" onkeyup="{ form_updated }">
                    </div>
                    <div class="required field">
                        <label>描述</label>
                        <textarea selenium="task-desc" rows="4" name="description" placeholder="描述" ref="description"
                                  onkeyup="{ form_updated }"></textarea>
                    </div>
                </div>
                <div class="ui tab" data-tab="data">
                    <div>
                        <div class="two fields" data-no-js>
                            <div class="field {required: file_field === 'scoring_program'}"
                                 each="{file_field in ['scoring_program', 'ingestion_program']}">
                                <label>
                                    {_.startCase(file_field)}
                                </label>
                                <div class="ui fluid left icon labeled input search dataset" data-name="{file_field}">
                                    <i class="search icon"></i>
                                    <input  type="text" class="prompt" id="{file_field}">
                                    <div selenium="scoring-program" class="results"></div>
                                </div>
                            </div>
                        </div>

                        <div class="two fields" data-no-js>
                            <div class="field" each="{file_field in ['reference_data', 'input_data']}">
                                <label>
                                    {_.startCase(file_field)}
                                </label>
                                <div class="ui fluid left icon labeled input search dataset" data-name="{file_field}">
                                    <i class="search icon"></i>
                                    <input type="text" class="prompt">
                                    <div class="results"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </form>
        </div>


        <div class="ui modal" ref="share_modal">
            <div class="ui header">共享</div>
            <div class="content">
                <select class="ui fluid search multiple selection dropdown" multiple id="share_search">
                    <i class="dropdown icon"></i>
                    <div class="default text">选择要共享的用户</div>
                    <div class="menu">
                    </div>
                </select>
            </div>
            <div class="actions">
                <div class="ui positive button">共享</div>
                <div class="ui cancel button">取消</div>
            </div>
        </div>
        <div class="actions">
            <div selenium="save-task" class="ui primary button {disabled: !modal_is_valid}" onclick="{ create_task }">创建</div>
            <div class="ui basic red cancel button">取消</div>
        </div>
    </div>

    <!-- 编辑任务模态框 -->
    <div class="ui modal" ref="edit_modal">
        <!-- 模态框标题 -->
        <div class="header">
            更新任务
        </div>
        <div class="content">
            <!-- 模态框选项卡 -->
            <div class="ui pointing menu">
                <div class="active item modal-item" data-tab="edit_details">详细信息</div>
                <div class="item modal-item" data-tab="edit_data">数据集和程序</div>
            </div>
            <!-- 模态框表单 -->
            <form class="ui form" ref="edit_form">
                <!-- 任务详情选项卡 -->
                <div class="ui active tab" data-tab="edit_details">
                    <!-- 任务名称 -->
                    <div class="required field">
                        <label>名称</label>
                        <input name="edit_name" placeholder="名称" ref="edit_name" value="{selected_task.name}" onkeyup="{ edit_form_updated }">
                    </div>
                    <!-- 任务描述 -->
                    <div class="required field">
                        <label>描述</label>
                        <textarea rows="4" name="edit_description" placeholder="描述" ref="edit_description"
                                  value="{selected_task.description}" onkeyup="{ edit_form_updated }"></textarea>
                    </div>
                </div>
                <!-- 任务数据集选项卡 -->
                <div class="ui tab" data-tab="edit_data">
                    <div>
                        <div class="two fields" data-no-js>
                            <!-- 评分程序 -->
                            <div class="field required">
                                <label>评分程序</label>
                                <div class="ui fluid left icon labeled input search dataset" data-name="scoring_program">
                                    <i class="search icon"></i>
                                    <input type="text" class="prompt" id="edit_scoring_program" value="{selected_task.scoring_program?.name  || ''}" name="edit_scoring_program">
                                    <div class="results"></div>
                                </div>
                            </div>
                            <!-- 导入程序 -->
                            <div class="field">
                                <label>导入程序</label>
                                <div class="ui fluid left icon labeled input search dataset" data-name="ingestion_program">
                                    <i class="search icon"></i>
                                    <input  type="text" class="prompt" id="edit_ingestion_program" value="{selected_task.ingestion_program?.name  || ''}" name="edit_ingestion_program">
                                    <div class="results"></div>
                                </div>
                            </div>
                        </div>
                        <div class="two fields" data-no-js>
                            <!-- 参考数据 -->
                            <div class="field">
                                <label>参考数据</label>
                                <div class="ui fluid left icon labeled input search dataset" data-name="reference_data">
                                    <i class="search icon"></i>
                                    <input  type="text" class="prompt" id="edit_reference_data" value="{selected_task.reference_data?.name || ''}" name="edit_reference_data">
                                    <div class="results"></div>
                                </div>
                            </div>
                            <!-- 输入数据 -->
                            <div class="field">
                                <label>输入数据</label>
                                <div class="ui fluid left icon labeled input search dataset" data-name="input_data">
                                    <i class="search icon"></i>
                                    <input  type="text" class="prompt" id="edit_input_data" value="{selected_task.input_data?.name  || ''}" name="edit_input_data">
                                    <div class="results"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </form>
        </div>
        <!-- 警告信息 -->
        <div class="content">
            <div class="ui yellow message">
                注意：如果需要，队伍者有责任重新运行更新后的任务的提交。
            </div>
        </div>
        <div class="actions">
            <div class="ui primary button {disabled: !edit_modal_is_valid}" onclick="{ update_task }">更新</div>
            <div class="ui basic red cancel button">取消</div>
        </div>
    </div>

    <script>

        var self = this
        self.mixin(ProgressBarMixin)

        /*---------------------------------------------------------------------
         初始化
        ---------------------------------------------------------------------*/

        self.marked_tasks = []
        self.tasks = []
        self.form_datasets = {}
        self.selected_task = {}
        self.page = 1
        self.file_types = [
            'input_data',
            'reference_data',
            'scoring_program',
            'ingestion_program'
        ]

        self.upload_progress = undefined


        self.one("mount", function () {
            self.update_tasks()
            $(".ui.checkbox", self.root).checkbox()
            $('#tasksTable').tablesort()
            $('.ui.search.dataset', self.root).each(function (i, item) {
                $(item)
                    .search({
                        apiSettings: {
                            url: URLS.API + 'datasets/?search={query}&type=' + (item.dataset.name || ""),
                            onResponse: function (data) {
                                let results = _.map(data.results, result => {
                                    result.description = result.description || ''
                                    return result
                                })

                                return {results: results}
                            }
                        },
                        preserveHTML: false,
                        minCharacters: 2,
                        fields: {
                            title: 'name'
                        },
                        cache: false,
                        maxResults: 4,
                        onSelect: function (result, response) {
                            // 暂时存储选中的数据集信息，保存时再获取
                            self.form_datasets[item.dataset.name] = result.key
                            self.form_updated()
                        }
                    })
            })

            $('#share_search').dropdown({
                apiSettings: {
                    url: `${URLS.API}user_lookup/?q={query}`,
                },
                clearable: true,
                preserveHTML: false,
                fields: {
                    title: 'name',
                    value: 'id',
                },
                cache: false,
                maxResults: 5,
            })

            $(self.refs.share_modal).modal({
                onApprove: function () {
                    let users = $('#share_search').dropdown('get value')
                    CODALAB.api.share_task(self.selected_task.id, {shared_with: users})
                        .done((data) => {
                            toastr.success('任务已共享')
                            $('#share_search').dropdown('clear')
                            CODALAB.api.get_task(self.selected_task.id)
                                .done((data) => {
                                    _.forEach(self.tasks, (task) => {
                                        if (task.id === self.selected_task.id) {
                                            task.shared_with = data.shared_with
                                            self.update()
                                            return false
                                        }
                                    })
                                })
                        })
                        .fail((response) => {
                            toastr.error('发生错误')
                            $('#share_search').dropdown('clear')
                            return true
                        })
                }

            })
        })

        /*---------------------------------------------------------------------
         模态框方法
        ---------------------------------------------------------------------*/

        self.show_upload_task_modal = () => {
            self.reset_upload_task_input()
            $(self.refs.upload_task_modal).modal('show')
        }
        self.close_upload_task_modal = () => {
            $(self.refs.upload_task_modal).modal('hide')
            self.reset_upload_task_input()
        }
        self.reset_upload_task_input = () => {
            // 重置文件输入
            $('input-file[ref="data_file"]').find("input").val('')
            // 重置上传进度
            self.hide_progress_bar()
        }
        self.show_modal = () => {
            $('.menu .item', self.root).tab('change tab', 'details')
            self.form_datasets = {}
            $(self.refs.modal).modal('show')

        }

        self.close_modal = () => {
            $(self.refs.modal).modal('hide')
            self.clear_form()
        }

        self.clear_form = () => {
            $(':input', self.refs.form)
                .not('[type="file"]')
                .not('button')
                .not('[readonly]').each(function (i, field) {
                $(field).val('')
            })
            self.form_datasets = {}
            self.modal_is_valid = false
        }

        self.check_upload_task_form = () => {

            var data_file = self.refs.data_file.refs.file_input.value

            if(data_file === undefined || !data_file.endsWith('.zip')) {
                toastr.warning("请选择一个 .zip 文件进行上传")
                self.reset_upload_task_input()
                return
            }

            self.prepare_upload(self.upload_task)()
        }

        self.upload_task = () => {

            // 重置上传进度
            self.file_upload_progress_handler(undefined)

            // 从输入中获取选中的文件
            var data_file = self.refs.data_file.refs.file_input.files[0]

            // 检查文件是否有效
            if(data_file === undefined || !data_file.name.endsWith('.zip')) {
                toastr.warning("请选择一个 .zip 文件进行上传")
                return
            }

            // 调用 API 函数上传文件并监听进度
            CODALAB.api.upload_task(data_file, self.file_upload_progress_handler)
                .then(function () {
                    toastr.success("任务上传成功")
                    setTimeout(function () {
                        CODALAB.events.trigger('reload_quota_cleanup')
                        CODALAB.events.trigger('reload_datasets')
                        self.close_upload_task_modal()
                        self.update_tasks()
                    }, 500)

                })
                .catch(function (error) {
                    toastr.error("任务上传失败：" + error.responseJSON.error)
                    self.hide_progress_bar()
                })


        }

        self.create_task = () => {
            let data = get_form_data($(self.refs.form))
            _.assign(data, self.form_datasets)
            data.created_by = CODALAB.state.user.id
            CODALAB.api.create_task(data)
                .done((response) => {
                    toastr.success('任务创建成功')
                    self.close_modal()
                    self.update_tasks()
                    CODALAB.events.trigger('reload_quota_cleanup')
                })
                .fail((response) => {
                    toastr.error('创建任务失败')
                })
        }

        self.toggle_task_is_public = () => {
            let message = self.selected_task.is_public
                ? '您确定要将此任务设为私有吗？设为私有后将不再对其他用户可见。'
                : '您确定要将此任务设为公开吗？设为公开后将对所有人可见。'
            if (confirm(message)) {
                CODALAB.api.update_task(self.selected_task.id, {id: self.selected_task.id, is_public: !self.selected_task.is_public})
                    .done(data => {
                        toastr.success('任务已更新')
                        self.selected_task = data
                        self.update()
                    })
                    .fail(resp => {
                        toastr.error(resp.responseJSON['is_public'])
                    })
            }
        }

        self.form_updated = () => {
            self.modal_is_valid = $(self.refs.name).val() && $(self.refs.description).val() && self.form_datasets.scoring_program
            self.update()
        }

        self.show_detail_modal = (task, e) => {
            // 如果点击的是复选框，则不弹出详情模态框
            if (e.target.type === 'checkbox') {
                return
            }
            CODALAB.api.get_task(task.id)
                .done((data) => {
                    self.selected_task = data
                    self.update()
                })
            $(self.refs.detail_modal).modal('show')
        }

        /*---------------------------------------------------------------------
         更新任务方法
        ---------------------------------------------------------------------*/

        self.show_edit_modal = (task, e) => {
            // 从 API 获取任务数据
            CODALAB.api.get_task(task.id)
                .done((data) => {
                    self.selected_task = data
                    self.update()

                    // 清空表单数据集
                    // 并插入任务中已有的数据集键值
                    self.form_datasets = {}
                    if(self.selected_task.ingestion_program !== null){
                        self.form_datasets['ingestion_program'] = self.selected_task.ingestion_program.key
                    }
                    if(self.selected_task.scoring_program !== null){
                        self.form_datasets['scoring_program'] = self.selected_task.scoring_program.key
                    }
                    if(self.selected_task.reference_data !== null){
                        self.form_datasets['reference_data'] = self.selected_task.reference_data.key
                    }
                    if(self.selected_task.input_data !== null){
                        self.form_datasets['input_data'] = self.selected_task.input_data.key
                    }

                    // 调用更新表单方法以启用/禁用更新按钮
                    self.edit_form_updated()

                    // 显示编辑任务模态框
                    $(self.refs.edit_modal).modal('show')

                })
        }

        self.close_edit_modal = () => {
            $(self.refs.edit_modal).modal('hide')
            self.clear_edit_form()
        }

        self.edit_form_updated = () => {
            self.edit_modal_is_valid = $(self.refs.edit_name).val() && $(self.refs.edit_description).val()
            self.update()
        }

        self.clear_edit_form = () => {
            $(':input', self.refs.edit_form)
                .not('[type="file"]')
                .not('button')
                .not('[readonly]').each(function (i, field) {
                $(field).val('')
            })
            self.form_datasets = {}
            self.edit_modal_is_valid = false
        }
        self.update_task = () => {
            // 从编辑表单中获取数据
            let data = get_form_data($(self.refs.edit_form))

            // 当评分程序为空时提示错误
            if(data.edit_scoring_program == ""){
                toastr.error('任务必须包含评分程序！')
                return
            }

            // 替换数据对象中的属性名称
            data.name = data.edit_name;
            data.description = data.edit_description;

            // 如果未移除导入程序，则添加表单中的新导入程序
            if(data.edit_ingestion_program != ""){
                data.ingestion_program = self.form_datasets.ingestion_program
            }
            // 如果未移除输入数据，则添加表单中的新输入数据
            if(data.edit_input_data != ""){
                data.input_data = self.form_datasets.input_data
            }
            // 如果未移除参考数据，则添加表单中的新参考数据
            if(data.edit_reference_data != ""){
                data.reference_data = self.form_datasets.reference_data
            }
            // 添加表单中的评分程序到数据
            data.scoring_program = self.form_datasets.scoring_program

            // 删除旧的属性名称
            delete data.edit_name
            delete data.edit_description
            delete data.edit_ingestion_program
            delete data.edit_scoring_program
            delete data.edit_input_data
            delete data.edit_reference_data

            task_id = self.selected_task.id
            CODALAB.api.update_task(task_id, data)
                .done((response) => {
                    toastr.success('任务已更新')
                    self.close_edit_modal()
                    self.update_tasks()
                    CODALAB.events.trigger('reload_quota_cleanup')
                })
                .fail((response) => {
                    toastr.error('更新任务失败')
                })
        }

        /*---------------------------------------------------------------------
         表格方法
        ---------------------------------------------------------------------*/

        self.filter = function (filters) {
            filters = filters || {}
            _.defaults(filters, {
                search: $(self.refs.search).val(),
                page: 1,
            })
            self.page = filters.page
            self.update_tasks(filters)
        }

        self.next_page = function () {
            if (!!self.pagination.next) {
                self.page += 1
                self.filter({page: self.page})
            } else {
                alert("没有有效的页码可前往！")
            }
        }
        self.previous_page = function () {
            if (!!self.pagination.previous) {
                self.page -= 1
                self.filter({page: self.page})
            } else {
                alert("没有有效的页码可前往！")
            }
        }


        self.update_tasks = function (filters) {
            filters = filters || {}
            let show_public_tasks = $(self.refs.public).prop('checked')
            if (show_public_tasks) {
                filters.public = true
            }
            CODALAB.api.get_tasks(filters)
                .done(function (data) {
                    self.tasks = data.results
                    self.pagination = {
                        "count": data.count,
                        "next": data.next,
                        "previous": data.previous
                    }
                    self.update()
                })
                .fail(function (response) {
                    toastr.error("无法加载任务")
                })
        }

        self.search_tasks = function () {
            var filter = self.refs.search.value
            delay(() => self.update_tasks({search: filter}), 100)
        }

        self.delete_task = function (task) {
            if (confirm("您确定要删除 '" + task.name + "' 吗？\n使用此任务的提交将无法重新运行！排行榜上显示的结果也可能受到影响！")) {
                CODALAB.api.delete_task(task.id)
                    .done(function () {
                        self.update_tasks()
                        toastr.success("任务删除成功！")
                        CODALAB.events.trigger('reload_quota_cleanup')
                    })
                    .fail(function (response) {
                        toastr.error(response.responseJSON['error'])
                    })
            }
            event.stopPropagation()
        }

        self.delete_tasks = function () {
            if (confirm(`您确定要删除多个任务吗？\n使用这些任务的提交将无法重新运行！排行榜上显示的结果也可能受到影响！`)) {
                CODALAB.api.delete_tasks(self.marked_tasks)
                    .done(function () {
                        self.update_tasks()
                        toastr.success("任务删除成功！")
                        self.marked_tasks = []
                        CODALAB.events.trigger('reload_quota_cleanup')
                    })
                    .fail(function (response) {
                        for (e in response.responseJSON) {
                            toastr.error(`${e}: '${response.responseJSON[e]}'`)
                        }
                    })
            }
            event.stopPropagation()
        }

        self.mark_task_for_deletion = function(task, e) {
            if (e.target.checked) {
                self.marked_tasks.push(task.id)
            }
            else {
                self.marked_tasks.splice(self.marked_tasks.indexOf(task.id), 1)
            }
        }

        self.open_share_modal = () => {
            $(self.refs.share_modal)
                .modal('show')
        }

        // 在删除未使用任务时更新任务列表
        CODALAB.events.on('reload_tasks', self.update_tasks)

    </script>
    <style type="text/stylus">
        .task-row
            height 42px
            cursor pointer
        .benchmark-row
            overflow: hidden
            white-space: nowrap
            text-overflow: ellipsis
            max-width: 125px
    </style>
</task-management>
