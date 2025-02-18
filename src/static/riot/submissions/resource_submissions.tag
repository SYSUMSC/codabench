<submission-management>

    <!-- 搜索 -->
    <div class="ui icon input">
        <input type="text" placeholder="搜索..." ref="search" onkeyup="{ filter.bind(this, undefined) }">
        <i class="search icon"></i>
    </div>
    <div class="ui checkbox inline-div" onclick="{ filter.bind(this, undefined) }">
        <label>显示公开</label>
        <input type="checkbox" ref="show_public">
    </div>
    <button class="ui green right floated labeled icon button" onclick="{show_creation_modal}">
        <i class="plus icon"></i>
        添加提交
    </button>
    <button class="ui red right floated labeled icon button {disabled: marked_submissions.length === 0}" onclick="{delete_submissions}">
        <i class="icon delete"></i>
        删除选中提交
    </button>

    <!-- 数据表 -->
    <table id="submissionsTable" class="ui {selectable: submissions.length > 0} celled compact sortable table">
        <thead>
        <tr>
            <th>文件名</th>
            <th>所属竞赛</th>
            <th width="175px">大小</th>
            <th width="125px">上传时间</th>
            <th width="60px" class="no-sort">公开</th>
            <th width="50px" class="no-sort">删除？</th>
            <th width="25px" class="no-sort"></th>
        </tr>
        </thead>
        <tbody>
        <tr each="{ submission, index in submissions }"
            class="submission-row"
            onclick="{show_info_modal.bind(this, submission)}">
            <!-- 如果存在文件名则显示，否则显示名称（适用于旧提交） -->
            <td>{ submission.file_name || submission.name }</td>
            <!-- 如果存在竞赛，则以链接形式显示竞赛名称 -->
            <td if="{submission.competition}"><a class="link-no-deco" target="_blank" href="../competitions/{ submission.competition.id }">{ submission.competition.title }</a></td>
            <!-- 如果没有竞赛，则显示空单元格 -->
            <td if="{!submission.competition}"></td>
            <td>{ format_file_size(submission.file_size) }</td>
            <td>{ timeSince(Date.parse(submission.created_when)) } 之前</td>
            <td class="center aligned">
                <i class="checkmark box icon green" show="{ submission.is_public }"></i>
            </td>
            <td class="center aligned">
                <button show="{submission.created_by === CODALAB.state.user.username}" class="ui mini button red icon" onclick="{ delete_submission.bind(this, submission) }">
                    <i class="icon delete"></i>
                </button>
            </td>
            <td class="center aligned">
                <div show="{submission.created_by === CODALAB.state.user.username}" class="ui fitted checkbox">
                    <input type="checkbox" name="delete_checkbox" onclick="{ mark_submission_for_deletion.bind(this, submission) }">
                    <label></label>
                </div>
            </td>
        </tr>

        <tr if="{submissions.length === 0}">
            <td class="center aligned" colspan="6">
                <em>暂无提交！</em>
            </td>
        </tr>
        </tbody>
        <tfoot>

        <!-- 分页 -->
        <tr>
            <th colspan="8" if="{submissions.length > 0}">
                <div class="ui right floated pagination menu" if="{submissions.length > 0}">
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

    <!-- 提交详情模态框 -->
    <div ref="info_modal" class="ui modal">
        <div class="header">
            {selected_row.file_name || selected_row.name}
        </div>
        <div class="content">
            <h3>详细信息</h3>

            <table class="ui basic table">
                <thead>
                <tr>
                    <th>标识</th>
                    <th>所属竞赛</th>
                    <th>创建者</th>
                    <th>创建时间</th>
                    <th>类型</th>
                    <th>公开</th>
                </tr>
                </thead>
                <tbody>
                <tr>
                    <td>{selected_row.key}</td>
                    <!-- 如果存在竞赛，则以链接形式显示竞赛名称 -->
                    <td if="{selected_row.competition}"><a class="link-no-deco" target="_blank" href="../competitions/{ selected_row.competition.id }">{ selected_row.competition.title }</a></td>
                    <!-- 如果没有竞赛，则显示空单元格 -->
                    <td if="{!selected_row.competition}"></td>
                    <td><a href="/profiles/user/{selected_row.created_by}/" target=_blank>{selected_row.owner_display_name}</a></td>
                    <td>{pretty_date(selected_row.created_when)}</td>
                    <td>{_.startCase(selected_row.type)}</td>
                    <td>{_.startCase(selected_row.is_public)}</td>
                </tr>
                </tbody>
            </table>
            <virtual if="{!!selected_row.description}">
                <div>描述：</div>
                <div class="ui segment">
                    {selected_row.description}
                </div>
            </virtual>
        </div>
        <div class="actions">
            <button show="{selected_row.created_by === CODALAB.state.user.username}"
                class="ui primary icon button" onclick="{toggle_is_public}">
                <i class="share icon"></i> {selected_row.is_public ? "设为私有" : "设为公开"}
            </button>
            <a href="{URLS.DATASET_DOWNLOAD(selected_row.key)}" class="ui green icon button">
                <i class="download icon"></i>下载文件
            </a>
            <button class="ui cancel button">关闭</button>
        </div>
    </div>

    <!-- 添加提交模态框 -->
    <div ref="submission_creation_modal" class="ui modal">
        <div class="header">添加提交表单</div>

        <div class="content">
            <div class="ui message error" show="{ Object.keys(errors).length > 0 }">
                <div class="header">
                    创建提交时出错
                </div>
                <ul class="list">
                    <li each="{ error, field in errors }">
                        <strong>{field}:</strong> {error}
                    </li>
                </ul>
            </div>

            <form class="ui form coda-animated {error: errors}" ref="form">
                <input-text name="name" ref="name" error="{errors.name}" placeholder="名称"></input-text>
                <input-text name="description" ref="description" error="{errors.description}"
                            placeholder="描述"></input-text>

                <input type=hidden name="type" ref="type" value="submission">
                
                <input-file name="data_file" ref="data_file" error="{errors.data_file}"
                            accept=".zip"></input-file>
            </form>

            <div class="ui indicating progress" ref="progress">
                <div class="bar">
                    <div class="progress">{ upload_progress }%</div>
                </div>
            </div>

        </div>
        <div class="actions">
            <button class="ui blue icon button" onclick="{check_form}">
                <i class="upload icon"></i>
                上传
            </button>
            <button class="ui basic red cancel button">取消</button>
        </div>
    </div>

    <script>
        var self = this
        self.mixin(ProgressBarMixin)

        /*---------------------------------------------------------------------
         初始化
        ---------------------------------------------------------------------*/
        self.errors = []
        self.submissions = []
        self.selected_row = {}
        self.marked_submissions = []

        self.upload_progress = undefined

        self.page = 1

        self.one("mount", function () {
            $(".ui.dropdown", self.root).dropdown()
            $(".ui.checkbox", self.root).checkbox()
            $('#submissionsTable').tablesort()
            self.update_submissions()
        })

        self.show_info_modal = function (row, e) {
            // 如果点击的是复选框，则不弹出详情模态框
            if (e.target.type === 'checkbox') {
                return
            }
            self.selected_row = row
            self.update()
            $(self.refs.info_modal).modal('show')
        }

        self.show_creation_modal = function () {
            $(self.refs.submission_creation_modal).modal('show')
        }

        /*---------------------------------------------------------------------
         方法
        ---------------------------------------------------------------------*/
        self.pretty_date = date => luxon.DateTime.fromISO(date).toLocaleString(luxon.DateTime.DATE_FULL)

        self.filter = function (filters) {
            filters = filters || {}
            _.defaults(filters, {
                search: $(self.refs.search).val(),
                page: 1,
            })
            self.page = filters.page
            self.update_submissions(filters)
        }

        self.next_page = function () {
            if (!!self.pagination.next) {
                self.page += 1
                self.filter({page: self.page})
            } else {
                alert("没有可前往的有效页码！")
            }
        }
        self.previous_page = function () {
            if (!!self.pagination.previous) {
                self.page -= 1
                self.filter({page: self.page})
            } else {
                alert("没有可前往的有效页码！")
            }
        }

        self.update_submissions = function (filters) {
            filters = filters || {}
            filters._public = $(self.refs.show_public).prop('checked')
            filters._type = "submission"
            CODALAB.api.get_datasets(filters)
                .done(function (data) {
                    self.submissions = data.results
                    self.pagination = {
                        "count": data.count,
                        "next": data.next,
                        "previous": data.previous
                    }
                    self.update()
                })
                .fail(function (response) {
                    toastr.error("无法加载提交...")
                })
        }

        self.delete_submission = function (submission, e) {
            name = submission.file_name || submission.name
            if (confirm(`确定要删除 '${name}' 吗？`)) {
                CODALAB.api.delete_dataset(submission.id)
                    .done(function () {
                        self.update_submissions()
                        toastr.success("提交删除成功！")
                        CODALAB.events.trigger('reload_quota_cleanup')
                    })
                    .fail(function (response) {
                        toastr.error(response.responseJSON['error'])
                    })
            }
            event.stopPropagation()
        }

        self.delete_submissions = function () {
            if (confirm(`确定要删除多个提交吗？`)) {
                CODALAB.api.delete_datasets(self.marked_submissions)
                    .done(function () {
                        self.update_submissions()
                        toastr.success("提交删除成功！")
                        self.marked_submissions = []
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

        self.clear_form = function () {
            // 清空表单
            $(':input', self.refs.form)
                .not(':button, :submit, :reset, :hidden')
                .val('')
                .removeAttr('checked')
                .removeAttr('selected');

            self.errors = {}
            self.update()
        }

        self.check_form = function (event) {
            if (event) {
                event.preventDefault()
            }

            // 重置上传进度，以防重新上传或之前出错——这是最合适的位置，同时重置动画
            self.file_upload_progress_handler(undefined)

            // 快速验证
            self.errors = {}
            var validate_data = get_form_data(self.refs.form)

            var required_fields = ['name', 'type', 'data_file']
            required_fields.forEach(field => {
                if (validate_data[field] === '') {
                    self.errors[field] = "此字段为必填项"
                }
            })

            if (Object.keys(self.errors).length > 0) {
                // 显示错误信息并退出
                self.update()
                return
            }

            // 调用进度条包装函数并执行上传——我们希望先检查并显示错误，再进行实际上传
            self.prepare_upload(self.upload)()
        }

        self.upload = function () {
            // 获取 "FormData" 以特殊方式获取文件（jQuery 会处理）
            var metadata = get_form_data(self.refs.form)
            delete metadata.data_file  // 不要将文件随其他数据发送

            if (metadata.is_public === 'on') {
                var public_confirm = confirm("创建公开提交意味着这将被发送到 Chahub 并在互联网上公开可用。您确定要继续吗？")
                if (!public_confirm) {
                    return
                }
            }

            var data_file = self.refs.data_file.refs.file_input.files[0]

            CODALAB.api.create_dataset(metadata, data_file, self.file_upload_progress_handler)
                .done(function (data) {
                    toastr.success("提交上传成功！")
                    self.update_submissions()
                    self.clear_form()
                    $(self.refs.submission_creation_modal).modal('hide')
                    CODALAB.events.trigger('reload_quota_cleanup')
                })
                .fail(function (response) {
                    if (response) {
                        try {
                            var errors = JSON.parse(response.responseText)

                            // 将错误数组转换为纯文本
                            Object.keys(errors).map(function (key, index) {
                                errors[key] = errors[key].join('; ')
                            })

                            self.update({errors: errors})
                        } catch (e) {

                        }
                    }
                    toastr.error("创建失败，发生错误")
                })
                .always(function () {
                    self.hide_progress_bar()
                })
        }

        self.toggle_is_public = () => {
            let message = self.selected_row.is_public
                ? '您确定要将此提交设为私有吗？设为私有后将不再对其他用户可见。'
                : '您确定要将此提交设为公开吗？设为公开后将对所有人可见？'
            if (confirm(message)) {
                CODALAB.api.update_dataset(self.selected_row.id, {id: self.selected_row.id, is_public: !self.selected_row.is_public})
                    .done(data => {
                        toastr.success('提交已更新')
                        $(self.refs.info_modal).modal('hide')
                        self.filter()
                    })
                    .fail(resp => {
                        toastr.error(resp.responseJSON['is_public'])
                    })
            }
        }

        self.mark_submission_for_deletion = function(submission, e) {
            if (e.target.checked) {
                self.marked_submissions.push(submission.id)
            }
            else {
                self.marked_submissions.splice(self.marked_submissions.indexOf(submission.id), 1)
            }
        }

        // 格式化文件大小函数
        self.format_file_size = function(file_size) {
            // 将文件大小从字符串解析为浮点数
            try {
                n = parseFloat(file_size)
            }
            catch(err) {
                // 解析失败则返回空字符串
                return ""
            }
            // 文件大小为 -1 表示错误
            if(n < 0) {
                return ""
            }
            // 定义文件大小单位（文件大小以 KB 为单位，转换为 MB 和 GB）
            const units = ['KB', 'MB', 'GB']
            let i = 0
            while(n >= 1000 && ++i){
                n = n/1000;
            }
            return(n.toFixed(1) + ' ' + units[i]);
        }

        // 在删除未使用/失败的提交时更新提交列表
        CODALAB.events.on('reload_submissions', self.update_submissions)

    </script>

    <style type="text/stylus">
        .submission-row:hover
            cursor pointer
    </style>
</submission-management>
