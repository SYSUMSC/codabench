<data-management>
    <!-- 搜索和筛选部分 -->
      
    <div class="ui icon input">
        <input type="text" placeholder="搜索..." ref="search" onkeyup="{ filter.bind(this, undefined) }">
        <i class="search icon"></i>
    </div>
    <select class="ui dropdown" ref="type_filter" onchange="{ filter.bind(this, undefined) }">
        <option value="">按类型过滤</option>
        <option value="-">----</option>
        <option each="{type in types}" value="{type}">{_.startCase(type)}</option>
    </select>
    <div class="ui checkbox" onclick="{ filter.bind(this, undefined) }">
        <label>显示自动创建</label>
        <input type="checkbox" ref="auto_created">
    </div>
    <div class="ui checkbox inline-div" onclick="{ filter.bind(this, undefined) }">
        <label>显示公开</label>
        <input type="checkbox" ref="show_public">
    </div>
    <button class="ui green right floated labeled icon button" onclick="{show_creation_modal}">
        <i selenium="add-dataset" class="plus icon"></i>
        添加数据集/程序
    </button>
    <button class="ui red right floated labeled icon button {disabled: marked_datasets.length === 0}" onclick="{delete_datasets}">
        <i class="icon delete"></i>
        删除选中项
    </button>

    <!-- 数据表 -->
    <table id="datasetsTable" class="ui {selectable: datasets.length > 0} celled compact sortable table">
        <thead>
        <tr>
            <th>文件名</th>
            <th width="175px">类型</th>
            <th width="175px">大小</th>
            <th width="125px">上传时间</th>
            <th width="60px" class="no-sort">正在使用</th>
            <th width="60px" class="no-sort">公开</th>
            <th width="50px" class="no-sort">删除？</th>
            <th width="25px" class="no-sort"></th>
        </tr>
        </thead>
        <tbody>
        <tr each="{ dataset, index in datasets }"
            class="dataset-row"
            onclick="{show_info_modal.bind(this, dataset)}">
            <td>{ dataset.name }</td>
            <td>{ dataset.type }</td>
            <td>{ format_file_size(dataset.file_size) }</td>
            <td>{ timeSince(Date.parse(dataset.created_when)) } 之前</td>
            <td class="center aligned">
                <i class="checkmark box icon green" show="{ dataset.in_use.length > 0 }"></i>
            </td>
            <td class="center aligned">
                <i class="checkmark box icon green" show="{ dataset.is_public }"></i>
            </td>
            <td class="center aligned">
                <button show="{dataset.created_by === CODALAB.state.user.username}" class="ui mini button red icon" onclick="{ delete_dataset.bind(this, dataset) }">
                    <i class="icon delete"></i>
                </button>
            </td>
            <td class="center aligned">
                <div show="{dataset.created_by === CODALAB.state.user.username}" class="ui fitted checkbox">
                    <input type="checkbox" name="delete_checkbox" onclick="{ mark_dataset_for_deletion.bind(this, dataset) }">
                    <label></label>
                </div>
            </td>
        </tr>

        <tr if="{datasets.length === 0}">
            <td class="center aligned" colspan="6">
                <em>暂无数据集！</em>
            </td>
        </tr>
        </tbody>
        <tfoot>

        <!-- 分页 -->
        <tr>
            <th colspan="8" if="{datasets.length > 0}">
                <div class="ui right floated pagination menu" if="{datasets.length > 0}">
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

    <!-- 数据集详情模态框 -->
    <div ref="info_modal" class="ui modal">
        <div class="header">
            {selected_row.name}
        </div>
        <div class="content">
            <h3>详细信息</h3>

            <table class="ui basic table">
                <thead>
                <tr>
                    <th>标识</th>
                    <th>创建者</th>
                    <th>创建时间</th>
                    <th>类型</th>
                    <th>公开</th>
                </tr>
                </thead>
                <tbody>
                <tr>
                    <td>{selected_row.key}</td>
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
            <div show="{!!_.get(selected_row.in_use, 'length')}"><strong>使用于：</strong>
                <div class="ui bulleted list">
                    <div class="item" each="{comp in selected_row.in_use}">
                        <a href="{URLS.COMPETITION_DETAIL(comp.pk)}" target="_blank">{comp.title}</a>
                    </div>
                </div>
            </div>
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

    <!-- 添加数据集/程序模态框 -->
    <div ref="dataset_creation_modal" class="ui modal">
        <div class="header">添加数据集/程序表单</div>

        <div class="content">
            <div class="ui message error" show="{ Object.keys(errors).length > 0 }">
                <div class="header">
                    创建数据集时出错
                </div>
                <ul class="list">
                    <li each="{ error, field in errors }">
                        <strong>{field}:</strong> {error}
                    </li>
                </ul>
            </div>

            <form class="ui form coda-animated {error: errors}" ref="form">
                <input-text selenium="scoring-name" name="name" ref="name" error="{errors.name}" placeholder="名称"></input-text>
                <input-text selenium="scoring-desc" name="description" ref="description" error="{errors.description}"
                            placeholder="描述"></input-text>

                <div class="field {error: errors.type}">
                    <select selenium="type" id="type_of_data" name="type" ref="type" class="ui dropdown">
                        <option value="">类型</option>
                        <option value="-">----</option>
                        <option each="{type in types}" value="{type}">{_.startCase(type)}</option>
                    </select>
                </div>

                <input-file selenium="file" name="data_file" ref="data_file" error="{errors.data_file}"
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
                <i selenium="upload" class="upload icon"></i>
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
        self.types = [
            "ingestion_program",
            "input_data",
            "public_data",
            "reference_data",
            "scoring_program",
            "starting_kit",
        ]
        self.errors = []
        self.datasets = []
        self.selected_row = {}
        self.marked_datasets = []


        self.upload_progress = undefined

        self.page = 1

        self.one("mount", function () {
            $(".ui.dropdown", self.root).dropdown()
            $(".ui.checkbox", self.root).checkbox()
            $('#datasetsTable').tablesort()
            self.update_datasets()
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
            $(self.refs.dataset_creation_modal).modal('show')
        }


        /*---------------------------------------------------------------------
         方法
        ---------------------------------------------------------------------*/
        self.pretty_date = date => luxon.DateTime.fromISO(date).toLocaleString(luxon.DateTime.DATE_FULL)

        self.filter = function (filters) {
            let type = $(self.refs.type_filter).val()
            filters = filters || {}
            _.defaults(filters, {
                type: type === '-' ? '' : type,
                search: $(self.refs.search).val(),
                page: 1,
            })
            self.page = filters.page
            self.update_datasets(filters)
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

        self.update_datasets = function (filters) {
            filters = filters || {}
            filters.was_created_by_competition = $(self.refs.auto_created).prop('checked')
            filters._public = $(self.refs.show_public).prop('checked')
            filters._type = "dataset"
            CODALAB.api.get_datasets(filters)
                .done(function (data) {
                    self.datasets = data.results
                    self.pagination = {
                        "count": data.count,
                        "next": data.next,
                        "previous": data.previous
                    }
                    self.update()
                })
                .fail(function (response) {
                    toastr.error("无法加载数据集...")
                })
        }

        self.delete_dataset = function (dataset, e) {
            if (confirm(`确定要删除 '${dataset.name}' 吗？`)) {
                CODALAB.api.delete_dataset(dataset.id)
                    .done(function () {
                        self.update_datasets()
                        toastr.success("数据集删除成功！")
                        CODALAB.events.trigger('reload_quota_cleanup')
                    })
                    .fail(function (response) {
                        toastr.error(response.responseJSON['error'])
                    })
            }
            event.stopPropagation()
        }

        self.delete_datasets = function () {
            if (confirm(`确定要删除多个数据集吗？`)) {
                CODALAB.api.delete_datasets(self.marked_datasets)
                    .done(function () {
                        self.update_datasets()
                        toastr.success("数据集删除成功！")
                        self.marked_datasets = []
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

            $('.dropdown', self.refs.form).dropdown('restore defaults')

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
            // 获取 "FormData" 以特殊方式获取文件（jQuery 处理文件时会用到）
            var metadata = get_form_data(self.refs.form)
            delete metadata.data_file  // 不要将文件与其他数据一起发送

            if (metadata.is_public === 'on') {
                var public_confirm = confirm("创建公开数据集意味着这将被发送到 Chahub 并在互联网上公开。您确定要继续吗？")
                if (!public_confirm) {
                    return
                }
            }

            var data_file = self.refs.data_file.refs.file_input.files[0]

            CODALAB.api.create_dataset(metadata, data_file, self.file_upload_progress_handler)
                .done(function (data) {
                    toastr.success("数据集上传成功！")
                    self.update_datasets()
                    self.clear_form()
                    $(self.refs.dataset_creation_modal).modal('hide')
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
                ? '您确定要将此数据集设为私有吗？设为私有后将不再对其他用户可见。'
                : '您确定要将此数据集设为公开吗？设为公开后将对所有人可见'
            if (confirm(message)) {
                CODALAB.api.update_dataset(self.selected_row.id, {id: self.selected_row.id, is_public: !self.selected_row.is_public})
                    .done(data => {
                        toastr.success('数据集已更新')
                        $(self.refs.info_modal).modal('hide')
                        self.filter()
                    })
                    .fail(resp => {
                        toastr.error(resp.responseJSON['is_public'])
                    })
            }
        }

        self.mark_dataset_for_deletion = function(dataset, e) {
            if (e.target.checked) {
                self.marked_datasets.push(dataset.id)
            }
            else {
                self.marked_datasets.splice(self.marked_datasets.indexOf(dataset.id), 1)
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
            // 定义单位（文件大小以 KB 为单位，转换为 MB 和 GB）
            const units = ['KB', 'MB', 'GB']
            // 循环直到 n 小于 1000，并选择合适的单位
            let i = 0
            while(n >= 1000 && ++i){
                n = n/1000;
            }
            // 保留一位小数并加上单位
            return(n.toFixed(1) + ' ' + units[i]);
        }

        // 删除未使用数据集时更新数据集列表
        CODALAB.events.on('reload_datasets', self.update_datasets)

    </script>

    <style type="text/stylus">
        .dataset-row:hover
            cursor pointer
    </style>
</data-management>
